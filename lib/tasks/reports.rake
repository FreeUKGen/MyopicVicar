namespace :reports do
	
desc "Create a missing locations list"
 task :missing_locations, [:limit] => [:environment] do |t, args|
 require 'missing_locations' 
 
  Mongoid.unit_of_work(disable: :all) do
   
     
          MissingLocations.process(args.limit) 
          
     
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


end