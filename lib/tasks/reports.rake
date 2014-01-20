namespace :reports do
	
desc "Create a missing locations list"
 # eg foo:create_search_records_docs[rebuild,e:/csvaug/a*/*.csv]
 #valid options for type are rebuild, replace, add
 task :missing_locations, [:limit] => [:environment] do |t, args|
 require 'missing_locations' 
 
  Mongoid.unit_of_work(disable: :all) do
   
     
          MissingLocations.process(args.limit) 
          
     
    puts "Task complete."
   end
  end





end