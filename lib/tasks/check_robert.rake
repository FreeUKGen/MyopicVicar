task :check_robert,[:batch] => [:environment] do |t, args|
  file_for_warning_messages = "#{Rails.root}/log/check_robert.txt"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  output_file = File.new(file_for_warning_messages, "a")
  output_file.puts "Starting check of robert at #{Time.now}"
  num_robt = SearchRecord.where("search_names.first_name": "robt.").count
  p num_robt
  SearchRecord.where("search_names.first_name": "robt.").all.each do |robt|
    a_robert = false
     robt.search_names.each do |names|
       a_robert = true if names.first_name ==  "robert" && names.origin == "e" 
    end
    p  robt if a_robert == false
    p robt.search_names if a_robert == false
    output_file.puts robt if a_robert == false
    output_file.puts robt.search_names if a_robert == false
  end
  
end
