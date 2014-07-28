class Place
  include Mongoid::Document

  include Mongoid::Timestamps::Updated::Short

  require 'chapman_code'
	require 'nokogiri'
  require 'open-uri'
  require 'net/http'
  require 'master_place_name'
  require 'register_type' 

  field :country, type: String
  field :county, type: String
  field :chapman_code, type: String#, :required => true
  field :place_name, type: String#, :required => true
  field :last_amended, type: String
  field :alternate_place_name, type: String
  field :place_notes, type: String
  field :genuki_url, type: String
  field :location, type: Array
  field :grid_reference, type: String
  field :latitude , type: String
  field :longitude, type: String
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
  field :modified_place_name, type: String #This is used for comparison searching
  field :disabled, type: String, default: "false" 
  field :master_place_lat, type: String
  field :master_place_lon, type: String
  field :error_flag,type: String, default: nil
  field :data_present, type: Boolean, default: false

    
  embeds_many :alternateplacenames
  
  accepts_nested_attributes_for :alternateplacenames


  validates_inclusion_of :chapman_code, :in => ChapmanCode::values+[nil]

  validates_presence_of :place_name
 
  validate :place_does_not_exist, on: :create

  validate :grid_reference_or_lat_lon_present_and_valid
  
  before_save :add_location_if_not_present
 
  index({ chapman_code: 1, modified_place_name: 1, disabled: 1 })
  index({ chapman_code: 1, place_name: 1, disabled: 1 })
  index({ chapman_code: 1, disabled: 1 })
  index({ place_name: 1, grid_reference: 1 })
  index({ source: 1})
 

  index({ location: "2dsphere" }, { min: -200, max: 200 })

  has_many :churches, dependent: :restrict
  has_many :search_records
  PLACE_BASE_URL = "http://www.genuki.org.uk"

  

 

  module MeasurementSystem 
    SI = 'si'
    ENGLISH = 'en'
    ALL_SYSTEMS = [SI, ENGLISH]
    OPTIONS = {
    'miles' => ENGLISH,
    'kilometers' => SI
    }    
    def self.system_to_units(system)
      OPTIONS.invert[system]
    end
  end
 

 

  def grid_reference_or_lat_lon_present_and_valid
    #in addition to checking for validities it also sets the location
    
      errors.add(:grid_reference, "Either the grid reference or the lat/lon must be present") if ((self[:grid_reference].nil? || self[:grid_reference].empty?) && ((self[:latitude].nil? || self[:latitude].empty?) || (self[:longitude].nil? || self[:longitude].nil?))) 
      unless (self[:grid_reference].nil? || self[:grid_reference].empty?) 
        errors.add(:grid_reference, "The grid reference is not correctly formatted") unless self[:grid_reference].is_gridref?
      end  
      unless self[:latitude].nil? || self[:longitude].nil?
            errors.add(:latitude, "The latitude must be between 45 and 70") unless self[:latitude].to_i > 45 && self[:latitude].to_i < 70
            errors.add(:longitude, "The longitude must be between -10 and 5") unless self[:longitude].to_i > -10 && self[:longitude].to_i < 5
      end #lat/lon
   end
  
 
  def place_does_not_exist 
      errors.add(:place_name, "already exits") if Place.where(:chapman_code => self[:chapman_code] , :place_name => self[:place_name], :disabled.ne => 'true' ).first
  end 

 def add_location_if_not_present
    if self.location.nil? || self.location.empty?
      if self[:latitude].nil? ||self[:longitude].nil? ||self[:latitude].empty? || self[:longitude].empty? then
               my_location = self[:grid_reference].to_latlng.to_a 
               p my_location
               self[:latitude] = my_location[0]
               self[:longitude]= my_location[1]
      end
           self.location = [self[:longitude].to_f,self[:latitude].to_f] 
    end

 end

 def change_grid_reference(grid)
   unless grid.nil?
     unless self.grid_reference == grid
      self.grid_reference = grid
      my_location = self.grid_reference.to_latlng.to_a 
      self.latitude = my_location[0]
      self.longitude = my_location[1]
      self.location = [self.longitude.to_f,self.latitude.to_f] 
      self.save(:validate => false)
     end
   end
end


 def change_lat_lon(lat,lon)
  change = "unchanged"
    unless lat.nil?  || lon.nil? 
      unless self.latitude == lat && self.longitude == lon
        self.latitude = lat
        self.longitude = lon
        self.location = [self.longitude.to_f,self.latitude.to_f]
        self.save(:validate => false)
        change = "changed"
      end 
    end
  change
 end


  def self.recalculate_last_amended_date(place)
    place.churches.each do |church|
      church.registers.each do |register|
         register.freereg1_csv_files.each do |file|
          
            file_creation_date = file.transcription_date
            file_amended_date = file.modification_date if (Freereg1CsvFile.convert_date(file.modification_date)  > Freereg1CsvFile.convert_date(file_creation_date))
            
            file_amended_date =  file_creation_date if file_amended_date.nil?
           
            register.last_amended = file_amended_date if (Freereg1CsvFile.convert_date(file_amended_date)  > Freereg1CsvFile.convert_date(register.last_amended))
            #p register.last_amended

          end #end of file
        register.save

        church.last_amended = register.last_amended if (Freereg1CsvFile.convert_date(register.last_amended ) > Freereg1CsvFile.convert_date(church.last_amended))
       # p church.last_amended
      end #end of register
      church.save
      place.last_amended = church.last_amended if (Freereg1CsvFile.convert_date(church.last_amended ) > Freereg1CsvFile.convert_date(place.last_amended))
      #p place.last_amended
    end #end of church
    place.save
  end

  def places_near(radius, system=MeasurementSystem::ENGLISH)
    earth_radius = system==MeasurementSystem::ENGLISH ? 3963 : 6379

    places = Place.geo_near(self.location).spherical.max_distance(radius.to_f/earth_radius).distance_multiplier(earth_radius).to_a
    # get rid of this place
    places.shift
    
    places
  end

  def save_to_original
    self.original_chapman_code = self.chapman_code unless !self.original_chapman_code.nil?
    self.original_county = self.county 
    self.original_country = self.country 
    self.original_place_name = self.place_name 
    self.original_grid_reference = self.grid_reference 
    self.original_latitude = self.latitude 
    self.original_longitude = self.longitude 
    self.original_source =  self.source 
  end

def change_name(place_name)
  successful = true
  self.churches.each do |church|
      church_name = church.church_name
      church.registers.each do |register|
       register.freereg1_csv_files.each do |file|
        success = Freereg1CsvFile.update_file_attribute(file,church_name,place_name )
        successful = false unless success 
       end #register
      end #church
     end #@place
    successful 
end
  
end
