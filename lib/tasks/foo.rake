namespace :foo do
	require 'create_places'
 desc "Process the freereg1_csv_filea and create the Places documents"
 task :create, [:num, :type] do |t, args| 
   limit = args.num
   type_of_build = args.type
   puts "Creating Places "
   puts "num = #{args.num} type = #{type_of_build}"
  
  	CreatePlaces.process(limit,type_of_build)
 end
end
