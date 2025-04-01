namespace :reports do

  desc "extract_null_place_locations"
  task :extract_null_place_locations, [:limit] => [:environment] do |t, args|
    require 'extract_null_place_locations'
    limit = args.limit
    puts "extract_null_place_locations"
    ExtractNullPlaceLocations.process(limit)
    puts "Completed Checking #{limit} unique names"
  end
  desc "count_valentines_marriages"
  task :count_valentines_marriages, [:limit] => [:environment] do |t, args|
    require 'count_valentines_marriages'
    limit = args.limit
    puts "count_valentines_marriages"
    CountValentinesMarriages.process(limit)
    puts "Completed Checking #{limit} years"
  end

  desc "extract_unique_names"
  task :extract_unique_names, [:limit] => [:environment] do |t, args|
    require 'extract_unique_names'
    limit = args.limit
    puts "Extracting unique names"
    ExtractUniqueNames.process(limit)
    puts "Completed Checking #{limit} unique names"
  end

  desc "extract_collection_unique_names"
  task :extract_collection_unique_names, [:limit] => [:environment] do |t, args|
    appname = MyopicVicar::Application.config.freexxx_display_name.downcase
    require 'extract_collection_unique_names' if appname != "freebmd"
    require 'bmd_unique_names' if appname == "freebmd"
    limit = args.limit
    puts "Extracting unique names"
    ExtractCollectionUniqueNames.process(limit) if appname != "freebmd"
    BmdUniqueNames.process(limit) if appname == "freebmd"
    puts "Completed Checking #{limit} collection unique names"
  end

  desc "extract_bmd_unique_names"
  task :extract_bmd_unique_names, [:district] => [:environment] do |t, args|
    appname = MyopicVicar::Application.config.freexxx_display_name.downcase
    require 'bmd_unique_names'
    district = args.district
    puts "Extracting unique names"
    BmdUniqueNames.process(district)
    puts "Completed extracting unique names for #{district} collection unique names"
  end

  desc "extract_unique_cen_field_name"
  task :extract_unique_cen_field_name, [:limit] => [:environment] do |t, args|
    require 'extract_unique_cen_field_name'
    limit = args.limit
    puts "Extracting unique cen field names"
    ExtractUniqueCenFieldName.process(limit)
    puts "Completed Checking #{limit} unique names"
  end

  desc "Unapproved_place_names list"
  task :report_on_files_for_each_register_church_place, [:chapman,:userid] => [:environment] do |t, args|
    require 'report_on_files_for_each_register_church_place'
    p 'report_on_files_for_each_register_church_place started'
    report = ReportOnFilesForEachRegisterChurchPlace.process(args.chapman)
    user = UseridDetail.userid(args.userid).first
    UserMailer.send_logs(report, user.email_address, 'place/church/register/file report is attached', "place/church/register/file report for #{args.chapman}").deliver_now
    p 'Task complete.'
  end


  desc "check_image_availability"
  task :check_image_availability, [:limit] => :environment do |t, args|
    require 'check_image_availability'

    CheckImageAvailability.process(args.limit)

  end

  desc "Unapproved_place_names list"
  task :unapproved_place_names, [:limit] => [:environment] do |t, args|
    require 'unapproved_place_names'
    Mongoid.unit_of_work(disable: :all) do
      UnapprovedPlaceNames.process(args.limit)
      puts "Task complete."
    end
  end

  desc "Report on Register Types"
  task :extract_information_on_register_types, [:limit] => [:environment] do |t, args|
    require 'extract_information_on_register_types'
    Mongoid.unit_of_work(disable: :all) do
      ExtractInformationOnRegisterTypes.process(args.limit)
      puts "Task complete."
    end
  end

  desc "Multiple batches for a file"
  task :multiple_batches, [:limit] => [:environment] do |t, args|
    require 'multiple_batches'
    Mongoid.unit_of_work(disable: :all) do
      MultipleBatches.process(args.limit)
      puts "Task complete."
    end
  end

  desc "Jail references list"
  task :jail_reference, [:limit] => [:environment] do |t, args|
    require 'jail_references'
    Mongoid.unit_of_work(disable: :all) do
      JailReferences.process(args.limit)
      puts "Task complete."
    end
  end

  desc "Create a database content report"
  task :database_contents, [:limit,:type] => [:environment] do |t, args|
    require 'database_contents'

    Mongoid.unit_of_work(disable: :all) do


      DatabaseContents.process(args.limit,args.type)


      puts "Task complete."
    end
  end

  desc "Create a report of files loaded by people"
  # eg foo:create_search_records_docs[rebuild,e:/csvaug/a*/*.csv]
  #valid options for type are rebuild, replace, add
  task :userid_files, [:syndicate] => [:environment] do |t, args|
    require 'userids_files'

    Mongoid.unit_of_work(disable: :all) do


      UseridsFiles.process(args.syndicate)


      puts "Task complete."
    end
  end

  desc "Create a report of Unapproved Places with no data"
  # eg foo:create_search_records_docs[rebuild,e:/csvaug/a*/*.csv]
  #valid options for type are rebuild, replace, add
  task :unapproved_and_no_data, [:limit] => [:environment] do |t, args|
    require 'unapproved_and_no_data'


    UnapprovedAndNoData.process(args.limit)


    puts "Task complete."

  end

  desc "Create a report of Places with missing fields location, genuki, county and country"

  task :missing_place_fields, [:limit] => [:environment] do |t, args|
    require 'missing_place_fields'

    Mongoid.unit_of_work(disable: :all) do

      MissingPlaceFields.process(args.limit)

      puts "Task complete."
    end
  end

  desc "Create a report of Master files"
  # eg foo:create_search_records_docs[rebuild,e:/csvaug/a*/*.csv]
  #valid options for type are rebuild, replace, add
  task :master_place_name_report, [:limit] => [:environment] do |t, args|
    require 'master_place_name_report'

    Mongoid.unit_of_work(disable: :all) do


      MasterPlaceNameReport.process(args.limit)


      puts "Task complete."
    end
  end

  desc "Create a report of Userid Details"
  # eg foo:create_search_records_docs[rebuild,e:/csvaug/a*/*.csv]
  #valid options for type are rebuild, replace, add
  task :userid_details_report, [:limit] => [:environment] do |t, args|
    require 'userid_details_report'

    Mongoid.unit_of_work(disable: :all) do


      UseridDetailsReport.process(args.limit)


      puts "Task complete."
    end
  end

  desc "Review Userid Files for completeness"
  task :review_userid_files, [:len,:range,:fr] => [:environment] do |t, args|
    require 'review_userid_files'
    ReviewUseridFiles.process(args.len,args.range,args.fr)
    puts "Task complete."

  end

  desc "Create a report of Case Sensitive Userid Details"
  # eg foo:create_search_records_docs[rebuild,e:/csvaug/a*/*.csv]
  #valid options for type are rebuild, replace, add
  task :userid_details_case_report, [:limit] => [:environment] do |t, args|
    require 'userid_details_case_report'

    Mongoid.unit_of_work(disable: :all) do


      UseridDetailsCaseReport.process(args.limit)


      puts "Task complete."
    end
  end

  desc "Create a report of Forename Populations"
  # eg foo:create_search_records_docs[rebuild,e:/csvaug/a*/*.csv]
  #valid options for type are rebuild, replace, add
  task :forenames_report, [:limit] => [:environment] do |t, args|
    require 'forenames_report'
    require 'freereg1_csv_entry'

    Mongoid.unit_of_work(disable: :all) do

      Freereg1CsvEntry.create_indexes()
      ForenamesReport.process(args.limit)


      puts "Task complete."
    end
  end

  desc "Create a report of Surname Populations"
  # eg foo:create_search_records_docs[rebuild,e:/csvaug/a*/*.csv]
  #valid options for type are rebuild, replace, add
  task :surnames_report, [:limit] => [:environment] do |t, args|
    require 'surnames_report'
    require 'freereg1_csv_entry'

    Mongoid.unit_of_work(disable: :all) do

      Freereg1CsvEntry.create_indexes()
      SurnamesReport.process(args.limit)


      puts "Task complete."
    end
  end
  desc "Create a report of files with errors"

  task :list_of_error_files, [:limit] => [:environment] do |t, args|
    require 'list_of_error_files'
    require 'freereg1_csv_file'

    Mongoid.unit_of_work(disable: :all) do

      ListOfErrorFiles.process(args.limit)


      puts "Task complete."
    end
  end

  desc "Create a report of Enabled Places"
  task :check_records_place, [:chapmancode] => [:environment] do |t, args|
    require 'check_records_place'

    CheckRecordsPlace.process(args.chapmancode)
    puts "Task complete."
  end

  desc "Create a report of Churches"
  task :check_records_church, [:chapmancode] => [:environment] do |t, args|
    require 'check_records_church'

    CheckRecordsChurch.process(args.chapmancode)
    puts "Task complete."
  end

  desc "Create a report of Registers"
  task :check_records_register, [:chapmancode] => [:environment] do |t, args|
    require 'check_records_register'

    CheckRecordsRegister.process(args.chapmancode)
    puts "Task complete."
  end

  desc "Create a report of Freereg1_Csv_File"
  task :check_records_freereg1_csv_file, [:chapmancode] => [:environment] do |t, args|
    require 'check_records_freereg1_csv_file'

    CheckRecordsFreereg1CsvFile.process(args.chapmancode)
    puts "Task complete."
  end

  desc "Create a report of Search_Record"
  task :check_records_search_record => [:environment] do |t, args|
    require 'check_records_search_record'

    CheckRecordsSearchRecord.process
    puts "Task complete."
  end
end
