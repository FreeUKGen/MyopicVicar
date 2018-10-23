class OpenNamesPerPlace
  include Mongoid::Document
  belongs_to :place, index: true
  field :surname, type: String
  field :description, type: String
  field :count, type: Integer, default: 0
end
