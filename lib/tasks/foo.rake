require 'chapman_code'
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

  desc "Create the indexes after all FreeREG processes have completed"
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
    script_index_places = @mongodb_bin + "mongo #{db} --eval \"db.places.ensureIndex({place_name:1 })\""
    `#{script_index_places}`
    p "#{ Index creation failed $?.to_i}" unless $?.to_i == 0
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


  desc "Refresh the places cache"
  task :refresh_places_cache => [:environment] do |t,args|
    PlaceCache.refresh_all
  end


  task :create_userid_docs, [:type,:range]  => [:environment] do |t, args|
    #this task reads the .uDetails file for each userid and creates the userid_detail collection
    require 'create_userid_docs'
    require "userid_detail"
    puts "Creating Transcriber Docs"
    CreateUseridDocs.process(args.type,args.range)
    puts "Task complete."
  end

  desc "Update userids and create a report of any problem email addresses"
  # eg foo:create_search_records_docs[rebuild,e:/csvaug/a*/*.csv]
  #valid options for type are rebuild, replace, add
  task :report_problem_email_address, [:range] => [:environment] do |t, args|
    require 'report_problem_email_address'

    Mongoid.unit_of_work(disable: :all) do
    ReportProblemEmailAddress.process(args.range)
      puts "Task complete."
    end
  end

  desc "report on user details"
  task :review_userid_docs, [:oldset, :newset, :range] => [:environment] do |t, args|
    require 'review_userid_docs'
    Mongoid.unit_of_work(disable: :all) do
      ReviewUseridDocs.process(args.oldset,args.newset,args.range)
      puts "Task complete."
    end
  end

desc "report on user details"
  task :review_userid_files, [:len,:range] => [:environment] do |t, args|
    require 'review_userid_files'
    Mongoid.unit_of_work(disable: :all) do
      ReviewUseridFiles.process(args.len,args.range)
      puts "Task complete."
    end
  end

  task :freereg_update,[:range] => [:environment] do |t,args|
    require 'review_changed_files'
    @mongodb_bin =   Rails.application.config.mongodb_bin_location
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    db = Mongoid.sessions[:default][:database]
    p db
    host = Mongoid.sessions[:default][:hosts].first
    p host
    
      ReviewChangedFiles.process(args.range)
   
  end

end
