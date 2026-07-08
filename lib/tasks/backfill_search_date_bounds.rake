# frozen_string_literal: true

require 'app'
require 'chapman_code'
require 'fileutils'

desc 'FreeREG: backfill search_date_min/search_date_max; args chapman_codes,limit,fix[,index_hint]'
task :backfill_search_date_bounds, %i[chapman_codes limit fix index_hint] => :environment do |_t, args|
  unless App.name_downcase == 'freereg'
    puts "This task is for FreeREG only (current app: #{App.name_downcase}). Aborting."
    exit 1
  end

  fix = args.fix.to_s.strip == 'fix'
  chapman_codes_arg = args.chapman_codes.to_s.strip
  limit = args.limit.present? ? args.limit.to_i : 0
  raw_hint = args.index_hint.to_s.strip
  hint_name = raw_hint.present? && !%w[none -].include?(raw_hint.downcase) ? raw_hint : nil
  apply_hint = lambda do |scoped|
    hint_name.present? ? scoped.hint(hint_name) : scoped
  end

  if chapman_codes_arg.blank?
    puts 'Provide chapman_codes: comma-separated list (e.g. CON,RUT) or all'
    exit 1
  end

  county_codes = if chapman_codes_arg == 'all'
                   ChapmanCode.values.uniq.compact
                 else
                   chapman_codes_arg.split(',').map(&:strip).reject(&:blank?)
                 end

  # Anything with a search_date but no search_date_min yet needs backfilling. Records
  # with neither are untranscribed/no-date and derive_date_bounds would return [nil, nil]
  # for them anyway, so there's nothing useful to backfill.
  base_filters = lambda do |scoped|
    scoped.where(:search_date.exists => true).where(:search_date_min.exists => false)
  end

  log_dir = Rails.root.join('log')
  FileUtils.mkdir_p(log_dir)
  log_path = log_dir.join('backfill_search_date_bounds.log')
  log = File.open(log_path, 'a')
  log.puts "[#{Time.now.utc.iso8601}] start fix=#{fix} chapman_codes=#{chapman_codes_arg} counties=#{county_codes.size} limit=#{limit} hint=#{hint_name || 'none'}"

  updated_log_path = log_dir.join('backfill_search_date_bounds_updated.tsv')
  updated_log = nil
  if fix
    updated_log = File.open(updated_log_path, 'a')
    updated_log.puts "# run_at=#{Time.now.utc.iso8601} chapman_codes=#{chapman_codes_arg} limit=#{limit}"
    updated_log.puts %w[search_record_id chapman_code search_date secondary_search_date search_date_min search_date_max].join("\t")
  end

  safe_count = lambda do |scoped|
    begin
      apply_hint.call(scoped).count
    rescue StandardError => e
      if hint_name.present? && e.message.to_s.match?(/hint|index|code 2|Bad hint/i)
        log.puts "count_hint_failed #{e.class}: #{e.message} (count without hint)"
        scoped.count
      else
        raise
      end
    end
  end

  total_matching = 0
  county_codes.each do |code|
    total_matching += safe_count.call(base_filters.call(SearchRecord.where(chapman_code: code)))
  end
  puts "Matching SearchRecords (sum by county): #{total_matching}"
  log.puts "matching_count=#{total_matching}"
  puts "Updated records will be appended to: #{updated_log_path}" if fix

  processed = 0
  fixed = 0
  errors = 0
  sample_shown = 0

  each_cursor_record = lambda do |relation|
    relation.each do |sr|
      break if limit.positive? && processed >= limit

      processed += 1

      if !fix && sample_shown < 25
        puts "#{sr.id}\t#{sr.chapman_code}\t#{sr.search_date}\t#{sr.secondary_search_date}"
        sample_shown += 1
      end

      next unless fix

      begin
        min, max = sr.derive_date_bounds
        sr.set(search_date_min: min, search_date_max: max)
        fixed += 1
        row = [sr.id.to_s, sr.chapman_code.to_s, sr.search_date.to_s, sr.secondary_search_date.to_s, min.to_s, max.to_s].join("\t")
        updated_log&.puts(row)
      rescue StandardError => e
        errors += 1
        msg = "#{sr.id}\t#{e.class}\t#{e.message}"
        puts "ERROR\t#{msg}"
        log.puts "ERROR\t#{msg}"
      end

      next unless fix && (processed % 500).zero?

      puts "Processed #{processed} (#{fixed} saved, #{errors} errors)..."
    end
  end

  county_codes.each do |county_code|
    break if limit.positive? && processed >= limit

    scoped = base_filters.call(SearchRecord.where(chapman_code: county_code))
    county_count = safe_count.call(scoped)
    next if county_count.zero?

    puts "County #{county_code}: #{county_count} matching"

    cursor = apply_hint.call(scoped.no_timeout)

    begin
      each_cursor_record.call(cursor)
    rescue StandardError => e
      if hint_name.present? && e.message.to_s.match?(/hint|index|code 2|Bad hint/i)
        puts "Hint rejected (#{e.class}): #{e.message}. Fix 4th arg index name or omit it; retrying county #{county_code} without hint."
        log.puts "hint_failed county=#{county_code} #{e.class}: #{e.message}"
        each_cursor_record.call(scoped.no_timeout)
      else
        raise
      end
    end
  end

  summary = "Done. processed=#{processed} fixed=#{fixed} errors=#{errors} (dry-run: #{!fix})"
  puts summary
  log.puts summary
  updated_log&.close
  log.close
end
