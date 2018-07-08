class OpenNamesPerPlace
  include Mongoid::Document
  belongs_to :place
  field :surname, type: String
  field :description, type: String
  field :count, type: Integer, default: 0
end
