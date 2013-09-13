namespace :foo do

 require 'create_places_docs'
 desc "Process the freereg1_csv_file and create the Places documents"
 task :create_places_docs, [:num, :type] do |t, args|  
 	Mongoid.unit_of_work(disable: :all) do
      limit = args.num
      type_of_build = args.type
      puts "Creating Places "
      puts "Number of freereg1_csv_file documents to be processed #{args.num} type of construction #{type_of_build}"
  
  	  CreatePlacesDocs.process(limit,type_of_build)
      puts "Completed Creating #{limit} Places"
    end
 end


 	require 'create_search_records_docs'
 desc "Process the freereg1_csv_entries and create the SearchRecords documents"
 task :create_search_records_docs, [:type,:pattern] => [:environment] do |t, args| 
 	Mongoid.unit_of_work(disable: :all) do
     puts "Creating Search Records "
     filenames = Dir.glob(args[:pattern])
     type_of_build = args.type
     l = 0
     filenames.each do |fn|
        if (l == 0 && type_of_build == "rebuild") 
          CreateSearchRecordsDocs.process(type_of_build,fn ) 
          type_of_build = "build"
          l = l+1
        else
           CreateSearchRecordsDocs.process(type_of_build,fn ) 
        end
      
     end
    puts "Task complete."
   end
  end




require 'check_search_records'
 desc "Process the freereg1_csv_entries and check that there is a corresponding SearchRecords document"
 task :check_search_records, [:num] do |t, args| 
 	Mongoid.unit_of_work(disable: :all) do
      limit = args.num 
      puts "Checking the existence of search record documents for the first #{limit} freereg1_csv_entries "
  	  CheckSearchRecords.process(limit)
      puts "Completed Checking #{limit} Search records"
    end
 end

require 'freereg_csv_processor'

desc "Process a csv file or directory specified thus: process_freereg_csv[../*/*.csv]"
task :process_freereg_csv, [:pattern] => [:environment] do |t, args| 
  # if we ever need to switch this to multiple files, see
  # http://stackoverflow.com/questions/3586997/how-to-pass-multiple-parameters-to-rake-task
  #print "Processing file passed in rake process_freereg_csv[filename]=#{args[:file]}\n" 
  filenames = Dir.glob(args[:pattern])
  filenames.sort #sort in alphabetical order, including directories
  filenames.each do |fn|
    FreeregCsvProcessor.process(fn)
  end
  puts "Task complete."
end


end
