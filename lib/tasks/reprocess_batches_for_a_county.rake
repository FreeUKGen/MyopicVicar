namespace :freereg do
  BATCH_SIZE = 100000
  PROGRESS_INTERVAL = 10
  PROGRESS_FILE_MARRIAGE_REPROCESS = File.join(Rails.root, 'tmp', 'reprocess_marriage_batches_for_a_county_done.txt')
  PROGRESS_FILE_MARRIAGE_CLEANUP = File.join(Rails.root, 'tmp', 'cleanup_marriage_batches_for_a_county_done.txt')
  desc "Reprocess batches for a specific county chapman code (e.g. 'rake freereg:reprocess_batches_for_a_county[YKS]')"
  task :reprocess_batches_for_a_county, [:chapman_code] => :environment do |t, args|
    validate_chapman_code(args[:chapman_code])
    chapman_code = args[:chapman_code].upcase
    
    puts "Starting batch reprocessing for #{ChapmanCode.name_from_code(chapman_code)} (#{chapman_code})"
    
    begin
      process_batches_for_county(chapman_code, nil)
    rescue => e
      handle_fatal_error(e)
    end
  end

  desc "Reprocess marriage batches for a county chapman code, or for ALL counties if none given (e.g. 'rake freereg:reprocess_marriage_batches_for_a_county[YKS]' or 'rake freereg:reprocess_marriage_batches_for_a_county')"
  task :reprocess_marriage_batches_for_a_county, [:chapman_code] => :environment do |t, args|
    reset_progress_if_requested!(PROGRESS_FILE_MARRIAGE_REPROCESS)
    done = load_done_counties(PROGRESS_FILE_MARRIAGE_REPROCESS)

    each_target_county(args[:chapman_code]) do |chapman_code|
      if args[:chapman_code].blank? && done.include?(chapman_code)
        puts "Skipping #{chapman_code} (already completed)"
        next
      end

      puts "Starting marriage batch reprocessing for #{ChapmanCode.name_from_code(chapman_code)} (#{chapman_code})"
      process_batches_for_county(chapman_code, 'ma')
      mark_county_done(PROGRESS_FILE_MARRIAGE_REPROCESS, chapman_code) if args[:chapman_code].blank?
    end
  rescue => e
    handle_fatal_error(e)
  end

  desc "clean up"
  task :clean_up_processed_batch, [:chapman_code] => :environment do |t, args|
    rake_lock_file = File.join(Rails.root, 'tmp', 'cleanup_lock_file.txt')
    unless File.exist?(rake_lock_file)
      validate_chapman_code(args[:chapman_code])
      chapman_code = args[:chapman_code].upcase

      puts "Starting batch clean up for #{ChapmanCode.name_from_code(chapman_code)} (#{chapman_code})"
      begin
        lock_file = File.new(rake_lock_file, 'w')
        clean_up_processed_batch(chapman_code, nil)
      rescue => e
        handle_fatal_error(e)
        FileUtils.rm_f(rake_lock_file)
      end
      FileUtils.rm_f(rake_lock_file)
    else
      p 'clean up process is running'
    end
  end

  desc "Clean up processed marriage batches for a county chapman code, or for ALL counties if none given (e.g. 'rake freereg:clean_up_processed_marriage_batch[YKS]' or 'rake freereg:clean_up_processed_marriage_batch')"
  task :clean_up_processed_marriage_batch, [:chapman_code] => :environment do |t, args|
    rake_lock_file = File.join(Rails.root, 'tmp', 'cleanup_lock_file.txt')
    if File.exist?(rake_lock_file)
      p 'clean up process is running'
      next
    end

    begin
      reset_progress_if_requested!(PROGRESS_FILE_MARRIAGE_CLEANUP)
      done = load_done_counties(PROGRESS_FILE_MARRIAGE_CLEANUP)

      File.new(rake_lock_file, 'w')
      each_target_county(args[:chapman_code]) do |chapman_code|
        if args[:chapman_code].blank? && done.include?(chapman_code)
          puts "Skipping #{chapman_code} (already completed)"
          next
        end

        puts "Starting marriage batch clean up for #{ChapmanCode.name_from_code(chapman_code)} (#{chapman_code})"
        clean_up_processed_batch(chapman_code, 'ma')
        mark_county_done(PROGRESS_FILE_MARRIAGE_CLEANUP, chapman_code) if args[:chapman_code].blank?
      end
    rescue => e
      handle_fatal_error(e)
    ensure
      FileUtils.rm_f(rake_lock_file)
    end
  end

  desc "List all available Chapman codes"
  task list_chapman_codes: :environment do
    display_chapman_codes
  end

  desc "Number of files to be processed for a county"
  task :count_batches_to_be_processed_for_the_county, [:chapman_code] => :environment do |t, args|
    validate_chapman_code(args[:chapman_code])
    chapman_code = args[:chapman_code].upcase
    
    begin
      count_batches_for_county(chapman_code)
    rescue => e
      handle_fatal_error(e)
    end
  end

  desc "Number of marriage files to be processed for a county chapman code, or ALL counties if none given"
  task :count_marriage_batches_to_be_processed_for_the_county, [:chapman_code] => :environment do |t, args|
    each_target_county(args[:chapman_code]) do |chapman_code|
      count_batches_for_county(chapman_code, record_type: 'ma')
    end
  rescue => e
    handle_fatal_error(e)
  end

  private

  def validate_chapman_code(chapman_code)
    unless chapman_code
      puts "Error: Chapman code is required, rake freereg:reprocess_batches_for_a_county[CHAPMAN_CODE]"
      exit 1
    end

    unless ChapmanCode.value?(chapman_code.upcase)
      puts "Error: Invalid Chapman code '#{chapman_code}'. Please use one of the following valid chapman codes:#{ChapmanCode.values.join(', ')}"
      exit 1
    end
  end

  def each_target_county(chapman_code_arg)
    if chapman_code_arg.present?
      validate_chapman_code(chapman_code_arg)
      yield chapman_code_arg.upcase
      return
    end

    ChapmanCode.values.sort.each do |code|
      next unless ChapmanCode.value?(code)
      yield code
    end
  end

  def reset_progress_if_requested!(progress_file)
    return unless ENV['RESET_PROGRESS'].present?

    FileUtils.rm_f(progress_file)
  end

  def load_done_counties(progress_file)
    return Set.new unless File.exist?(progress_file)

    require 'set'
    Set.new(File.read(progress_file).lines.map { |l| l.strip.upcase }.reject(&:empty?))
  end

  def mark_county_done(progress_file, chapman_code)
    FileUtils.mkdir_p(File.dirname(progress_file))
    File.open(progress_file, 'a') { |f| f.puts(chapman_code.to_s.upcase) }
  end

  def clean_up_processed_batch(chapman_code, record_type = nil)
    if record_type.present?
      clean_up_search_records_for_county(chapman_code, record_type)
    else
      RecordType.all_types.each do |rt|
        clean_up_search_records_for_county(chapman_code, rt)
      end
    end
  end

  def clean_up_search_records_for_county(chapman_code, record_type)
    scope = search_records_for_county(chapman_code, record_type)
    total = scope.count
    if total.zero?
      puts "No search records found for #{chapman_code} (#{record_type})"
      return
    end

    puts "Found #{total} search records to clean up for #{record_type}"
    processed = 0
    scope.no_timeout.each do |search_record|
      entry = search_record.freereg1_csv_entry
      next if entry.blank?

      place = entry.freereg1_csv_file&.register&.church&.place
      next if place.blank?

      processed += 1
      puts "processing #{processed}/#{total}: #{search_record.id}"
      search_record.transform
      search_record.place_id = place.id
      search_record.save
    end
  end

  def search_records_for_county(chapman_code, record_type)
    SearchRecord.where(chapman_code: chapman_code, record_type: record_type).hint('chapman_record_type')
  end

  def process_batches_for_county(chapman_code, record_type = nil)
    if record_type.present?
      process_search_records_for_county(chapman_code, record_type)
    else
      RecordType.all_types.each do |rt|
        process_search_records_for_county(chapman_code, rt)
      end
    end
  end

  def process_search_records_for_county(chapman_code, record_type)
    scope = search_records_for_county(chapman_code, record_type)
    total = scope.count

    if total.zero?
      puts "No search records found for #{chapman_code} (#{record_type})"
      return
    end

    puts "Found #{total} search records to process for #{RecordType.display_name(record_type)}"

    processed = 0
    skipped = 0
    failed = []
    start_time = Time.now
    software_version = get_software_version
    search_version = software_version&.last_search_record_version.to_s

    scope.no_timeout.each_slice(BATCH_SIZE) do |search_record_group|
      search_record_group.each do |search_record|
        begin
          result = process_single_search_record(search_record, search_version)
          if result == :skipped
            skipped += 1
          else
            processed += 1
            if (processed % PROGRESS_INTERVAL).zero?
              print_progress(processed, total, start_time)
            end
          end
        rescue => e
          handle_search_record_error(search_record, e, failed)
        end
      end
    end

    print_search_record_summary(total, processed, skipped, failed, start_time)
  end

  def process_single_search_record(search_record, search_version)
    entry = search_record.freereg1_csv_entry
    return :skipped if entry.blank?

    place = entry.freereg1_csv_file&.register&.church&.place
    return :skipped if place.blank?

    SearchRecord.no_timeout.update_create_search_record(entry, search_version, place)
    :processed
  end

  def get_software_version
    server = SoftwareVersion.extract_server(Socket.gethostname)
    SoftwareVersion.where(server: server, app: 'freereg').control.first
  end

  def print_progress(processed, total, start_time)
    elapsed = Time.now - start_time
    avg_time = elapsed / processed
    remaining = avg_time * (total - processed)
    
    print "\nProgress: #{processed}/#{total} (#{(processed.to_f/total*100).round(1)}%)"
    print " - Est. remaining time: #{format_duration(remaining)}"
  end

  def handle_search_record_error(search_record, error, failed)
    failed << {
      search_record_id: search_record.id.to_s,
      freereg1_csv_entry_id: search_record.freereg1_csv_entry_id.to_s,
      error: error.message,
      backtrace: error.backtrace.first(3)
    }
    puts "\nError processing search record #{search_record.id}: #{error.message}"
  end

  def print_search_record_summary(total, processed, skipped, failed, start_time)
    elapsed = Time.now - start_time

    puts "\n\nProcessing complete!"
    puts "----------------------------------------"
    puts "Total search records: #{total}"
    puts "Successfully processed: #{processed}"
    puts "Skipped (no entry or place): #{skipped}"
    puts "Failed: #{failed.count}"
    puts "Total time: #{format_duration(elapsed)}"
    puts "Average time per record: #{format_duration(elapsed / processed)}" if processed.positive?

    if failed.any?
      puts "\nFailed search records:"
      failed.each do |f|
        puts "- #{f[:search_record_id]} (entry #{f[:freereg1_csv_entry_id]}): #{f[:error]}"
        puts "  Backtrace: #{f[:backtrace].join("\n  ")}"
      end
    end
  end

  def count_batches_for_county(chapman_code, record_type: nil)
    puts "Counting search records to be processed for #{ChapmanCode.name_from_code(chapman_code)} (#{chapman_code})"

    if record_type.present?
      total = search_records_for_county(chapman_code, record_type).count
      if total.zero?
        puts "No search records found for #{chapman_code}"
        return
      end
      puts "Found #{total} #{RecordType.display_name(record_type)} search records to process"
    else
      total = 0
      RecordType.all_types.each do |rt|
        count = search_records_for_county(chapman_code, rt).count
        total += count
        puts "Found #{count} #{RecordType.display_name(rt)} search records to process"
      end
      puts "Found #{total} search records to process in total"
    end
  end

  def display_chapman_codes
    puts "Available Chapman Codes:"
    puts "----------------------"
    ChapmanCode.values.sort.each do |code|
      puts "#{code}: #{ChapmanCode.name_from_code(code)}"
    end
  end

  def handle_fatal_error(error)
    puts "\nFatal error: #{error.message}"
    puts error.backtrace
    exit 1
  end

  def format_duration(seconds)
    return "0s" if seconds.zero?
    
    hours = (seconds / 3600).to_i
    minutes = ((seconds % 3600) / 60).to_i
    seconds = (seconds % 60).to_i
    
    parts = []
    parts << "#{hours}h" if hours > 0
    parts << "#{minutes}m" if minutes > 0
    parts << "#{seconds}s" if seconds > 0 || parts.empty?
    
    parts.join(" ")
  end
end
