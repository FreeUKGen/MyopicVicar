class MasterPlaceName 
  
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  

  require 'chapman_code'
  #require 'osgb'

  field :country, type: String
  field :county, type: String
  field :chapman_code, type: String
  field :grid_reference, type: String
  field :latitude , type: String
  field :longitude, type: String
  field :place_name, type: String
  field :original_place_name, type: String
  field :original_county, type: String
  field :original_chapman_code, type: String
  field :original_country, type: String
  field :original_grid_reference, type: String
  field :original_latitude, type: String
  field :original_longitude, type: String
  field :original_source, type: String
  field :source, type: String
  field :reason_for_change, type: String
  field :other_reason_for_change, type: String
  field :genuki_url, type: String
  field :modified_place_name, type: String #This is used for comparison searching
  field :disabled, type: String, default: "false" 
  
  after_save :update_place
  index({ chapman_code: 1, modified_place_name: 1, disabled: 1 })
  index({ chapman_code: 1, place_name: 1, disabled: 1 })
  index({ chapman_code: 1, disabled: 1 })
  index({ place_name: 1, grid_reference: 1 })
  index({ source: 1})

  validate :place_does_not_exist, on: :create
  validate :grid_reference_is_valid
  validate :grid_reference_or_location_present
  validate :lat_long_is_valid
  
     
  def place_does_not_exist 

         place = MasterPlaceName.where('chapman_code' => self[:chapman_code] , 'place_name' => self[:place_name]).first 
         if place then
          if place.disabled == "true" 
          place.update_attributes(:disabled => "false") 
          errors.add(:place_name, "Place was previously disabled; it has been re-enabled; go to edit on the place")
          else
           errors.add(:place_name, "already exists")
         end 
        end
  end

  def grid_reference_is_valid
       unless (self[:grid_reference].nil? || self[:grid_reference].empty?) then
         errors.add(:grid_reference, "The grid reference is not correctly formatted") unless self[:grid_reference].is_gridref?
     end
  end

  def lat_long_is_valid
   unless self[:latitude].nil? || self[:longitude].nil?
    errors.add(:latitude, "The latitude must be between 45 and 70") unless self[:latitude].to_i > 45 && self[:latitude].to_i < 70
    errors.add(:longitude, "The longitude must be between -10 and 5") unless self[:longitude].to_i > -10 && self[:longitude].to_i < 5
   end
  end

  def grid_reference_or_location_present
    case 
    when ((self[:grid_reference].nil? || self[:grid_reference].empty?) && ((self[:latitude].nil? || self[:latitude].empty?) || (self[:longitude].nil? || self[:longitude].nil?))) 
      errors.add(:grid_reference, "Either the grid reference or the lat/lon must be present") 
    end
  end

  def update_place

    county = self.chapman_code
    place = self.place_name 
    my_place = Place.where(:chapman_code => county, :place_name =>  place).first
    unless my_place.nil?
     my_place.update_lat_and_lon_from_master_place_name 
    end 
#Write backup
    file_name = "master_place_name.json." + (Time.now.to_i).to_s 
    @mongodb_bin =   Rails.application.config.mongodb_bin_location
    @tmp_location =   Rails.application.config.mongodb_collection_temp 
    @db = Mongoid.sessions[:default][:database]
    collection = @mongodb_bin + "mongoexport --db #{@db}  --collection \"master_place_names\"  --out  " + File.join(@tmp_location, file_name )
    unless File.file?(file_name)
       output =  `#{collection}`
     
       else 
         p "file already exists"
       end
   

  end


 
  
end
