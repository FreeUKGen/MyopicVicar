namespace :build do

 $collections = Array.new
 $collections[0] = "master_place_names"
 $collections[1] = "alias_place_churches"  
 $collections[2] = "places"
 $collections[3] = "churches"
 $collections[4] = "registers"
 $collections[5] = "freereg1_csv_files"
 $collections[6] = "freereg1_csv_entries"
 $collections[7] = "search_records"
 COLLECTIONS = {
'master_place_names' => 'MasterPlaceName',
'alias_place_churches' => 'AliasPlaceChurch',
'places' => 'Place',
'churches' => 'Church',
'registers' => 'Register',
'freereg1_csv_files' => 'Freereg1CsvFile',
'freereg1_csv_entries' => 'Freereg1CsvEntry',
'search_records' => 'SearchRecord'
}
EXPORT_COMMAND =  "mongoexport --db myopic_vicar_development --collection  "
 EXPORT_OUT = " --out  "
 IMPORT_COMMAND =  "mongoimport --db myopic_vicar_development --collection  "
 IMPORT_IN = " --file  "

# example build:freereg_from_files["0/1","2/3/4/5/6/7", "0/1","2/3/4/5","0/1/2/3/4/5"]
#this saves and reloads the Master and Alias collections, drops the other 6 collections, reloads 4 of those from the github respository
#and indexes everything
# example build:freereg_from_files["","","","0/1","0/1"]
#reloads the Mater and Alias collections from Github and indexes them
# example build:freereg_from_files["","","2/3/4/5/6/7","0/1","0/1/2/3/4/5/6/7"]
#relaoads saved versions of Places/Churches/Registers/Files/Entries/Search_records from tmp and reloads the Mater and Alias 
#collections from Github and indexes them all
#******************************NOTE************************************
#it uses the @mongodb_bin =   Rails.application.config.mongodb_bin_location where the Mongodb binary are located
# @tmp_location = Rails.application.config.mongodb_collection_temp to store the temp files
#@file_location =  Rails.application.config.mongodb_collection_location the location of the github ollections
#from the developmentapplication.config
task :freereg_from_files,[:save, :drop, :reload_from_temp, :load_from_file, :index] => [:recreate_freereg_csv_indexes,:environment] do |t,args|
puts "Completed rebuild of FreeREG"
end

task :save_freereg_collections,[:save, :drop, :reload_from_temp, :load_from_file, :index] => [:environment] do |t,args|
 puts "Saving collections"
 EXPORT_COMMAND =  "mongoexport --db myopic_vicar_development --collection  "
 EXPORT_OUT = " --out  "
 collections_to_save = Array.new
 @mongodb_bin =   Rails.application.config.mongodb_bin_location
 @tmp_location =   Rails.application.config.mongodb_collection_temp
 collections_to_save = args[:save].split("/")
   collections_to_save.each  do |col|
    coll  = col.to_i
    collection = @mongodb_bin + EXPORT_COMMAND + $collections[coll] + EXPORT_OUT + @tmp_location + $collections[coll] + ".json"
    puts "#{$collections[coll]} being saved in #{@tmp_location}"
     output =  `#{collection}`
     p output
  end
 puts "Save task compelete"
end

task :drop_freereg_collections,[:save, :drop, :reload_from_temp, :load_from_file, :index] => [:save_freereg_collections, :environment] do |t,args|
  puts "Dropping collections"
  collections_to_drop = args[:drop].split("/")
   collections_to_drop.each  do |col|
     coll  = col.to_i
     model = COLLECTIONS[$collections[coll]].constantize if COLLECTIONS.has_key?($collections[coll]) 
     model.collection.drop
     puts "#{$collections[coll]} dropped"
   end
 puts "Collections drop task completed"
end

task :reload_freereg_collections_from_temp,[:save, :drop, :reload_from_temp, :load_from_file, :index] => [:drop_freereg_collections, :environment] do |t,args|
 puts "Reloading collections"
 IMPORT_COMMAND =  "mongoimport --db myopic_vicar_development --collection  "
 IMPORT_IN = " --file  "
 collections_to_reload = Array.new
 @mongodb_bin =   Rails.application.config.mongodb_bin_location
 @tmp_location =   Rails.application.config.mongodb_collection_temp
  collections_to_reload = args[:reload_from_temp].split("/")
  collections_to_reload.each  do |col|
    coll  = col.to_i
    collection = @mongodb_bin + IMPORT_COMMAND + $collections[coll] + IMPORT_IN + @tmp_location + $collections[coll] + ".json"
    puts "#{$collections[coll]} being reloaded from #{@tmp_location}"
    p collection
    output = `#{collection}`
    p output
  end
 puts "Reload task compelete "
end

task :load_freereg_collections_from_file,[:save, :drop, :reload_from_temp, :load_from_file, :index] => [:reload_freereg_collections_from_temp, :environment] do |t,args|
 puts "Loading collections"
 IMPORT_COMMAND =  "mongoimport --db myopic_vicar_development --collection  "
 IMPORT_IN = " --file  "
 collections_to_load = Array.new
 @mongodb_bin =   Rails.application.config.mongodb_bin_location
 @tmp_location =   Rails.application.config.mongodb_collection_temp
 @file_location =  Rails.application.config.mongodb_collection_location
 collections_to_load = args[:load_from_file].split("/")
 collections_to_load.each  do |col|
    coll  = col.to_i
    collection = @mongodb_bin + IMPORT_COMMAND + $collections[coll] + IMPORT_IN + @file_location + $collections[coll] + ".json"
    puts "#{$collections[coll]} being loaded from #{@file_location}"
    p collection
    output = `#{collection}`
    puts output
  end
 puts "Load task compelete"
end

desc "Create the indices after all FreeREG processes have completed"
task :recreate_freereg_csv_indexes,[:save, :drop, :reload_from_temp, :load_from_file, :index] => [:load_freereg_collections_from_file, :environment] do  |t,args|
  require 'freereg1_csv_file'
  require 'freereg1_csv_entry'
  require 'register'
  require 'church'
  require 'place'
  collections_to_index = Array.new
   collections_to_index = args[:index].split("/")
  puts "Freereg build indexes."
   collections_to_index.each  do |col|
     coll  = col.to_i
     model = COLLECTIONS[$collections[coll]].constantize if COLLECTIONS.has_key?($collections[coll]) 
     model.create_indexes()
     puts "#{$collections[coll]} indexed"
   end
    puts " Index task complete."
end




# example build:freereg[recreate,create_search_records,e:/freereg8/,a-d,e-f"]
#This processes the csv files located at e:/freereg8/ and creates the search records at the same time. Before doing so it
# saves a copy of the Master and Alias; it drops Places/Churches/Registers/Freere1_csv_files,Freereg1_csv_entries and search records.
#it then runs a csv_process on all userids starting with a, b, c and then d with another process doing e, and f. and reloads the Master and Alias collections, drops the other 6 collections, reloads 4 of those from the github respository
#and indexes everything
# example build:freereg[recreate,create_search_records,e:/freereg8/,*.WRY*.csv,*.NOR*.csv]
# this creates a database for WRY and NOR  with search records from all files
# it saves Master and Alias before dropping everything and rebuilding and re-indexing
#example build:freereg[add,create_search_records,e:/freereg8/,userid/wryconba.csv,useridb/norabsma.csv]
#this adds the records for 2 specific files to the existing database
#******************************NOTE************************************
#it uses the @mongodb_bin =   Rails.application.config.mongodb_bin_location where the Mongodb binary are located
# @tmp_location = Rails.application.config.mongodb_collection_temp to store the temp files
#@file_location =  Rails.application.config.mongodb_collection_location the location of the github ollections
#from the developmentapplication.config








  task :freereg,[:type,:search_records,:base_dirctory,:range1,:range2] => [:setup,:create_freereg_csv_indexes] do |t, args| 
    p "completed build"
  end

task :setup => [:setup_index, :environment] do |t, args| 

  system("Rake load_emendations") 
  puts "Setup finished"

 end

 task :setup_save,[:type] => [ :environment] do |t, args| 
 @mongodb_bin =   Rails.application.config.mongodb_bin_location
 @tmp_location =   Rails.application.config.mongodb_collection_temp
 #@datafile_location =  Rails.application.config.mongodb_datafile
 #save master_place_names and alias
 p "Save started"
  collections_to_save = ["0","1"]
   collections_to_save.each  do |col|
    coll  = col.to_i
    collection = @mongodb_bin + EXPORT_COMMAND + $collections[coll] + EXPORT_OUT + @tmp_location + $collections[coll] + ".json"
    puts "#{$collections[coll]} being saved in #{@tmp_location}"
     output =  `#{collection}`
     p output
   end
   p "Save finished"
  end

  task :setup_drop,[:type]  => [:setup_save, :environment] do |t, args| 
  puts "Dropping collections"
  #dops place, church, register, files
  if :type == "recreate"
  collections_to_drop = ["2","3","4","5","6","7"]
   collections_to_drop.each  do |col|
     coll  = col.to_i
     model = COLLECTIONS[$collections[coll]].constantize if COLLECTIONS.has_key?($collections[coll]) 
     model.collection.drop
     puts "#{$collections[coll]} dropped"
   end 
   end
 puts "Collections drop task completed"
end

task :setup_index => [:setup_drop, :environment] do |t, args| 
  puts "Creating minimum indexes"
 script_index_places = @mongodb_bin + 'mongo myopic_vicar_development --eval "db.places.ensureIndex({place_name:1 })"'
   `#{script_index_places}`
   p "#{ Index creation failed $?.to_i}" unless $?.to_i == 0 
  script_index_places_chapman = @mongodb_bin + 'mongo myopic_vicar_development --eval "db.places.ensureIndex({chapman_code: 1, place_name:1 })"'
 `#{script_index_places_chapman}`
   p "#{ Index creation failed $?.to_i}" unless $?.to_i == 0 
 script_index_registers_alternate = @mongodb_bin + 'mongo myopic_vicar_development --eval "db.registers.ensureIndex({church_id:1, alternate_register_name: 1 })"'
 `#{script_index_registers_alternate}`
    p "#{ Index creation failed $?.to_i}" unless $?.to_i == 0 
 script_index_registers = @mongodb_bin + 'mongo myopic_vicar_development --eval "db.registers.ensureIndex({church_id:1, register_name: 1 })"'
 `#{script_index_registers}`
   p "#{ Index creation failed $?.to_i}" unless $?.to_i == 0 
  script_index_churches = @mongodb_bin + 'mongo myopic_vicar_development --eval "db.churches.ensureIndex({place_id: 1, church_name: 1 })"'
 `#{script_index_churches}`
   p "#{ Index creation failed $?.to_i}" unless $?.to_i == 0 
 script_index_freereg1_csv_files = @mongodb_bin + 'mongo myopic_vicar_development --eval "db.freereg1_csv_files.ensureIndex({file_name: 1, userid: 1, county: 1, place: 1 , church_name: 1, register_type: 1})"'
 `#{script_index_freereg1_csv_files}`
    p "#{ Index creation failed $?.to_i}" unless $?.to_i == 0 
 script_index_freereg1_csv_entries = @mongodb_bin + 'mongo myopic_vicar_development --eval "db.freereg1_csv_entries.ensureIndex({freereg1_csv_file_id:1 })"'
 `#{script_index_freereg1_csv_entries}`
    p "#{ Index creation failed $?.to_i}" unless $?.to_i == 0 
 script_index_search_records = @mongodb_bin + 'mongo myopic_vicar_development --eval "db.search_records.ensureIndex({freereg1_csv_file_id :1 })"' 
      `#{script_index_search_records}`
    p "#{ Index creation failed $?.to_i}" unless $?.to_i == 0 
     puts "Minimum indexes created"

end
 
 #This was an attempt to see if invoking 2 rake tasks as separate threads helps; it does not
 task :parallelr,[:type,:search_records,:base_dirctory,:range1,:range2] => [:environment]  do |t, args| 
  require "freereg_csv_processor"
    p "Starting processors"
    base_directory = args.base_dirctory
    range1 = args.range1
    range2 = args.range2
    type = args.type
    search_records = args.search_records
    Rake::Task['build:process_csv'].invoke(type,search_records,base_directory,range1)
    Rake::Task['build:process_csv'].reenable
    Rake::Task['build:process_csv'].invoke(type,search_records,base_directory,range1)
    p "Completed processors"
 end

#This was an attempt to see if spinning off 2 2 rake processes helps; it does not
# I tried forking them but fork is unsupported in Windows.
task :parallelp,[:type,:search_records,:base_dirctory,:range1,:range2] => [:environment]  do |t, args| 
  p "Starting processors"
  p args
    base_directory = args.base_dirctory
    range1 = args.range1
    range2 = args.range2
    type = args.type
    search_records = args.search_records
    
    system("Rake build:process_csv[#{type},#{search_records},#{base_directory},#{range1}]") 
    system("Rake build:process_csv[#{type},#{search_records},#{base_directory},#{range2}]") 
    
    p "Completed processors"
 end

 
desc "Create the indices after all FreeREG processes have completed"
task :create_freereg_csv_indexes => [:parallelp,:environment] do  
  #task is there to creat indexes after running of freereg_csv_processor
  
  require 'freereg1_csv_file'
  require 'freereg1_csv_entry'
  require 'register'
  require 'church'
  require 'place'
  puts "Freereg build indexes."
  Freereg1CsvFile.create_indexes()
  Freereg1CsvEntry.create_indexes()
  Register.create_indexes()
  Church.create_indexes()
  Place.create_indexes()
  puts "Indexes complete."
end

desc "Process the freereg1_csv_entries and create the SearchRecords documents"
 # eg foo:create_search_records_docs[rebuild,e:/csvaug/a*/*.csv]
 #valid options for type are rebuild, replace, add
 task :create_search_records_docs, [:type,:search_records,:base_dirctory] => [:create_freereg_csv_indexes,:environment] do |t, args|
 require 'create_search_records_docs' 
 require 'search_record' 
  Mongoid.unit_of_work(disable: :all) do
    base_directory = args.base_dirctory
  aplha = Array.new
  alpha = args[:range2].split("-") 
  alpha_start = ALPHA.find_index(alpha[0])
  alpha_end = ALPHA.find_index(alpha[1]) + 1
  create_search_records = args.search_records
  puts "Processing CSV file with #{args.search_records}"
  index = alpha_start
  while index < alpha_end do 
    pattern = base_directory + ALPHA[index] + "*/*.csv"
    filenames = Dir.glob(pattern).sort
    filenames.each do |fn|
      
      CreateSearchRecordsDocs.process(create_search_records,fn ) if create_search_records == 'create_search_records'
    end
    index = index + 1
   end
     puts "Search Records complete."
   end
  end

task :process_csv,[:type,:search_records,:base_directory,:range,] => [:environment] do |t, args| 

  require 'freereg_csv_processor'
  require 'freereg1_csv_file'
  require 'freereg1_csv_entry'
  require 'register'
  require 'church'
  require 'place'

  puts "processing CSV file with #{args.search_records}"
  FreeregCsvProcessor.process(args.type,args.search_records, args.base_directory, args.range)
  puts "Freereg task complete."

 end

end



 