class DistrictPseudonym < FreebmdDbBase
  self.pluralize_table_names = true
  self.table_name = 'DistrictPseudonyms'
  belongs_to :District, foreign_key: :DistrictNumber
end