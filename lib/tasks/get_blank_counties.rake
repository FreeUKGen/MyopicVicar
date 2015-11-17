desc "Get a list of blanlk counties"
task :blank_counties => :environment do 
  
  file_for_warning_messages = "log/blank_counties.log"
     FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
     message_file = File.new(file_for_warning_messages, "w")
     p "Started a blank county check"
     message_file.puts  "Started a blank county check"
     Place.where(:county => nil, :disabled => 'false').all.order_by(county: 1, place_name: 1).each do |place|
      message_file.puts  " #{place.place_name},#{place.chapman_code}"
     end
     p "finished"
end
