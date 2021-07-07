class Freecen2Township
  include Mongoid::Document
  include Mongoid::Timestamps::Short
  require 'freecen_constants'
  field :name, type: String
  field :note, type: String
  field :prenote, type: String
  embedded_in :freecen2_civil_parish
end
