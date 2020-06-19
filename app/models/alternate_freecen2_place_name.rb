class AlternateFreecen2PlaceName
  include Mongoid::Document

  field :alternate_name, type: String
  embedded_in :freecen2_place
  #attr_accessible :alternate_name
end
