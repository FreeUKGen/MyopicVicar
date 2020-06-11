class Freecen2CivilParish
  include Mongoid::Document
  include Mongoid::Timestamps::Short
  require 'freecen_constants'
  field :name, type: String
  field :note, type: String
  field :number, type: Integer
  validates :number, numericality: { only_integer: true }, allow_blank: true
  field :suffix, type: String

  belongs_to  :freecen2_piece, optional: true, index: true

  embeds_many :freecen2_hamlets

  delegate :year, :name, :tnaid, :number, :code, :note, to: :freecen2_piece, prefix: :piece, allow_nil: true

  index(piece_name: 1, piece_year: 1, name: 1)
end
