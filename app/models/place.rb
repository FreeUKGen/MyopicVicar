class Place
  include MongoMapper::Document

  embedded_callbacks_off
  
  key :chapman_code, String
  many :churches
  key :genuki_url, String
  key :place_name
end
