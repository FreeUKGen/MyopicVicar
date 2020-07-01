class CountyCombo < FreebmdDbBase
  self.pluralize_table_names = false
  self.table_name = 'CountyCombos'
  has_many :BestGuesses, primary_key: 'CountyComboID', foreign_key: 'CountyComboID'
end