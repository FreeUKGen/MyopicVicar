class Place
  include Mongoid::Document

  require 'chapman_code'
	require 'nokogiri'

   
  field :chapman_code, type: String#, :required => true
  field :place_name, type: String#, :required => true
  field :last_amended, type: String
  field :alternate_place_name, type: String
  field :place_notes, type: String
  field :genuki_url, type: String

	field :pastplace_lat, type: String
  field :pastplace_lon, type: String
  field :geonames_lat, type: String
  field :geonames_lon, type: String

  field :location, type: Array
  
  index({ location: "2dsphere" }, { min: -200, max: 200 })

  has_many :churches
  has_many :search_records
  

  module MeasurementSystem 
    SI = :si
    ENGLISH = :english
  end
 
  
 # index ([[:chapman_code, Mongo::ASCENDING],[:place_name, Mongo::ASCENDING]])

  validates_inclusion_of :chapman_code, :in => ChapmanCode::values+[nil]
  validates_presence_of :place_name
  validate :place_does_not_exist, on: :create
  index({ chapman_code: 1, place_name: 1 }, { unique: true })

  def place_does_not_exist 
    
      errors.add(:place_name, "already exits") if Place.where('chapman_code' => self[:chapman_code] , 'place_name' => self[:place_name]).first

  end


  def places_near(radius, system=MeasurementSystem::ENGLISH)
    earth_radius = system==MeasurementSystem::ENGLISH ? 3963 : 6379

    places = Place.geo_near(self.location).spherical.max_distance(radius.to_f/earth_radius).distance_multiplier(earth_radius).to_a
    # get rid of this place
    places.shift
    
    places
  end

  # xml_root defines the root for the UkHgisPlaceProviders repository on the local filesystem
	def geocode!(xml_root)
		geocode_from_pastplace(File.join(xml_root, "pastplace", self.to_xml_basename))		
		geocode_from_geonames(File.join(xml_root, "geonames", self.to_xml_basename))		
		
		fill_location
		
		save!
		
		self
  end

  def fill_location
    # pastplace seems to be higher quality than geonames, so use that first
    if !self.pastplace_lat.blank?
      self.location=[self.pastplace_lat.to_f, self.pastplace_lon.to_f]
    else
      self.location=[self.geonames_lat.to_f, self.geonames_lon.to_f]      
    end
  end

  def geocode_from_pastplace(filename)
    p filename
    return unless File.exists?(filename)

		file = File.open(filename)
		doc = Nokogiri::XML(file)
		self[:pastplace_lat] = doc.xpath('//place/lat').text
		self[:pastplace_lon] = doc.xpath('//place/lon').text
		file.close
  end

	def geocode_from_geonames(filename)
	  p filename
    return unless File.exists?(filename)

		file = File.open(filename)
		doc = Nokogiri::XML(file)
		geonames_count=doc.xpath('//totalResultsCount').text.to_i
		if geonames_count > 0
  		self[:geonames_lat] = doc.xpath('//geoname/lat').first.text
  		self[:geonames_lon] = doc.xpath('//geoname/lng').first.text
		end
		file.close
	end

  def to_xml_basename
    "#{self[:chapman_code]}_#{self[:place_name]}.xml".gsub(" ", "_")
  end
end
