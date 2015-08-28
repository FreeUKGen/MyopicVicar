class Freecen1VldFile
  include Mongoid::Document
  has_many :freecen1_vld_entries
  has_many :freecen_dwellings
  
  field :file_name, type: String
  field :dir_name, type: String
  field :census_type, type: String
  field :raw_year, type: String
  field :full_year, type: String
  field :piece, type: String
  field :series, type: String
end
