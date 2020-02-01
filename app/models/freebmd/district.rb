class District < FreebmdDbBase
  self.table_name = 'Districts'
  has_many :DistrictToCounty, foreign_key: :DistrictNumber
end