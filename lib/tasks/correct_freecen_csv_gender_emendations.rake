desc "Correct FreeCEN CSV search records missing forename variations due to gender case mismatch in emendation check.
      Usage: rake correct_freecen_csv_gender_emendations[limit,fix]
        limit: max records to process (0 or blank = no limit, use a small number for testing)
        fix:   'true' to apply changes, anything else (or blank) for dry-run"
task :correct_freecen_csv_gender_emendations, [:limit, :fix] => :environment do |_t, args|
  start_time = Time.now
  file_date  = start_time.strftime('%Y%m%d%H%M')
  log_path   = "#{Rails.root}/log/correct_freecen_csv_gender_emendations_#{file_date}.log"
  FileUtils.mkdir_p(File.dirname(log_path))
  log_file = File.new(log_path, 'w')

  fix   = args.fix == 'true'
  limit = args.limit.to_i
  limit = nil if limit == 0

  sleep_time = Rails.application.config.emmendation_sleep.to_f

  message = "Starting FreeCEN CSV gender emendation correction at #{start_time} | fix=#{fix} | limit=#{limit || 'none'}"
  log_file.puts message
  p message

  # Only gender-specific rules were broken by the case mismatch — gender-neutral rules were unaffected
  gender_rules = EmendationRule.where(:gender.ne => nil).to_a
  # Group by original so records shared by same-original/different-gender rules (e.g. alex->alexander/alexandra)
  # are queried and examined once, instead of once per rule.
  rules_by_original = gender_rules.group_by(&:original)

  message = "Found #{gender_rules.size} gender-specific emendation rules across #{rules_by_original.size} original names to process"
  log_file.puts message
  p message

  total_examined     = 0
  total_updated       = 0
  total_already_ok    = 0
  total_wrong_gender  = 0

  rules_by_original.each do |original, rules|
    records = SearchRecord.where(
      'search_names.first_name' => original,
      :freecen_csv_entry_id.ne => nil
    ).no_timeout

    rule_stats = rules.each_with_object({}) do |rule, stats|
      stats[rule] = { examined: 0, updated: 0, already_ok: 0, wrong_gender: 0 }
    end

    records.each do |record|
      break if limit && total_examined >= limit

      total_examined += 1

      rules.each do |rule|
        stats       = rule_stats[rule]
        replacement = rule.replacement
        gender      = rule.gender # stored as 'm' or 'f'

        stats[:examined] += 1

        already_emended = record.search_names.any? do |sn|
          sn.first_name == replacement && sn.origin == SearchRecord::Source::EMENDOR
        end

        if already_emended
          total_already_ok   += 1
          stats[:already_ok] += 1
          next
        end

        # Confirm the record has a name with the matching gender (guards against applying wrong-gender rule)
        has_matching_gender = record.search_names.any? do |sn|
          sn.first_name == original && sn.gender.present? && sn.gender.downcase == gender
        end

        unless has_matching_gender
          total_wrong_gender   += 1
          stats[:wrong_gender] += 1
          next
        end

        if fix
          record.emend_all
          record.save!
          sleep(sleep_time)
        end

        log_file.puts "#{fix ? 'Updated' : 'Would update'} #{record.id}: #{original} -> #{replacement} (gender: #{gender})"
        total_updated   += 1
        stats[:updated] += 1
      end
    end

    rules.each do |rule|
      stats   = rule_stats[rule]
      message = "Rule #{original}->#{rule.replacement} (#{rule.gender}): examined=#{stats[:examined]} | updated=#{stats[:updated]} | already_ok=#{stats[:already_ok]} | wrong_gender=#{stats[:wrong_gender]}"
      log_file.puts message
      p message
    end

    break if limit && total_examined >= limit
  end

  end_time = Time.now
  message = "Finished at #{end_time} | examined=#{total_examined} | updated=#{total_updated} | already_ok=#{total_already_ok} | wrong_gender=#{total_wrong_gender} | elapsed=#{(end_time - start_time).round(2)}s | log=#{log_path}"
  log_file.puts message
  p message
  log_file.close
end
