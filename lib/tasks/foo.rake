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
 task :create_search_records_docs, [:num, :type, :skip] do |t, args| 
 	Mongoid.unit_of_work(disable: :all) do
      limit = args.num
      type_of_build = args.type
      sk = args.skip
      puts "Creating Search Records "
      puts "Number of documents to be processed #{args.num} type of construction #{type_of_build} and skipping #{sk} entry documents"

  	 CreateSearchRecordsDocs.process(limit,type_of_build,sk)
      puts "Completed Creating #{limit} Search records"
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
end
