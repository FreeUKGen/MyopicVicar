task :correct_all_emendations,[:limit,:fix,:reset] => [:environment] do |t, args|
  file_for_warning_messages = "#{Rails.root}/log/correct_all_emendation.txt"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  output_file = File.new(file_for_warning_messages, "w")
  #type true for original and false for replacement
  args.fix == "true" ? fix = true : fix = false

  # checkpoint file: records the `original` of the last FULLY completed rule, so a later
  # invocation can skip past already-finished rules instead of reloading/rechecking them.
  # pass reset=true to ignore/clear an existing checkpoint and start over from the first rule.
  progress_file = "#{Rails.root}/tmp/correct_all_emendations_progress.txt"
  File.delete(progress_file) if args.reset == "true" && File.exist?(progress_file)
  last_completed_original = File.exist?(progress_file) ? File.read(progress_file).strip : nil
  last_completed_original = nil if last_completed_original.blank?

  output_file.puts "Starting correction of original emendations  at #{Time.now}#{last_completed_original ? " (resuming after '#{last_completed_original}')" : ""}"

  stopping = args.limit.to_i
  total_num_emended = 0
  total_num_unemended = 0
  total = EmendationRule.all.count
  num = 0
  hit_limit = false
  rules = EmendationRule.no_timeout.asc(:original)
  rules = rules.where(:original.gt => last_completed_original) if last_completed_original
  rules.each do |rule|
      start_time = Time.now
      num_emended = 0
      num_unemended = 0
      original = rule.original
      replacement = rule.replacement
      #code for originals to replacement
      base_query = SearchRecord.where("search_names.first_name": original)
      num_emendations = base_query.count
      # push the limit down to Mongo instead of loading every matching record first.
      # +1 preserves the off-by-one break semantics below (stopping+1 == num).
      # stopping <= 0 means no cap at all: fetch and process every matching record for every rule.
      query = stopping > 0 ? base_query.limit([(stopping - num) + 1, 1].max) : base_query
      search_records = Hash.new
      query.each do |record|
          rec = record.id.to_s
          search_records[rec] = record unless search_records.has_key?(rec)
      end
      search_records.each_value do |record|   
        a_match = false
        record.search_names.each do |names|
           a_match = true if names.first_name ==  replacement && names.origin == "e" 
           break if a_match
        end
        unless a_match
         
          num_unemended = num_unemended + 1 
          if fix
            record.emend_all
            record.save
            output_file.puts "#{record.inspect}"
            output_file.puts "#{record.search_names.inspect}" 
            entry = Freereg1CsvEntry.find(record.freereg1_csv_entry) unless record.freereg1_csv_entry.blank?
            output_file.puts "#{entry.inspect}" unless record.freereg1_csv_entry.blank?
            output_file.puts "*********************************************************************************************************"
            sleep_time = 0.01*(Rails.application.config.sleep.to_f).to_f
            sleep(sleep_time)
          end
        else
         num_emended = num_emended + 1 
        end
        num = num + 1
        sleep(100) if (num/100000)*100000 == num
        if stopping > 0 && stopping + 1 == num
          hit_limit = true
          break
        end
      end
      num_emended = num_emended - 1 if hit_limit
      num_unemended = num_unemended - 1 if hit_limit
      total_num_emended = total_num_emended + num_emended
      total_num_unemended = total_num_unemended + num_unemended
      end_time = Time.now
      processing_time = (end_time - start_time)/num_unemended
      #output_file.puts "Of #{num_emendations} originals for #{original} with replacement #{replacement} #{num_emended} were emended and #{num_unemended} unemended at #{processing_time}"
      p "Of #{num_emendations} originals for #{original} with replacement #{replacement} #{num_emended} were emended and #{num_unemended} unemended at #{processing_time}"
      # only checkpoint past a rule we actually finished -- a rule cut short by hitting the
      # limit gets fully retried next run (harmless: already-fixed records are skipped via a_match)
      File.write(progress_file, rule.original) unless hit_limit
      break if hit_limit
  end
  # ran to completion without hitting the limit -- nothing left to resume, clear the checkpoint
  File.delete(progress_file) if !hit_limit && File.exist?(progress_file)
  p "  A total of #{num} records examined for #{total} rules with #{total_num_emended} emended and #{total_num_unemended} unemended at #{Time.now}"
end
