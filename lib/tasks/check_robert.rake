task :check_robert,[:limit] => [:environment] do |t, args|
  file_for_warning_messages = "#{Rails.root}/log/check_robert.txt"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  output_file = File.new(file_for_warning_messages, "w")
  output_file.puts "Starting check of robert at #{Time.now}"
  stopping = args.limit.to_i
  num_robt = SearchRecord.where("search_names.first_name": "robt.").count
  p num_robt
  num_emended = 0
  num = 0
  SearchRecord.where("search_names.first_name": "will.").all.each do |robt|
    a_robert = false
     robt.search_names.each do |names|
       a_robert = true if names.first_name ==  "william" && names.origin == "e" 
    end
   # p  robt if a_robert == false
   # p robt.search_names if a_robert == false
    output_file.puts "#{robt.inspect}" if a_robert == false
    output_file.puts "#{robt.search_names.inspect}" if a_robert == false
    num_emended = num_emended + 1 if a_robert == true
    num = num + 1
    break if stopping + 1 == num
  end
  num_emended = num_emended - 1 if stopping + 1 == num
  p "Of #{num_robt} originals #{num_emended} were emended"
end
