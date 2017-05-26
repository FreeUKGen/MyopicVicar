require 'chapman_code'

namespace :foo do
  # rake foo:update_search_records[number of files, record type,software version, force creation, order files are processed]
  #eg f2rake  foo:update_search_records[0,bu,"2016-05-27T19:23:31+00:00", true, 1]
  #number of files of 0 is all, force creation is true or false, order files processed is 1 or -1

  task :update_search_records,[:limit,:record_type,:version,:force, :order] => [:environment] do |t,args|
    #limit is number of files to process 0 is all
    require 'update_search_records'
    UpdateSearchRecords.process(args.limit,args.record_type,args.version,args.force,args.order)
  end
  # rake foo:get_software_version[manual,2012/1/1,2015/4/8,1.0]

  desc "Get the software version, e.g. rake foo:get_software_version[manual,2012/1/1,2015/4/8,1.0]"
  task :get_software_version,[:manual,:start,:last,:version] => :environment do |t,args|
    require 'get_software_version'
    GetSoftwareVersion.process(args.manual,args.start,args.last,args.version)
  end

  desc "Check refinery users are complete, setting fix to fix will add it"
  task :check_refinery_entries,[:limit,:fix] => :environment do |t, args|
    require 'check_refinery_entries'
    CheckRefineryEntries.process(args.limit,args.fix)
  end

  desc "Correct the witness records"
  task :correct_witness_records,[:limit,:range] => :environment do |t, args|
    require 'correct_witness_records'
    CorrectWitnessRecords.process(args.limit,args.range)
  end

  desc "Correct the multiple witness records"
  task :correct_multiple_witness_records,[:limit,:range,:fix] => :environment do |t, args|
    require 'correct_multiple_witness_records'
    CorrectMultipleWitnessRecords.process(args.limit,args.range,args.fix)
  end

  desc "Initialize the Physical files collection"
  task :load_physical_file_records,[:limit,:range] => :environment do |t, args|
    require 'load_physical_file_records'
    LoadPhysicalFileRecords.process(args.limit,args.range)
    PhysicalFile.create_indexes()
  end

  desc "Process the freereg1_csv_entries and check that there is a corresponding SearchRecords document"
  # eg foo:check_search_records[100000]
  #num is the number of records to be checked
  task :check_search_records, [:num] => [:environment]do |t, args|
    require 'check_search_records'
    Mongoid.unit_of_work(disable: :all) do
      limit = args.num
      puts "Checking the existence of search record documents for the first #{limit} freereg1_csv_entries "
      CheckSearchRecords.process(limit)
      puts "Completed Checking #{limit} Search records"
    end
  end
  desc "Correct missing modified_place_names list"
  task :missing_modified_place_names, [:limit] => [:environment] do |t, args|
    require 'missing_modified_place_names'
    Mongoid.unit_of_work(disable: :all) do
      MissingModifiedPlaceNames.process(args.limit)

      puts "Task complete."
    end
  end

  # eg foo:check_search_records[100000]
  #num is the number of records to be checked
  task :add_record_digest, [:num,:range] => [:environment]do |t, args|
    require 'add_record_digest'
    Mongoid.unit_of_work(disable: :all) do
      limit = args.num
      puts "Adding record digest "
      AddRecordDigest.process(limit,args.range)
      puts "Completed adding #{limit} record digests"
    end
  end
  desc "Process the freereg1_csv_entries and check that there is a corresponding SearchRecords document"
  # eg foo:check_search_records[100000]
  #num is the number of records to be checked
  task :check_record_digest, [:num] => [:environment]do |t, args|
    require 'check_record_digest'
    Mongoid.unit_of_work(disable: :all) do
      limit = args.num
      puts "Checking record digest "
      CheckRecordDigest.process(limit)
      puts "Completed checking #{limit} record digests"
    end
  end



  desc "Create the indexes after all FreeREG processes have completed"
  task :create_freereg_csv_indexes => [:environment] do
    #task is there to create indexes after running of freereg_csv_processor
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
    require "physical_file"
    puts "Freereg build indexes."
    Country.create_indexes()
    County.create_indexes()
    Syndicate.create_indexes()
    UseridDetail.create_indexes()
    Freereg1CsvFile.create_indexes()
    Register.create_indexes()
    Church.create_indexes()
    Place.create_indexes()
    BatchError.create_indexes()
    Contact.create_indexes()
    Feedback.create_indexes()
    SearchQuery.create_indexes()
    AtticFile.create_indexes()
    Freereg1CsvEntry.create_indexes()
    SearchRecord.create_indexes()
    PhysicalFile.create_indexes()
    puts "Indexes complete."
  end

  desc "Create the search record indices "
  task :create_search_records_indexes => [:environment] do
    #task is there to create indexes after running of freereg_csv_processor
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
    db = Mongoid.clients[:default][:database]
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
    if args.extras.count == 0
      PlaceCache.refresh_all
    else
      args.extras.each { |a| PlaceCache.refresh(a.to_s) }
    end
  end

  desc "Clear the rake_processing_lock"
  task :clear_processing_lock => [:environment] do |t,args|
    rake_lock_file = File.join(Rails.root,"tmp","processing_rake_lock_file.txt")
    if File.exist?(rake_lock_file)
      p "FREEREG:CSV_PROCESSING: removing rake lock file #{rake_lock_file}"
      FileUtils.rm(rake_lock_file, :force => true)
    else
      p "FREEREG:CSV_PROCESSING: Rake lock file did not exist"
    end
  end

  desc "Check and Refresh the places cache"
  task :check_and_refresh_places_cache => [:environment] do |t,args|
    PlaceCache.check_and_refresh_if_absent
    p "finished"
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

  desc "Load attic files"
  task :load_files_into_userid_details, [:len,:range,:fr] => [:environment] do |t, args|
    require 'load_files_into_userid_details'
    LoadFilesIntoUseridDetails.process(args.len,args.range,args.fr)
    puts "Task complete."

  end

  desc "Refresh UCF lists on places"
  task :refresh_ucf_lists, [:skip] => [:environment] do |t,args|
    Place.order(:chapman_code => :asc, :place_name => :asc).no_timeout.all.each_with_index do |place, i|
      unless args.skip && i < args.skip.to_i
        Freereg1CsvFile.where(:place_name => place.place_name).order(:file_name => :asc).all.each do |file|
          print "#{i}\tUpdating\t#{place.chapman_code}\t#{place.place_name}\t#{file.file_name}\n"
          place.update_ucf_list(file)
        end
        place.save!
      end
    end
  end
  
  desc "Recalculate SearchRecord for Freereg1CsvEntry ids in a file"
  task :recalc_search_record_for_entries_in_file, [:id_file,:limit] => [:environment] do |t,args|
    p "starting"
    number = 0
    stop_after = args.limit.to_i
    p "doing #{stop_after} records"
    lines = File.readlines(args.id_file).map { |l| l.to_s }
    p "#{lines.length} records to process"
    lines.each do |line|
      break if number > stop_after 
      number = number + 1
      if line =~ /^#/
        p "Rebuilding "
        p line
      else
        p line
        entry = Freereg1CsvEntry.find(line.chomp)
        record = entry.search_record
        begin
          if record.freereg1_csv_entry && record.freereg1_csv_entry.freereg1_csv_file 
            p record.search_date
            p record.secondary_search_date
            p "#{entry.birth_date} #{entry.baptism_date} #{entry.burial_date} #{entry.marriage_date} "
            search_record_parameters = Freereg1Translator.translate(entry.freereg1_csv_file, entry)
            p search_record_parameters
            record.update_attributes(search_record_parameters)
            record.transform
            p record.search_date
            p record.secondary_search_date
            record.save!
            break if record.search_date.nil?
            p "passed"
          end
        rescue => e
          binding.pry
          record.transform
        end
      end
    end
    p "#{number} records processed"
  end
  
end
