class Place
  include Mongoid::Document

  field :chapman_code, type: String
  embeds_many :churches
  field :genuki_url, type: String
  field :place_name
end
