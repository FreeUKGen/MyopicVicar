class District < ActiveRecord::Base
  establish_connection FREEBMD_DB
  self.table_name = 'Districts'
  has_many :DistrictToCounty, foreign_key: :DistrictNumber
end