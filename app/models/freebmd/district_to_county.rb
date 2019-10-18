class DistrictToCounty < ActiveRecord::Base
  establish_connection FREEBMD_DB
  self.pluralize_table_names = false
  self.table_name = 'DistrictToCounty'
  belongs_to :District, foreign_key: :DistrictNumber
end