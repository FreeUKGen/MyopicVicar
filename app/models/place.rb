class Place
  include Mongoid::Document

  require 'chapman_code'

   
  field :chapman_code, type: String#, :required => true
  field :place_name, type: String#, :required => true
  field :last_amended, type: String
  field :alternate_place_name, type: String
  field :place_notes, type: String

  has_many :churches
  field :genuki_url, type: String
  
 # index ([[:chapman_code, Mongo::ASCENDING],[:place_name, Mongo::ASCENDING]])

  validates_inclusion_of :chapman_code, :in => ChapmanCode::values+[nil]
  validates_presence_of :place_name
  validate :place_does_not_exist, on: :create
  index({ chapman_code: 1, place_name: 1 }, { unique: true })

  def place_does_not_exist 
    
      errors.add(:place_name, "already exits") if Place.where('chapman_code' => self[:chapman_code] , 'place_name' => self[:place_name]).first

  end
end
