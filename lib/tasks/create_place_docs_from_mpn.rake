task :create_place_docs_from_mpn   => [:environment] do 
require 'chapman_code'
require 'master_place_name'
require "place"
Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    Place.delete_all
    lim = 0
    type_of_build = "add"
    puts "starting a #{type_of_build} with a limit of #{lim} files"

    file_for_warning_messages = "log/place_creation_messages.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
    @@message_file = File.new(file_for_warning_messages, "w")
  
    
    l = 0
	  l_errors = 0
    l_dis = 0

    number_of_places = MasterPlaceName.count
    p "Prcoessing #{number_of_places} places"
     details = Hash.new
     details[:location] = Array.new
	   MasterPlaceName.all.no_timeout.each do |master_record|
       l = l + 1
      break if l == lim
      details[:country] = master_record.country
      details[:county] = master_record.county
      details[:chapman_code] = master_record.chapman_code
      details[:place_name] = master_record.place_name
      details[:master_place_lat] = master_record.latitude
      details[:master_place_lon] = master_record.longitude
      details[:location][0] =  master_record.latitude
      details[:location][1] = master_record.longitude
      details[:genuki_url] = master_record.genuki_url
      details[:grid_reference] = master_record.grid_reference
      details[:latitude] = master_record.latitude
      details[:longitude] = master_record.longitude
      details[:original_place_name] = master_record.original_place_name
      details[:original_county] = master_record.original_county
      details[:original_chapman_code] = master_record.original_chapman_code
      details[:original_country] = master_record.original_country
      details[:original_grid_reference] = master_record.original_grid_reference
      details[:original_latitude] = master_record.original_latitude
      details[:original_longitude] = master_record.original_longitude
      details[:original_source] = master_record.original_source
      details[:source] = master_record.source
      details[:reason_for_change] = master_record.reason_for_change
      details[:other_reason_for_change] = master_record.other_reason_for_change
      details[:modified_place_name] = master_record.modified_place_name#This is used for comparison searching
      details[:disabled] = master_record.disabled
      
     unless details[:disabled] == 'true'
       place = Place.create(details)
       place.save
      

        if place.errors.any?
           l_errors = l_errors + 1
           @@message_file.puts "#{place.place_name},#{place.chapman_code},#{place.errors.messages},Place creation failed "
           p "#{place.place_name},#{place.chapman_code},#{place.errors.messages},Place creation failed "
        else
         
        end  #errors
      else
        l_dis = l_dis + 1
      end
     
    end #do
    Place.create_indexes()
     p "#{l} names processed with #{l_errors} errors and #{l_dis} disabled"
 end #method

