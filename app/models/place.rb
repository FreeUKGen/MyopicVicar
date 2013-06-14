class Place
  include Mongoid::Document

  field :chapman_code, type: String
  field :place_name
  embeds_many :churches
  field :genuki_url, type: String
 
end
