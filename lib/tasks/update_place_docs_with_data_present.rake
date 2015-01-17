task :update_place_docs_with_data_present   => [:environment] do

  require "place"
  Mongoid.load!("#{Rails.root}/config/mongoid.yml")

  lim = 0
  type_of_build = "add"
  puts "starting a #{type_of_build} with a limit of #{lim} files"

  file_for_warning_messages = "log/place_field_creation_messages.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
  @@message_file = File.new(file_for_warning_messages, "w")


  l = 0
  l_errors = 0
  l_dis = 0
  l_drop = 0
  number_of_places = Place.count
  p "Processing #{number_of_places} places"
  @@message_file.puts "Processing #{number_of_places} places"

  Place.all.no_timeout.each do |place|
    data_present = false
    place.churches.each do |church|
      church.registers.each do |register|
        if register.freereg1_csv_files.exists?
          data_present = true
          l_dis = l_dis + 1
        end
      end
    end
  place.update_attributes(:data_present => data_present) unless place.data_present == data_present
    if place.errors.any?
      l_errors = l_errors + 1
      @@message_file.puts "#{place.place_name},#{place.chapman_code},#{place.errors.messages},Place update failed "
      p "#{place.place_name},#{place.chapman_code},#{place.errors.messages},Place update failed "

    end  #er
  l = l + 1
  break if l == lim 
end
  

p "#{l} names processed with #{l_errors} errors and #{l_dis} with data"
@@message_file.puts "#{l} names processed with #{l_errors} errors and #{l_dis} with data"

end #method
