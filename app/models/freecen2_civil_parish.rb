class Freecen2CivilParish
  include Mongoid::Document
  include Mongoid::Timestamps::Short
  require 'freecen_constants'
  field :civil_parish_name, type: String
  field :civil_parish_note, type: String
  field :parish_number, type: Integer
  validates :parish_number, numericality: { only_integer: true }, allow_blank: true
  field :parish_suffix, type: String

  embedded_in :freecen2_piece, class_name: 'Piece'

  embeds_many :freecen2_hamlets
end
