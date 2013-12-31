namespace :foo do


 desc "Process the freereg1_csv_file and create the Places documents"
# eg foo:create_places_docs[10000,rebuild]
 #valid options for type are rebuild, replace, add
 task :create_places_docs, [:num, :type] do |t, args|
  require 'create_places_docs' 
  require 'place' 
 	Mongoid.unit_of_work(disable: :all) do
      limit = args.num
      type_of_build = args.type
      puts "Creating Places "
      puts "Number of freereg1_csv_file documents to be processed #{args.num} type of construction #{type_of_build}"
  
  	  CreatePlacesDocs.process(limit,type_of_build)
      puts "Completed Creating #{limit} Places"
      Place.create_indexes()
      puts "Task complete."
  end
 end


 	
 desc "Process the freereg1_csv_entries and create the SearchRecords documents"
 # eg foo:create_search_records_docs[rebuild,e:/csvaug/a*/*.csv]
 #valid options for type are rebuild, replace, add
 task :create_search_records_docs, [:type,:pattern] => [:environment] do |t, args|
 require 'create_search_records_docs' 
 require 'search_record' 
 	Mongoid.unit_of_work(disable: :all) do
   
     filenames = Dir.glob(args[:pattern])
     filenames.sort #sort in alphabetical order, including directories
     type_of_build = args.type
       puts "Creating Search Records with #{type_of_build} option"
     l = 0
     filenames.each do |fn|
        if (l == 0 && type_of_build == "rebuild") 
          CreateSearchRecordsDocs.process(type_of_build,fn ) 
          type_of_build = "replace"
          l = l+1
        else
           CreateSearchRecordsDocs.process(type_of_build,fn ) 
        end
      
     end
    puts "Task complete."
   end
  end





 desc "Process the freereg1_csv_entries and check that there is a corresponding SearchRecords document"
  # eg foo:check_search_records[100000]
  #num is the number of records to be checked
  task :check_search_records, [:num] do |t, args| 
    require 'check_search_records'
 	Mongoid.unit_of_work(disable: :all) do
      limit = args.num 
      puts "Checking the existence of search record documents for the first #{limit} freereg1_csv_entries "
  	  CheckSearchRecords.process(limit)
      puts "Completed Checking #{limit} Search records"
    end
 end



desc "Process a csv file or directory specified thus: process_freereg_csv[../*/*.csv]"
task :process_freereg_csv, [:pattern, :type] => [:environment] do |t, args| 
  # if type is entered as create_search_records then a search record will be created for each entry
  #if type is anything else the search records will not be created. I use no_creation_of_search_records
  require 'freereg_csv_processor'
  require 'freereg1_csv_file'
  require 'freereg1_csv_entry'
  require 'register'
  require 'church'
  require 'place'
  create_search_records = args[:type]
  puts "processing CSV file with #{create_search_records}"
  filenames = Dir.glob(args[:pattern])
  filenames.sort #sort in alphabetical order, including directories
  filenames.each do |fn|
    FreeregCsvProcessor.process(fn,create_search_records)
  end
  
  puts "Task complete."
end



desc "Create the indices after all FreeREG processes have completed"
task :create_freereg_csv_indexes, [:pattern] => [:environment] do |t, args| 
  #task is there to creat indexes after running of freereg_csv_processor
  
  require 'freereg1_csv_file'
  require 'freereg1_csv_entry'
  require 'register'
  require 'church'
  require 'place'
  puts "Freereg build indexes."
  Freereg1CsvFile.create_indexes()
  #Freereg1CsvEntry.create_indexes()
  Register.create_indexes()
  Church.create_indexes()
  Place.create_indexes()
  puts "Task complete."
end


desc "Process a .uDetails file  "
task :create_transcriber_docs, [:pattern] => [:environment] do |t, args| 
  require 'create_transcriber_docs'
  filenames = Dir.glob(args[:pattern])
  puts "#{filenames}"
  filenames.sort #sort in alphabetical order, including directories
  filenames.each do |fn|
    puts "#{fn}"
    CreateTranscriberDocs.process(fn)
  end
  puts "Task complete."
end



desc "Create master_place_names from gazetteer  "
task :create_master_place_names_from_gazetteer, [:type, :add_url]  => [:environment] do |t, args| 
  # if type is rebuild then the currrent collection will be deleted and a complete new collection made
  #if anything else eg add then existing entries will be skipped over and new ones added
  # if add url is set to add_url then genuki lookup happens
  require 'create_master_place_names_from_gazetteer'
  require 'master_place_name'
  type_of_build = args.type
  add_url = args.add_url
  puts "Creating Place Names Gazetteer Documents with type #{type_of_build} and url #{add_url} "
  
    CreateMasterPlaceNamesFromGazetteer.process(type_of_build,add_url)
  puts "Collection created, now creating indexes"
  MasterPlaceName.create_indexes()
  puts "Task complete."
end



desc "Add Genuki URL to master_place_names  "
task :add_genuki_url_to_master_place_name, [:type, :add_url] => [:environment]  do |t, args| 
  # if type is rebuild then the currrent collection will be deleted and a complete new collection made
  #if anything else eg add then existing entries will be skipped over and new ones added
  # if add url is set to add_url then genuki lookup happens
  require 'add_genuki_url_to_master_place_name'
   
  type_of_build = args.type
  add_url = args.add_url
  puts "Adding Genuki URL to Master Place Name Documents with type #{type_of_build} and url #{add_url} "
  
    AddGenukiUrlToMasterPlaceName.process(type_of_build,add_url)
  
  puts "Task complete."
end



desc "Add lat and lon to place documents"
task :add_lat_lon_to_place, [:type]  => [:environment] do |t, args| 
  require 'add_lat_lon_to_place'
  require 'place'
  type_of_build = args.type
  puts "Adding lat and lon to place documents #{type_of_build}"
  
    AddLatLonToPlace.process(type_of_build)

  puts "Collection modification complete, now creating indexes."

  Place.create_indexes()
  puts "Task complete."
end

desc "check place documents"
task :check_place_docs, [:type]  => [:environment] do |t, args| 
  require 'master_place_name'
  require 'check_place_records'
  require 'place'
  type_of_build = args.type
  puts "Check Place Docs in Gazetteer"
  
    CheckPlaceRecords.process(type_of_build)

  
  puts "Task complete."
end

end



  


