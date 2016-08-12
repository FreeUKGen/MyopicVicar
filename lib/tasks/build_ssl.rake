namespace :build_ssl do

  $collections = Array.new
  $collections[0] = "master_place_names"
  $collections[1] = "batch_errors"
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
  $collections[12] = "feedbacks"
  $collections[13] = "search_queries"
  $collections[14] = "contacts"
  $collections[15] = "attic_files"


  # example build:freereg[recreate,create_search_records,a-d,e-f,g-h]
  #This processes the csv files and creates the search records at the same time. Before doing so it
  # saves a copy of the Master and Alias; it drops Places/Churches/Registers/Freere1_csv_files,Freereg1_csv_entries and search records.
  #it then runs a csv_process on all userids starting with a, b, c and then d with another process doing e, and f. and reloads the Master and Alias collections, drops the other 6 collections, reloads 4 of those from the github respository
  #and indexes everything
  # example build:freereg[recreate,create_search_records,*/WRY*.csv,*/NFK*.csv,*/DEN*.csv]
  # this creates a database for WRY and NFK  with search records from all files
  # it saves Master and Alias before dropping everything and rebuilding and re-indexing
  #example build:freereg[add,create_search_records,userid/wryconba.csv,userid/norabsma.csv,]
  #this adds the records for 2 specific files to the existing database
  #******************************NOTE************************************
  #it uses a number of settings located in config environment development
  # config.mongodb_bin_location        where the Mongodb binary are located
  # config.mongodb_collection_temp     where to store the temp files
  # config.mongodb_collection_location where the github collections are located
  #       as well as the date of the dataset being used
  # config.dataset_date = "13 Dec 2013"

  task :freereg,[:type,:search_records,:range1,:range2,:range3,:port] => [:setup,:create_freereg_csv_indexes] do |t, args|
    p "completed build"
  end

  task :setup => [ :environment] do |t, args|
    require 'emendation_rule'
    require 'emendation_type'
    puts "Start Setup"
    file_for_warning_messages = "log/freereg_messages.log"
    File.delete(file_for_warning_messages) if File.exists?(file_for_warning_messages)
    @@message_file = File.new(file_for_warning_messages, "a")
    @@message_file.chmod( 0664 )
    puts "Freereg messages log deleted."
    x = system("rake load_emendations")
    puts "Emendations loaded" if x
    EmendationRule.create_indexes()
    EmendationType.create_indexes()
    puts "Setup finished"

  end

  task :setup_save,[:type,:search_records,:range1,:range2,:range3,:port] => [:setup, :environment] do |t, args|
    @mongodb_bin =   Rails.application.config.mongodb_bin_location
    @tmp_location =   Rails.application.config.mongodb_collection_temp
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    @db = Mongoid.clients[:default][:database]
    #@datafile_location =  Rails.application.config.mongodb_datafile
    #save master_place_names and alias
    p "Save started"
    collections_to_save = ["0","1","2","3","4","8","9","10","11","12","13","14","15"]
    p "using database #{@db} on port #{args.port}"
    collections_to_save.each  do |col|
      coll  = col.to_i
      collection = @mongodb_bin + EXPORT_COMMAND + "#{@db} --ssl --port #{args.port}  --collection " + $collections[coll] + EXPORT_OUT + File.join(@tmp_location, $collections[coll] + ".json")
      puts "#{$collections[coll]} being saved in #{@tmp_location}"
      output =  `#{collection}`
      p output
    end
    p "Save finished"
  end

  task :setup_drop,[:type]  => [:setup_save, :environment] do |t, args|
    puts "Collections drop task initiated"
    #dops place, church, register, files
    if args.type == "recreate"

      collections_to_drop = ["5","6","7",]
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

    script_index_places = @mongodb_bin + "mongo #{@db} --eval \"db.places.ensureIndex({place_name: 1 })\""
    `#{script_index_places}`
    p "Index creation result #{$?.to_i}" unless $?.to_i == 0
    script_index_places_chapman = @mongodb_bin + "mongo #{@db} --eval \"db.places.ensureIndex({chapman_code: 1, place_name: 1 })\""
    `#{script_index_places_chapman}`
    p "Index creation result #{$?.to_i}" unless $?.to_i == 0
    script_index_registers_alternate = @mongodb_bin + "mongo #{@db} --eval \"db.registers.ensureIndex({church_id: 1, alternate_register_name: 1 })\""
    `#{script_index_registers_alternate}`
    p "Index creation result #{$?.to_i}" unless $?.to_i == 0
    script_index_registers = @mongodb_bin + "mongo #{@db} --eval \"db.registers.ensureIndex({church_id: 1, register_name: 1 })\""
    `#{script_index_registers}`
    p "Index creation result #{$?.to_i}" unless $?.to_i == 0
    script_index_churches = @mongodb_bin + "mongo #{@db} --eval \"db.churches.ensureIndex({place_id: 1, church_name: 1 })\""
    `#{script_index_churches}`
    p "Index creation result #{$?.to_i}" unless $?.to_i == 0
    script_index_freereg1_csv_files = @mongodb_bin + "mongo #{@db} --eval \"db.freereg1_csv_files.ensureIndex({file_name: 1, userid: 1, county: 1, place: 1 , church_name: 1, register_type: 1})\""
    `#{script_index_freereg1_csv_files}`
    p "Index creation result #{$?.to_i}" unless $?.to_i == 0
    script_index_freereg1_csv_entries = @mongodb_bin + "mongo #{@db} --eval \"db.freereg1_csv_entries.ensureIndex({freereg1_csv_file_id: 1 })\""
    `#{script_index_freereg1_csv_entries}`
    p "Index creation result #{$?.to_i}" unless $?.to_i == 0
    script_index_search_records_entries = @mongodb_bin + "mongo #{@db} --eval \"db.search_records.ensureIndex({freereg1_csv_entry_id: 1 })\""
    `#{script_index_search_records_entries}`
    p "Index creation result #{$?.to_i}" unless $?.to_i == 0
    puts "Minimum indexes created"

  end

  #This spinning off 1,2 or 3 rake csv_processes.
  task :parallelp,[:type,:search_records,:range1,:range2,:range3] => [:setup_index, :environment]  do |t, args|
    p "Starting processors"

    search_records = args.search_records
    time_start = Time.now
    pid1 = Kernel.spawn("rake build:process_freereg1_csv[#{args.type},#{args.search_records},#{args.range1}]")
    pid2 = Kernel.spawn("rake build:process_freereg1_csv[#{args.type},#{args.search_records},#{args.range2}]") unless args.range2.nil?
    pid3 = Kernel.spawn("rake build:process_freereg1_csv[#{args.type},#{args.search_records},#{args.range3}]") unless args.range3.nil?
    p "#{pid1} #{pid2}  #{pid3}  started at #{time_start}"
    p Process.waitall
    time_end = Time.now
    process_time = time_end - time_start
    p "Completed processors in #{process_time}"
  end

  desc "Process the freereg1_csv_entries and create the SearchRecords documents"
  # eg foo:create_search_records_docs[rebuild,e:/csvaug/a*/*.csv]
  #valid options for type are rebuild, replace, add
  task :parallel_create_search_records, [:type,:search_records,:range1,:range2,:range3] => [:parallelp,:environment] do |t, args|
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

  task :create_search_records, [:type,:search_records,:range] => [:environment] do |t, args|
    require 'create_search_records_docs'
    @mongodb_bin =   Rails.application.config.mongodb_bin_location
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    @db = Mongoid.clients[:default][:database]
    search_records = "create_search_records"
    script_index_search_records_entries = @mongodb_bin  + "mongo #{@db} --eval \"db.search_records.ensureIndex({freereg1_csv_entry_id: 1 })\""
    p script_index_search_records_entries
    `#{script_index_search_records_entries}`
    p "Index creation result #{$?.to_i}" unless $?.to_i == 0

    CreateSearchRecordsDocs.process(args.type,search_records,args.range )
    exit(true)
  end

  # # This is the processing task. It can be invoked on its own as build:process_freereg1_csv[] with
  # #parameters as defined for build:freereg EXCEPT there is only one range argument
  # #NOTE NO SETUP of the database IS DONE DURING THIS TASK
  # task :process_freereg1_csv,[:type,:search_records,:range] => [:environment] do |t, args|
  #
  # require 'freereg_csv_processor'
  # # use the processor to initiate search record creation on add or update but not on recreation when we do at end
  # search_records = "no_search_records"
  # search_records = "create_search_records" if args.search_records == "create_search_records_processor"
  #
  # puts "processing CSV file with #{args.type} and #{search_records}"
  # success = FreeregCsvProcessor.process(args.type,search_records,args.range)
  # if success
  # puts "Freereg task complete."
  # exit(true)
  # else
  # puts "Freereg task failed"
  #
  # exit(false)
  # end
  # end
  # task :process_freereg1_individual_csv,[:user,:file] => [:environment] do |t, args|
  #
  # require 'freereg_csv_processor'
  # require 'user_mailer'
  # # use the processor to initiate search record creation on add or update but not on recreation when we do at end
  # range = File.join(args.user ,args.file)
  # search_records = "create_search_records"
  #
  # success = FreeregCsvProcessor.process("recreate",search_records,range)
  # if success
  # UserMailer.batch_processing_success(args.user,args.file).deliver
  # exit(true)
  # else
  # file = File.join(Rails.application.config.datafiles,args.user,args.file)
  # if File.exists?(file)
  # p file
  # File.delete(file)
  # end
  # exit(false)
  # end
  # end

  desc "Create the indexes after all FreeREG processes have completed"
  task :create_freereg_csv_indexes => [:parallel_create_search_records, :setup_index, :environment] do
    #task is there to create indexes after running of freereg_csv_processor
    require 'batch_error'
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
    require "contact"
    require "feedback"
    require "search_query"
    require "attic_file"


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
    BatchError.create_indexes()
    Contact.create_indexes()
    Feedback.create_indexes()
    SearchQuery.create_indexes()
    AtticFile.create_indexes()

    puts "Indexes complete."
  end

  # example build:freereg_from_files["0/1","2/3/4/5/6/7", "0/1","2/3/4/5","0/1/2/3/4/5"]
  #this saves and reloads the Master and Alias collections, drops the other 6 collections, reloads 4 of those from the github respository
  #and indexes everything
  # example build:freereg_from_files["","","","0/1","0/1"]
  #reloads the Mater and Alias collections from Github and indexes them
  # example build:freereg_from_files["","","2/3/4/5/6/7","0/1","0/1/2/3/4/5/6/7"]
  #reloads saved versions of Places/Churches/Registers/Files/Entries/Search_records from tmp and reloads the Mater and Alias
  #collections from Github and indexes them all
  #******************************NOTE************************************
  #it uses the @mongodb_bin =   Rails.application.config.mongodb_bin_location where the Mongodb binary are located
  # @tmp_location = Rails.application.config.mongodb_collection_temp to store the temp files
  #@file_location =  Rails.application.config.mongodb_collection_location the location of the github collections
  #from the development application.config
  task :freereg_from_files,[:save, :drop, :reload_from_temp, :load_from_file, :index, :port] => [:recreate_freereg_csv_indexes,:environment] do |t,args|
    puts "Completed rebuild of FreeREG"
  end

  task :save_freereg_collections,[:save, :drop, :reload_from_temp, :load_from_file, :index, :port] => [:environment] do |t,args|
    puts "Saving collections"
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    @db = Mongoid.clients[:default][:database]
    EXPORT_COMMAND =  "mongoexport --db #{@db} --ssl --port #{args.port} --collection  "
    EXPORT_OUT = " --out  "
    p "using database #{@db} on port #{args.port}"
    collections_to_save = Array.new
    @mongodb_bin =   Rails.application.config.mongodb_bin_location
    @tmp_location =   Rails.application.config.mongodb_collection_temp
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    @db = Mongoid.clients[:default][:database]
    unless args[:save].nil?
      collections_to_save = args[:save].split("/")
      collections_to_save.each  do |col|
        coll  = col.to_i
        location = File.join(@tmp_location, collection_array[coll] + ".json")
        #saved_file = File.new(location,"w")
        collection = @mongodb_bin + EXPORT_COMMAND  + collection_array[coll] + EXPORT_OUT + location
        #saved_file.close
        puts "#{collection_array[coll]} being saved in #{@tmp_location}"
        output =  `#{collection}`
        p output
      end
    end
    puts "Save task complete"
  end

  task :drop_freereg_collections,[:save, :drop, :reload_from_temp, :load_from_file, :index] => [:save_freereg_collections, :environment] do |t,args|
    puts "Dropping collections"
    unless args[:drop].nil?
      collections_to_drop = args[:drop].split("/")
      collections_to_drop.each  do |col|
        coll  = col.to_i
        model = COLLECTIONS[$collections[coll]].constantize if COLLECTIONS.has_key?($collections[coll])
        model.collection.drop
        puts "#{$collections[coll]} dropped"
      end
    end
    puts "Collections drop task completed"
  end

  task :reload_freereg_collections_from_temp,[:save, :drop, :reload_from_temp, :load_from_file, :index, :port] => [:drop_freereg_collections, :environment] do |t,args|
    puts "Reloading collections"
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    @db = Mongoid.clients[:default][:database]
    IMPORT_COMMAND =  "mongoimport --db #{@db} --ssl --port #{args.port} --collection  "
    IMPORT_IN = " --file  "
    p "using database #{@db} on port #{args.port}"
    collections_to_reload = Array.new
    @mongodb_bin =   Rails.application.config.mongodb_bin_location
    @tmp_location =   Rails.application.config.mongodb_collection_temp
    unless args[:reload_from_temp].nil?
      collections_to_reload = args[:reload_from_temp].split("/")
      collections_to_reload.each  do |col|
        coll  = col.to_i
        collection = @mongodb_bin + IMPORT_COMMAND + $collections[coll] + IMPORT_IN + File.join(@tmp_location, $collections[coll] + ".json")
        puts "#{$collections[coll]} being reloaded from #{@tmp_location}"
        p collection
        output = `#{collection}`
        p output
      end
    end
    puts "Reload task complete "
  end

  task :load_freereg_collections_from_file,[:save, :drop, :reload_from_temp, :load_from_file, :index, :port] => [:reload_freereg_collections_from_temp, :environment] do |t,args|
    puts "Loading collections"
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    @db = Mongoid.clients[:default][:database]
    IMPORT_COMMAND =  "mongoimport --db #{@db} --ssl --port #{args.port} --collection  "
    IMPORT_IN = " --file  "
    p "using database #{@db} on port #{args.port}"
    collections_to_load = Array.new
    @mongodb_bin =   Rails.application.config.mongodb_bin_location
    @tmp_location =   Rails.application.config.mongodb_collection_temp
    @file_location =  Rails.application.config.mongodb_collection_location
    unless args[:load_from_file].nil?
      collections_to_load = args[:load_from_file].split("/")
      collections_to_load.each  do |col|
        coll  = col.to_i
        collection = @mongodb_bin + IMPORT_COMMAND + $collections[coll] + IMPORT_IN + File.join(@file_location, $collections[coll] + ".json")
        puts "#{$collections[coll]} being loaded from #{@file_location}"
        p collection
        output = `#{collection}`
        puts output
      end
    end
    puts "Load task complete"
  end

  desc "Create the indexes after all FreeREG processes have completed"
  task :recreate_freereg_csv_indexes,[:save, :drop, :reload_from_temp, :load_from_file, :index] => [:load_freereg_collections_from_file, :environment] do  |t,args|
    require "county"
    require "country"
    require "userid_detail"
    require "syndicate"
    require "search_record"
    require 'freereg1_csv_file'
    require 'freereg1_csv_entry'
    require 'register'
    require 'church'
    require 'place'
    require "contact"
    require "feedback"
    require "search_query"
    require "attic_file"

    collections_to_index = Array.new
    unless args[:index].nil?
      collections_to_index = args[:index].split("/")
      puts "Freereg build indexes."
      collections_to_index.each  do |col|
        coll  = col.to_i
        model = COLLECTIONS[$collections[coll]].constantize if COLLECTIONS.has_key?($collections[coll])
        model.create_indexes()
        puts "#{$collections[coll]} indexed"
      end
    end
    puts " Index task complete."
  end
  task :backup_freereg_collections,[:save, :port] => [:environment] do |t,args|
    puts "Backing collections"
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    @db = Mongoid.clients[:default][:database]
    EXPORT_COMMAND =  "mongoexport --db #{@db} --ssl --port #{args.port} --collection  "
    EXPORT_OUT = " --out  "
    p "using database #{@db} on port #{args.port}"
    collections_to_save = ["0","1","2","3","4","5","8","9","10","11","12","13","14","15"] if args.save == 'partial'
    collections_to_save = ["0","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15"] if args.save == 'full'
    @mongodb_bin =   Rails.application.config.mongodb_bin_location
    @tmp_location =   Rails.application.config.mongodb_collection_location
    @tmp_location = File.join(@tmp_location, Time.now.to_i.to_s )
    FileUtils.mkdir(@tmp_location)

    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    @db = Mongoid.clients[:default][:database]

    collections_to_save.each  do |col|
      coll  = col.to_i
      collection = @mongodb_bin + EXPORT_COMMAND + $collections[coll] + EXPORT_OUT + @tmp_location + '/' + $collections[coll] + ".json"
      puts "#{$collections[coll]} being saved in #{@tmp_location}"
      output =  `#{collection}`
      p output
    end

    puts "Save task complete"
  end

  task :freereg_update,[:range,:type,:delta] => [:environment] do |t,args|
    require 'freereg_csv_update_processor'
    @mongodb_bin =   Rails.application.config.mongodb_bin_location
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    db = Mongoid.clients[:default][:database]
    p db
    host = Mongoid.clients[:default][:hosts].first
    p host

    FreeregCsvUpdateProcessor.process(args.range,args.type,args.delta)

  end

  task :delete_entries_records_for_removed_batches => [:environment] do |t,args|
    # base = 1 uses the change files directory and base = 2 uses the actual files directory
    require 'delete_entries_records_for_removed_batches'
    @mongodb_bin =   Rails.application.config.mongodb_bin_location
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    db = Mongoid.clients[:default][:database]
    p db
    host = Mongoid.clients[:default][:hosts].first
    p host

    DeleteEntriesRecordsForRemovedBatches.process
  end


end
