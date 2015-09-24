class FreecenPiece
  include Mongoid::Document
  field :chapman_code, type: String
  field :piece_number, type: String
  field :district_name, type: String
  field :subplaces, type: Array
  field :parish_number, type: String
  field :suffix, type: String
  belongs_to :freecen1_fixed_dat_entry
  belongs_to :place
  
  index(:piece_number => 1, :chapman_code => 1)
end
