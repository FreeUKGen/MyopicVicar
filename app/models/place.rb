class Place
  include Mongoid::Document

  include Mongoid::Timestamps::Updated::Short

  require 'chapman_code'
	require 'nokogiri'
  require 'open-uri'
  require 'net/http'
  require 'master_place_name'
   
  field :chapman_code, type: String#, :required => true
  field :place_name, type: String#, :required => true
  field :last_amended, type: String
  field :alternate_place_name, type: String
  field :place_notes, type: String
  field :genuki_url, type: String
  field :master_place_lat, type: String
  field :master_place_lon, type: String
	field :location, type: Array

  after_create :lat_and_lon_from_master_place_name
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
 
  
 # index ([[:chapman_code, Mongo::ASCENDING],[:place_name, Mongo::ASCENDING]])

  validates_inclusion_of :chapman_code, :in => ChapmanCode::values+[nil]
  validates_presence_of :place_name
   validate :lat_long_is_valid
  validate :place_does_not_exist, on: :create
  index({ chapman_code: 1, place_name: 1 }, { unique: true })
  index({ place_name: 1 })

  def place_does_not_exist 
    
      errors.add(:place_name, "already exits") if Place.where('chapman_code' => self[:chapman_code] , 'place_name' => self[:place_name]).first

  end 
  def lat_long_is_valid
   unless self[:master_place_lat].nil? || self[:master_place_lon].nil?
    errors.add(:master_place_lat, "The latitude must be between 45 and 70") unless self[:master_place_lat].to_i > 45 && self[:master_place_lat].to_i < 70
    errors.add(:master_place_lon, "The longitude must be between -10 and 5") unless self[:master_place_lon].to_i > -10 && self[:master_place_lon].to_i < 5
   end
  end

  def create_or_update_last_amended_date(freereg_file)
    register = freereg_file.register._id
    register = Register.find(register)
    church = register.church.id
    church = Church.find(church)
    
  end

  def lat_and_lon_from_master_place_name
    place = self.place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase
    master_record = MasterPlaceName.where(:chapman_code => self.chapman_code, :modified_place_name => place).first
   unless master_record.nil? 
          self.master_place_lat = master_record.latitude
          self.master_place_lon = master_record.longitude
          self.location = [self.master_place_lat, self.master_place_lon]
          self.genuki_url  = master_record.genuki_url
          self.save
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
