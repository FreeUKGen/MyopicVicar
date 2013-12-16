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
	field :pastplace_lat, type: String
  field :pastplace_lon, type: String
  field :geonames_lat, type: String
  field :geonames_lon, type: String

  field :location, type: Array

  after_create :lat_and_lon_from_master_place_name
  index({ location: "2dsphere" }, { min: -200, max: 200 })

  has_many :churches
  has_many :search_records
  PLACE_BASE_URL = "http://www.genuki.org.uk"

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
          self.save!
    else
      # Master does not have the place name lets look at Genuki
      # type 0 Complete word (default) 1 Exact match 2 Word ending 3 Word beginning 4 Word containing 
      type = 1
      self.genuki_extract(type)
    
      if self.location[0].nil? then
      #not found in Master of Genuki lets try past place and Geoname
        self.geocode!("D:/Users/Kirk/Documents/GitHub/UkHgisPlaceProviders")
      end      
    end
  end

  def genuki_extract(type)
      genuki_uri = URI('http://www.genuki.org.uk/cgi-bin/gaz')
      genuki_page = Net::HTTP.post_form(genuki_uri, 'PLACE' => self.place_name, 'CCC' => self.chapman_code, 'TYPE' => type)
      our_page = Nokogiri::HTML(genuki_page.body)
     if our_page.css('div').text =~  /does not match any place name in the gazetteer/ 
          self.genuki_url = "no url"
          self.location = [nil,nil]
          self.save!
     else
         page_tr = our_page.css('table').css('tr')
         individual_td = page_tr[5].css('td')
         county =individual_td [0].text.chomp
         ref = individual_td [2].text.chomp
         location = ref.to_latlng.to_s.split(",")
         url = individual_td [3].css("a")
         place = url[0].text.chomp
         self.location = [location[0].to_f,location[1].to_f]
         self.genuki_url = PLACE_BASE_URL + url[0]["href"]
         self.master_place_lat = location[0].to_f
         self.master_place_lon = location[1].to_f
         self.save!   
         #lets save the record in the master collection
         master_record =  MasterPlaceName.new()
         master_record.chapman_code = self.chapman_code
         master_record.place_name = self.place_name
         master_record.modified_place_name = self.place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase
         master_record.genuki_url = self.genuki_url
         master_record.grid_reference = ref
         master_record.latitude = location[0].to_f
         master_record.longitude = location[1].to_f
         master_record.source = "Genuki"
         master_record.save!   
         
     end
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
          self.master_place_lat = self.pastplace_lat.to_f
          self.master_place_lon = self.pastplace_lon.to_f
          source = "PastPlaces"
    else
     if !self.geonames_lat.blank? then
      self.master_place_lat = self.geonames_lat.to_f
      self.master_place_lon = self.geonames_lon.to_f
          source = "GeoNames"
      end
    end
      self.location = [self.master_place_lat, self.master_place_lon]
      if !self.master_place_lat.blank? then
          master_place = MasterPlaceName.new()
          master_place.place_name = self.place_name
          master_place.chapman_code = self.chapman_code
          master_place.latitude = self.master_place_lat
          master_place.longitude = self.master_place_lon
          master_place.source = source
          master_place.save!
      end
  end

  def geocode_from_pastplace(filename)
   
    return unless File.exists?(filename)

		file = File.open(filename)
		doc = Nokogiri::XML(file)
		self[:pastplace_lat] = doc.xpath('//place/lat').text
		self[:pastplace_lon] = doc.xpath('//place/lon').text
		file.close
  end

	def geocode_from_geonames(filename)
	 
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
