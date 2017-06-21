task :correct_all_emendations,[:limit,:fix] => [:environment] do |t, args|
  file_for_warning_messages = "#{Rails.root}/log/correct_all_emendation.txt"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  output_file = File.new(file_for_warning_messages, "w")
  #type true for original and false for replacement
  args.fix == "true" ? fix = true : fix = false
  output_file.puts "Starting correction of original emendations  at #{Time.now}" 
  
  stopping = args.limit.to_i
  total_num_emended = 0
  total_num_unemended = 0
  total = EmendationRule.all.count
  num = 0
  EmendationRule.no_timeout.each do |rule|
      start_time = Time.now
      num_emended = 0
      num_unemended = 0
      original = rule.original
      replacement = rule.replacement
      #code for originals to replacement
      search_records = Hash.new
      SearchRecord.where("search_names.first_name": original).all.each do |record|
          rec = record.id.to_s
          search_records[rec] = record unless search_records.has_key?(rec)
      end
      num_emendations = search_records.length  
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
        break if stopping + 1 == num
      end
      num_emended = num_emended - 1 if stopping + 1 == num
      num_unemended = num_unemended - 1 if stopping + 1 == num
      total_num_emended = total_num_emended + num_emended
      total_num_unemended = total_num_unemended + num_unemended
      end_time = Time.now
      processing_time = (end_time - start_time)/num_unemended
      #output_file.puts "Of #{num_emendations} originals for #{original} with replacement #{replacement} #{num_emended} were emended and #{num_unemended} unemended at #{processing_time}"
      p "Of #{num_emendations} originals for #{original} with replacement #{replacement} #{num_emended} were emended and #{num_unemended} unemended at #{processing_time}"
      break if stopping + 1 == num
  end
  p "  A total of #{num} records examined for #{total} rules with #{total_num_emended} emended and #{total_num_unemended} unemended at #{Time.now}"
end
