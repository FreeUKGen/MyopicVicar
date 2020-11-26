class Freecen2Ward
  include Mongoid::Document
  include Mongoid::Timestamps::Short
  field :name, type: String
  field :note, type: String
  field :prenote, type: String
  embedded_in :freecen2_civil_parish
end
