# frozen_string_literal: true

require 'app'
require 'chapman_code'
require 'fileutils'

desc 'FreeREG: backfill SearchRecord.location_names[0] to "Place ||| Church"; args chapman_codes,limit,fix'
task :backfill_location_names_delimiter, %i[chapman_codes limit fix] => :environment do |_t, args|
  unless App.name_downcase == 'freereg'
    puts "This task is for FreeREG only (current app: #{App.name_downcase}). Aborting."
    exit 1
  end

  fix = args.fix.to_s.strip == 'fix'
  chapman_codes_arg = args.chapman_codes.to_s.strip
  limit = args.limit.present? ? args.limit.to_i : 0

  if chapman_codes_arg.blank?
    puts 'Provide chapman_codes: comma-separated list (e.g. CON,RUT) or all'
    exit 1
  end

  county_codes = if chapman_codes_arg == 'all'
                   ChapmanCode.values.uniq.compact
                 else
                   chapman_codes_arg.split(',').map(&:strip).reject(&:blank?)
                 end

  legacy_location0 = lambda do |scoped|
    # Legacy: location_names.0 contains '(' and ')', but not the new delimiter.
    # Also ensure location_names exists and has an element 0.
    scoped.where('location_names.0' => { '$exists' => true })
          .where('location_names.0' => /[()]/)
          .not.where('location_names.0' => /\|\|\|/)
  end

  log_dir = Rails.root.join('log')
  FileUtils.mkdir_p(log_dir)
  log_path = log_dir.join('backfill_location_names_delimiter.log')
  log = File.open(log_path, 'a')
  log.puts "[#{Time.now.utc.iso8601}] start fix=#{fix} chapman_codes=#{chapman_codes_arg} counties=#{county_codes.size} limit=#{limit}"

  processed = 0
  fixed = 0
  errors = 0

  county_codes.each do |county_code|
    break if limit.positive? && processed >= limit

    scoped = legacy_location0.call(SearchRecord.where(chapman_code: county_code))
    county_count = scoped.count
    next if county_count.zero?

    puts "County #{county_code}: #{county_count} legacy location_names[0] rows"

    scoped.no_timeout.each do |sr|
      break if limit.positive? && processed >= limit

      processed += 1

      begin
        place, church, _reg = sr.extract_location_parts
        new_location0 = [place.to_s.strip, church.to_s.strip].join(' ||| ').strip

        if !fix
          puts "#{sr.id}\t#{county_code}\t#{sr.location_names[0]}\t=>\t#{new_location0}" if processed <= 25
          next
        end

        sr.location_names = Array(sr.location_names)
        sr.location_names[0] = new_location0
        sr.location_names[1] = sr.location_names[1].to_s # keep as-is (may be '')

        sr.digest = sr.cal_digest
        sr.save!
        fixed += 1
      rescue StandardError => e
        errors += 1
        msg = "#{sr.id}\t#{e.class}\t#{e.message}"
        puts "ERROR\t#{msg}"
        log.puts "ERROR\t#{msg}"
      end

      puts "Processed #{processed} (#{fixed} saved, #{errors} errors)..." if fix && (processed % 500).zero?
    end
  end

  summary = "Done. processed=#{processed} fixed=#{fixed} errors=#{errors} (dry-run: #{!fix})"
  puts summary
  log.puts summary
  log.close
end

