class Freecen1FixedDatFile
  include Mongoid::Document
  field :filename, type: String
  field :dirname, type: String
  field :year, type: String
  field :chapman_code, type: String
  field :file_digest, type: String
  has_many :freecen1_fixed_dat_entries
end
