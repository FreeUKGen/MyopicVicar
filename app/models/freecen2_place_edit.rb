class Freecen2PlaceEdit
  include Mongoid::Document
  include Mongoid::Timestamps::Short
  field :editor, type: String
  field :reason, type: String
  field :created, type: DateTime
  field :previous_place_name, type: String
  field :previous_alternate_place_names, type: Array
  field :previous_county, type: String
  field :previous_chapman_code, type: String
  field :previous_country, type: String
  field :previous_grid_reference, type: String
  field :previous_latitude, type: String
  field :previous_longitude, type: String
  field :previous_source, type: String
  field :previous_website, type: String
  field :previous_notes, type: String
  embedded_in :freecen2_place
end
