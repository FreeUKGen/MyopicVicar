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

    
  embeds_many :alternateplacenames
  
  accepts_nested_attributes_for :alternateplacenames


  validates_inclusion_of :chapman_code, :in => ChapmanCode::values+[nil]

  validates_presence_of :place_name
 
  validate :place_does_not_exist, on: :create


  validate :grid_reference_is_valid
  validate :grid_reference_or_location_present
  validate :lat_long_is_valid


  #before_save :add_lat_and_lon_from_master_place_name, on: :create
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
  
 
  def place_does_not_exist 
     
        errors.add(:place_name, "already exits") if Place.where(:chapman_code => self[:chapman_code] , :place_name => self[:place_name], :disabled.ne => 'true' ).first

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

  def add_lat_and_lon_from_master_place_name
    place = self.place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase
    master_record = MasterPlaceName.where(:chapman_code => self.chapman_code, :modified_place_name => place,:disabled.ne => "true").first
   unless master_record.nil? 
          self.master_place_lat = master_record.latitude
          self.master_place_lon = master_record.longitude
          self.location = [self.master_place_lat, self.master_place_lon]
          self.genuki_url  = master_record.genuki_url
         
    else 
      master_record = MasterPlaceName.where(:chapman_code => self.chapman_code, :place_name =>self.place_name,:disabled.ne => "true").first
      unless master_record.nil? 
          self.master_place_lat = master_record.latitude
          self.master_place_lon = master_record.longitude
          self.location = [self.master_place_lat, self.master_place_lon]
          self.genuki_url  = master_record.genuki_url
      end
    end
  end
def update_lat_and_lon_from_master_place_name
    place = self.place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase
    master_record = MasterPlaceName.where(:chapman_code => self.chapman_code, :modified_place_name => place,:disabled.ne => "true").first
   unless master_record.nil? 
          self.master_place_lat = master_record.latitude
          self.master_place_lon = master_record.longitude
          self.location = [self.master_place_lat, self.master_place_lon]
          self.genuki_url  = master_record.genuki_url
          self.save
    else 
      master_record = MasterPlaceName.where(:chapman_code => self.chapman_code, :place_name =>self.place_name,:disabled.ne => "true").first
      unless master_record.nil? 
          self.master_place_lat = master_record.latitude
          self.master_place_lon = master_record.longitude
          self.location = [self.master_place_lat, self.master_place_lon]
          self.genuki_url  = master_record.genuki_url
          self.save
      end
    end
  end

  

  def places_near(radius, system=MeasurementSystem::ENGLISH)
    earth_radius = system==MeasurementSystem::ENGLISH ? 3963 : 6379

    places = Place.geo_near(self.location).spherical.max_distance(radius.to_f/earth_radius).distance_multiplier(earth_radius).to_a
    # get rid of this place
    places.shift
    
    places
  end

  
end
