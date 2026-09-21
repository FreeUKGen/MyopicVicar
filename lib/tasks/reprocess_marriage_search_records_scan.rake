# Backup rake tasks: reprocess marriage SearchRecords via a single collection scan.
# Does not modify lib/tasks/reprocess_batches_for_a_county.rake
namespace :freereg do
    PROGRESS_INTERVAL = 10
    PROGRESS_FILE = File.join(Rails.root, 'tmp', 'reprocess_marriage_search_records_scan_checkpoint.txt')
  
    desc "Backup: reprocess marriage search records (SearchRecord scan, skip non-ma in Ruby). County: rake freereg:reprocess_marriage_search_records_scan[STS]. All: rake freereg:reprocess_marriage_search_records_scan. RESET_PROGRESS=1 to restart."
    task :reprocess_marriage_search_records_scan, [:chapman_code] => :environment do |_t, args|
      reset_scan_checkpoint_if_requested!
  
      chapman_code = parse_optional_chapman_code(args[:chapman_code])
      resume_from_id = chapman_code ? nil : load_scan_checkpoint
  
      if chapman_code
        puts "Marriage search record scan for #{ChapmanCode.name_from_code(chapman_code)} (#{chapman_code})"
      else
        puts 'Marriage search record scan (all counties)'
        puts "Resuming after #{resume_from_id}" if resume_from_id
      end
  
      run_marriage_search_record_scan(
        chapman_code: chapman_code,
        resume_from_id: resume_from_id,
        checkpoint: chapman_code.nil?
      )
      FileUtils.rm_f(PROGRESS_FILE) unless chapman_code
    rescue => e
      scan_fatal_error(e)
    end
  
    desc "Backup: count marriage search records for reprocess_marriage_search_records_scan"
    task :count_marriage_search_records_scan, [:chapman_code] => :environment do |_t, args|
      chapman_code = parse_optional_chapman_code(args[:chapman_code])
      count = 0
  
      SearchRecord.asc(:_id).no_timeout.each do |search_record|
        next unless marriage_freereg_search_record?(search_record)
        next if skip_for_chapman_code?(search_record, chapman_code)
  
        count += 1
      end
  
      label = chapman_code ? chapman_code : 'all counties'
      puts "Found #{count} marriage search records (#{label})"
    rescue => e
      scan_fatal_error(e)
    end
  
    def parse_optional_chapman_code(chapman_code_arg)
      return nil if chapman_code_arg.blank?
  
      code = chapman_code_arg.upcase
      unless ChapmanCode.value?(code)
        puts "Error: Invalid Chapman code '#{chapman_code_arg}'"
        exit 1
      end
      code
    end
  
    def reset_scan_checkpoint_if_requested!
      return unless ENV['RESET_PROGRESS'].present?
  
      FileUtils.rm_f(PROGRESS_FILE)
    end
  
    def load_scan_checkpoint
      return nil unless File.exist?(PROGRESS_FILE)
  
      id = File.read(PROGRESS_FILE).strip
      return nil if id.blank?
      return nil unless BSON::ObjectId.legal?(id)
  
      BSON::ObjectId.from_string(id)
    end
  
    def save_scan_checkpoint(search_record_id)
      FileUtils.mkdir_p(File.dirname(PROGRESS_FILE))
      File.write(PROGRESS_FILE, search_record_id.to_s)
    end
  
    def run_marriage_search_record_scan(chapman_code:, resume_from_id:, checkpoint:)
      scope = SearchRecord.asc(:_id)
      scope = scope.where(:_id.gt => resume_from_id) if resume_from_id
  
      processed = 0
      scanned = 0
      failed = []
      start_time = Time.now
      search_version = scan_search_record_version
  
      scope.no_timeout.each do |search_record|
        scanned += 1
        next unless marriage_freereg_search_record?(search_record)
        next if skip_for_chapman_code?(search_record, chapman_code)
  
        begin
          update_marriage_search_record_from_scan(search_record, search_version)
          processed += 1
          save_scan_checkpoint(search_record.id) if checkpoint
  
          if (processed % PROGRESS_INTERVAL).zero?
            puts "\nUpdated #{processed} marriages (scanned #{scanned})"
          end
        rescue => e
          failed << { id: search_record.id.to_s, error: e.message }
          puts "\nError #{search_record.id}: #{e.message}"
        end
      end
  
      elapsed = Time.now - start_time
      puts "\nDone. Scanned #{scanned}, updated #{processed}, failed #{failed.size}, time #{format_scan_duration(elapsed)}"
      failed.each { |f| puts "  #{f[:id]}: #{f[:error]}" } if failed.any?
    end
  
    def marriage_freereg_search_record?(search_record)
      search_record.record_type == RecordType::MARRIAGE &&
        search_record.freereg1_csv_entry_id.present?
    end
  
    def skip_for_chapman_code?(search_record, chapman_code)
      return false if chapman_code.blank?
  
      search_record.chapman_code.to_s.upcase != chapman_code
    end
  
    def update_marriage_search_record_from_scan(search_record, search_version)
      entry = search_record.freereg1_csv_entry
      return unless entry.present?
  
      place = entry.freereg1_csv_file.register.church.place
      SearchRecord.no_timeout.update_create_search_record(entry, search_version, place)
    end
  
    def scan_search_record_version
      server = SoftwareVersion.extract_server(Socket.gethostname)
      software_version = SoftwareVersion.where(server: server, app: 'freereg').control.first
      software_version&.last_search_record_version.to_s
    end
  
    def format_scan_duration(seconds)
      return '0s' if seconds.zero?
  
      hours = (seconds / 3600).to_i
      minutes = ((seconds % 3600) / 60).to_i
      secs = (seconds % 60).to_i
      parts = []
      parts << "#{hours}h" if hours.positive?
      parts << "#{minutes}m" if minutes.positive?
      parts << "#{secs}s" if secs.positive? || parts.empty?
      parts.join(' ')
    end
  
    def scan_fatal_error(error)
      puts "\nFatal error: #{error.message}"
      puts error.backtrace
      exit 1
    end
  end