class Freecen2PlaceUniqueName
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  field :unique_surnames,  type: Hash # key year value array of surnames
  field :unique_forenames, type: Hash # key year value array of forenames
  belongs_to :freecen2_place, index: true
end
