class CreatePlaceDocsFromMpn
require 'chapman_code'
require "#{Rails.root}/app/models/place"

include Mongoid::Document
 
  def initialize
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
  end

  def self.process(type,lim) 
     x = CreatePlaceDocsFromMpn.new

    limit = lim.to_i
    type_of_build = type
    puts "starting a #{type_of_build} with a limit of #{limit} files"

    file_for_warning_messages = "log/place_creation_messages.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
    @@message_file = File.new(file_for_warning_messages, "w")
  
    Place.destroy_all if type_of_build == "recreate"
    Church.destroy_all if type_of_build == "recreate"
    Register.destroy_all if type_of_build == "recreate"
    l = 0
	  l_errors = 0

    number_of_places = MasterPlaceName.where.count
    p "Prcoessing #{number_of_places} places"
	   MasterPlaceName.where.all.no_timeout.each do |master_record|
       l = l + 1
      break if l == limit
      old_place = nil
      old_place = Place.where(:chapman_code => master_record.chapman_code, :place_name => master_record.place_name ).first unless type_of_build == "recreate"
      if old_place.nil?
      place = Place.new

      place.country =  master_record.country
      place.county = master_record.county
      place.chapman_code = master_record.chapman_code 
      place.place_name =  master_record.place_name
      place.master_place_lat = master_record.latitude
      place.master_place_lon = master_record.longitude
      place.location = [place.master_place_lat, place.master_place_lon]
      place.genuki_url  = master_record.genuki_url
      place.grid_reference   = master_record.grid_reference
      place.latitude = master_record.latitude
      place.longitude = master_record.longitude
      place.original_place_name = master_record.original_place_name 
      place.original_county = master_record.original_county
      place.original_chapman_code = master_record.original_chapman_code 
      place.original_country = master_record.original_country
      place.original_grid_reference = master_record.original_grid_reference 
      place.original_latitude = master_record.original_latitude
      place.original_longitude = master_record.original_longitude
      place.original_source = master_record.original_source
      place.source = master_record.source
      place.reason_for_change = master_record.reason_for_change
      place.other_reason_for_change = master_record.other_reason_for_change
      place.modified_place_name = master_record.modified_place_name#This is used for comparison searching
      place.disabled =  master_record.disabled
     

        unless place.save
           l_errors = l_errors + 1
           @@message_file.puts "#{place.place_name},#{place.chapman_code},#{place.errors.messages},Place creation failed "
           p "#{place.place_name},#{place.chapman_code},#{place.errors.messages},Place creation failed "
        
        end  #errors
      end #nil    
    end #do
     p "#{l} names processed with #{l_errors} errors"
  end #method
end #class
