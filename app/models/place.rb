class Place
  include MongoMapper::Document
  key :chapman_code, String
  many :churches
  key :genuki_url, String
  key :place_name
end
