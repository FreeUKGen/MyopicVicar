class AlternateFreecen2PlaceName
  include Mongoid::Document

  field :alternate_name, type: String
  field :standard_alternate_name, type: String
  field :alternate_name_soundex, type: String
  embedded_in :freecen2_place
  before_save :add_standard, :add_alternate_name_soundex
  #attr_accessible :alternate_name
  def add_standard
    self.standard_alternate_name = Freecen2Place.standard_place(alternate_name)
  end

  def add_alternate_name_soundex
    self.alternate_name_soundex = Text::Soundex.soundex(self.alternate_name)
  end
end
