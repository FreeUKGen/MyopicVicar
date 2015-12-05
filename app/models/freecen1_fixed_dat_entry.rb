class Freecen1FixedDatEntry
  include Mongoid::Document
  field :piece_number, type: String
  field :district_name, type: String
  field :subplaces, type: Array
  field :parish_number, type: String
  field :suffix, type: String
  belongs_to :freecen1_fixed_dat_file
  has_one :freecen_piece
end
