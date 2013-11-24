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

  has_many :churches
  has_many :search_records
 
  
 # index ([[:chapman_code, Mongo::ASCENDING],[:place_name, Mongo::ASCENDING]])

  validates_inclusion_of :chapman_code, :in => ChapmanCode::values+[nil]
  validates_presence_of :place_name
  validate :place_does_not_exist, on: :create
  index({ chapman_code: 1, place_name: 1 }, { unique: true })

  def place_does_not_exist 
    
      errors.add(:place_name, "already exits") if Place.where('chapman_code' => self[:chapman_code] , 'place_name' => self[:place_name]).first

  end


	def geocode(xml_root)
		geocode_from_pastplace(File.join(xml_root, "pastplace", self.to_xml_basename))		
		geocode_from_geonames(File.join(xml_root, "geonames", self.to_xml_basename))		
		save!
		self
  end

  def geocode_from_pastplace(filename)
		file = File.open(filename)
		doc = Nokogiri::XML(file)
		self[:pastplace_lat] = doc.xpath('//place/lat').text
		self[:pastplace_lon] = doc.xpath('//place/lon').text
		file.close
  end

	def geocode_from_geonames(filename)
		file = File.open(filename)
		doc = Nokogiri::XML(file)
		self[:geonames_lat] = doc.xpath('//geoname/lat').text
		self[:geonames_lon] = doc.xpath('//geoname/lon').text
		file.close
	end

  def to_xml_basename
    "#{self[:chapman_code]}_#{self[:place_name]}.xml".gsub(" ", "_")
  end
end
