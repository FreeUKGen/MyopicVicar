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
'freereg1_csv_entries' => 'Freereg1CsvEntries',
'search_records' => 'SearchRecords'
}
task :freereg_from_files,[:save, :drop, :reload_from_temp, :load_from_file, :index] => [:recreate_freereg_csv_indexes,:environment] do |t,args|
puts "Completed rebuild of FreeREG"
end

task :save_freereg_collections,[:save, :drop, :reload_from_temp, :load_from_file, :index] => [:environment] do |t,args|
 puts "Saving collections"
 EXPORT_COMMAND =  "mongoexport --db myopic_vicar_development --collection  "
 EXPORT_OUT = " --out  "
 collections_to_save = Array.new
 @mongobd_bin =   Rails.application.config.mongodb_bin_location
 @tmp_location =   Rails.application.config.mongodb_collection_temp
 collections_to_save = args[:save].split("/")
   collections_to_save.each  do |col|
    coll  = col.to_i
    collection = @mongobd_bin + EXPORT_COMMAND + $collections[coll] + EXPORT_OUT + @tmp_location + $collections[coll] + ".json"
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
 @mongobd_bin =   Rails.application.config.mongodb_bin_location
 @tmp_location =   Rails.application.config.mongodb_collection_temp
  collections_to_reload = args[:reload_from_temp].split("/")
  collections_to_reload.each  do |col|
    coll  = col.to_i
    collection = @mongobd_bin + IMPORT_COMMAND + $collections[coll] + IMPORT_IN + @tmp_location + $collections[coll] + ".json"
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
 @mongobd_bin =   Rails.application.config.mongodb_bin_location
 @tmp_location =   Rails.application.config.mongodb_collection_temp
 @file_location =  Rails.application.config.mongodb_collection_location
 collections_to_load = args[:load_from_file].split("/")
 collections_to_load.each  do |col|
    coll  = col.to_i
    collection = @mongobd_bin + IMPORT_COMMAND + $collections[coll] + IMPORT_IN + @file_location + $collections[coll] + ".json"
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

end



 