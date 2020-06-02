class Freecen2Hamlet
  include Mongoid::Document
  include Mongoid::Timestamps::Short
  require 'freecen_constants'
  field :name, type: String
  field :note, type: String

  embedded_in :freecen2_civil_parish, class_name: 'CivilParish'

end
