namespace :foo do

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

task :correct_master_place_records, [:limit]  => [:environment] do |t, args| 
 
  require 'correct_master_place_records'
 
  puts "Correcting Master Place Name Records "
  
    CorrectMasterPlaceRecords.process(args.limit)
  #puts "Collection created, now creating indexes"
 # MasterPlaceName.create_indexes()
  puts "Task complete."
end

desc "Add lat and lon to place documents or checks for errors between Master and Places"
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

desc "Create the indices after all FreeREG processes have completed"
task :create_freereg_csv_indexes => [:environment] do  
  #task is there to creat indexes after running of freereg_csv_processor
  require 'search_record'
  require 'freereg1_csv_file'
  require 'freereg1_csv_entry'
  require 'register'
  require 'church'
  require 'place'
  require "userid_detail"
  require "syndicate"
   require "county"
    require "country"
  puts "Freereg build indexes."
  Country.create_indexes()
  County.create_indexes()
  Syndicate.create_indexes()
  UseridDetail.create_indexes()
  SearchRecord.create_indexes()
  Freereg1CsvFile.create_indexes()
  Freereg1CsvEntry.create_indexes()
  Register.create_indexes()
  Church.create_indexes()
  Place.create_indexes()
  puts "Indexes complete."
end

desc "Create the search record indices "
task :create_search_records_indexes => [:environment] do  
  #task is there to creat indexes after running of freereg_csv_processor
  require 'search_record'
 
  puts "Search records build indexes."

  SearchRecord.create_indexes()
 
  puts "Indexes complete."
end

 task :create_userid_docs, [:type]  => [:environment] do |t, args| 
 #this task reads the .uDetails file for each userid and creates the userid_detail collection  
  require 'create_userid_docs'
   require "userid_detail"
  puts "Creating Transcriber Docs"
  range = "*/*.uDetails"
    CreateUseridDocs.process(args.type,range )
    UseridDetail.create_indexes()
  
  puts "Task complete."
 end
 
 task :create_syndicate_docs, [:type]  => [:environment] do |t, args| 
   # This takes reads a csv file of syndicate coordinators and creates the syndicates collection
  require 'create_syndicate_docs'
  range = "syndicate_coordinators.csv"
  puts "Creating Syndicate Docs"
  
    CreateSyndicateDocs.process(args.type,range )
    Syndicate.create_indexes()
  
  puts "Task complete."
 end


 task :create_county_docs, [:type]  => [:environment] do |t, args| 
   # This takes reads a csv file of syndicate coordinators and creates the syndicates collection
  require 'create_county_docs'
  range = "county_coordinators.csv"
  puts "Creating County Docs"
  
    CreateCountyDocs.process(args.type,range )
    County.create_indexes()

  
  puts "Task complete."
 end
 
task :create_country_docs, [:type]  => [:environment] do |t, args| 
   # This takes reads a csv file of syndicate coordinators and creates the syndicates collection
  require 'create_country_docs'
  range = "country_coordinators.csv"
  puts "Creating Country Docs"
  
    CreateCountryDocs.process(args.type,range )
    Country.create_indexes()
  
  puts "Task complete."
 end

task :update_freereg_with_new_syndicate  => [:environment] do |t,args|
   # This takes reads a csv file of syndicate coordinators and creates the syndicates collection
  require 'update_freereg_syndicate'
  
  puts "Updating Freereg Files with updated syndicate"
  
   UpdateFreeregSyndicate.process( )
    Freereg1CsvFile.create_indexes()
  
  puts "Task complete."
 end

  task :testbed => [:environment] do |t,args|
  @mongodb_bin =   Rails.application.config.mongodb_bin_location
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    db = Mongoid.sessions[:default][:database]

    p 'Testing'
    p db
 script_index_places = @mongodb_bin + "mongo #{db} --eval \"db.places.ensureIndex({place_name:1 })\""
   `#{script_index_places}`
   p "#{ Index creation failed $?.to_i}" unless $?.to_i == 0 

  p "finished"
    
  end
desc "Process the freereg1_csv_entries and create the SearchRecords documents"
 # eg foo:create_search_records_docs[rebuild,e:/csvaug/a*/*.csv]
 #valid options for type are rebuild, replace, add
 task :parallel_create_search_records, [:type,:search_records,:range1,:range2,:range3] => [:environment] do |t, args|
 # only parallel create search records if we are recreating else the processor does it
    if args.search_records == 'create_search_records_parallel'  then
       time_start = Time.now
     puts "Processing entries to search records with #{args.search_records}"
     pid1 = Kernel.spawn("rake build:create_search_records[#{args.type},#{args.search_records},#{args.range1}]")  
     pid2 = Kernel.spawn("rake build:create_search_records[#{args.type},#{args.search_records},#{args.range2}]")  unless args.range2.nil?
     pid3 = Kernel.spawn("rake build:create_search_records[#{args.type},#{args.search_records},#{args.range3}]")  unless args.range3.nil?
     p Process.waitall
      time_end = Time.now
    process_time = time_end - time_start
     puts "Search Records complete in #{process_time}."
    end
  end
 task :export_freereg_collections,[:save] => [:environment] do |t,args|
  $collections = Array.new
 $collections[0] = "master_place_names"
 $collections[1] = "alias_place_churches"  
 $collections[2] = "places"
 $collections[3] = "churches"
 $collections[4] = "registers"
 $collections[5] = "freereg1_csv_files"
 $collections[6] = "freereg1_csv_entries"
 $collections[7] = "search_records"
 $collections[8] = "userid_details"
 $collections[9] = "syndicates"
 $collections[10] = "counties"
 $collections[11] = "countries"

 COLLECTIONS = {
'master_place_names' => 'MasterPlaceName',
'alias_place_churches' => 'AliasPlaceChurch',
'places' => 'Place',
'churches' => 'Church',
'registers' => 'Register',
'freereg1_csv_files' => 'Freereg1CsvFile',
'freereg1_csv_entries' => 'Freereg1CsvEntry',
'search_records' => 'SearchRecord',
'userid_details' => 'UseridDetail',
'syndicates' => 'Syndicate',
'counties' => 'County',
'countries' => 'Country'

}
fields = Array.new
fields[0] = 
"country,county,chapman_code,grid_reference,latitude,longitude,place_name,original_place_name,original_county,original_chapman_code,original_country,original_grid_reference,original_latitude,original_longitude,original_source,source,reason_for_change,other_reason_for_change,genuki_url,modified_place_name,disabled,c_at,u_at"
 puts "Exporting collections"
  Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    @db = Mongoid.sessions[:default][:database]
 EXPORT_COMMAND =  "mongoexport --db #{@db} --collection  "
 EXPORT_OUT = " --out  "
 collections_to_save = Array.new
 @mongodb_bin =   Rails.application.config.mongodb_bin_location
 @tmp_location =   Rails.application.config.mongodb_collection_temp
 
 unless args[:save].nil?
 collections_to_save = args[:save].split("/")
   collections_to_save.each  do |col|
    coll  = col.to_i
    collection = @mongodb_bin + EXPORT_COMMAND + $collections[coll] + " --fields #{fields[coll]} " + EXPORT_OUT + @tmp_location + '/' + $collections[coll] + ".csv"
    puts "#{$collections[coll]} being exported in #{@tmp_location}"
    p collection
     output =  `#{collection}`
     p output
  end
end
 puts "Export task compelete"
end




end
