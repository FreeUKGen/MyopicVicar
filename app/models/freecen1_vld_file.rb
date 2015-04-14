class Freecen1VldFile
  include Mongoid::Document
  field :file_name, type: String
  field :dir_name, type: String
  field :census_type, type: String
  field :raw_year, type: String
  field :full_year, type: String
  field :piece, type: String
  field :series, type: String
end
