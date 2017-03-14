namespace :reports do

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

end
