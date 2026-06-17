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

  sleep_time = (Rails.application.config.sleep.to_f * 0.01)

  message = "Starting FreeCEN CSV gender emendation correction at #{start_time} | fix=#{fix} | limit=#{limit || 'none'}"
  log_file.puts message
  p message

  # Only gender-specific rules were broken by the case mismatch — gender-neutral rules were unaffected
  gender_rules = EmendationRule.where(:gender.ne => nil).to_a

  message = "Found #{gender_rules.size} gender-specific emendation rules to process"
  log_file.puts message
  p message

  total_examined   = 0
  total_updated    = 0
  total_already_ok = 0

  gender_rules.each do |rule|
    original    = rule.original
    replacement = rule.replacement
    gender      = rule.gender # stored as 'm' or 'f'

    records = SearchRecord.where(
      'search_names.first_name' => original,
      :freecen_csv_entry_id.ne => nil
    ).no_timeout

    rule_examined   = 0
    rule_updated    = 0
    rule_already_ok = 0

    records.each do |record|
      break if limit && total_examined >= limit

      total_examined += 1
      rule_examined  += 1

      already_emended = record.search_names.any? do |sn|
        sn.first_name == replacement && sn.origin == SearchRecord::Source::EMENDOR
      end

      if already_emended
        total_already_ok += 1
        rule_already_ok  += 1
        next
      end

      # Confirm the record has a name with the matching gender (guards against applying wrong-gender rule)
      has_matching_gender = record.search_names.any? do |sn|
        sn.first_name == original && sn.gender.present? && sn.gender.downcase == gender
      end

      next unless has_matching_gender

      if fix
        record.emend_all
        record.save
        sleep(sleep_time)
      end

      log_file.puts "#{fix ? 'Updated' : 'Would update'} #{record.id}: #{original} -> #{replacement} (gender: #{gender})"
      total_updated += 1
      rule_updated  += 1
    end

    message = "Rule #{original}->#{replacement} (#{gender}): examined=#{rule_examined} | updated=#{rule_updated} | already_ok=#{rule_already_ok}"
    log_file.puts message
    p message

    break if limit && total_examined >= limit
  end

  end_time = Time.now
  message = "Finished at #{end_time} | examined=#{total_examined} | updated=#{total_updated} | already_ok=#{total_already_ok} | elapsed=#{(end_time - start_time).round(2)}s | log=#{log_path}"
  log_file.puts message
  p message
  log_file.close
end
