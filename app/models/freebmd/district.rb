class District < FreebmdDbBase
  self.table_name = 'Districts'
  has_many :DistrictToCounty, foreign_key: :DistrictNumber
  has_many :records, foreign_key: :DistrictNumber, class_name: '::BestGuess'
end