class DistrictToCounty < FreebmdDbBase
  self.pluralize_table_names = false
  self.table_name = 'DistrictToCounty'
  belongs_to :District, foreign_key: :DistrictNumber
end