class AlternateFreecen2PlaceName
  include Mongoid::Document

  field :alternate_name, type: String
  field :standard_alternate_name, type: String
  embedded_in :freecen2_place
  before_save :add_standard
  #attr_accessible :alternate_name
  def add_standard
    self.standard_alternate_name = Freecen2Place.standard_place(alternate_name)
  end
end
