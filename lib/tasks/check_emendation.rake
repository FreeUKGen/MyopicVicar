task :check_emendation,[:limit,:emendation,:replacement,:type,:fix] => [:environment] do |t, args|
  file_for_warning_messages = "#{Rails.root}/log/check_emendation.txt"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  output_file = File.new(file_for_warning_messages, "w")
  #type true for original and false for replacement
  args.type == "true"? type = true : type = false
  original = args.emendation.to_s 
  replacement = args.replacement.to_s 
  args.fix == "true" ? fix = true : fix = false
  output_file.puts "Starting check of original emendation #{original} with replacement #{replacement} at #{Time.now}" if type
  output_file.puts "Starting check of original emendation #{replacement} at #{Time.now}" unless type
  stopping = args.limit.to_i
  num_emended = 0
  num_unemended = 0
  num = 0
  if type
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
          output_file.puts "#{record.inspect}"
          output_file.puts "#{record.search_names.inspect}" 
          num_unemended = num_unemended + 1 
          if fix
            record.emend_all
            record.save
            output_file.puts "Fixed #{record.search_names.inspect}"
            num = num + 1
            break if stopping + 1 == num
          end
        else
         num_emended = num_emended + 1 
        end
        break if stopping + 1 == num
      end
      num_emended = num_emended - 1 if stopping + 1 == num
      num_unemended = num_unemended - 1 if stopping + 1 == num
      p "Of #{num_emendations} originals for #{original} with replacement #{replacement} #{num_emended} were emended and #{num_unemended} unemended"
  else
      # code of replacements
  end
end
