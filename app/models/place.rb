class Place
  include Mongoid::Document

  field :chapman_code, type: String
  has_many :churches
  field :genuki_url, type: String
  field :place_name
end
