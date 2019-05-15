class Freecen1FixedDatEntry
  include Mongoid::Document
  field :piece_number, type: Integer
  field :district_name, type: String
  field :subplaces, type: Array
  field :parish_number, type: Integer #was parnum really "parish"? maybe "part"?
  field :suffix, type: String
  field :lds_film_number, type: String
  field :freecen_filename, type: String
  field :entry_number, type: Integer
  belongs_to :freecen1_fixed_dat_file
  has_one :freecen_piece
end
