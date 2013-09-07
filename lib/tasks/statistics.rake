namespace :statistics do

    
   require "freereg1_csv_file_contents"  
    desc "Process freereg csv file documents for county, place, church, userid or file"
    task :freereg1_csv_file_contents, [:county, :place, :church, :userid, :file] do |t, args|
    	Mongoid.unit_of_work(disable: :all) do
    user_id = args.userid  
    county = args.county
    place = args.place
    church = args.church
    file = args.file
    puts "Starting Freereg1 Csv File contents reporter for county: #{county} place: #{place} church: #{church} user_id: #{user_id} file: #{file}"
    Freereg1CsvFileContents.process(county,place,church,user_id,file)
    puts "Finished county_page_process task"
    end
    end
end