class ScanList < FreebmdDbBase
  self.pluralize_table_names = false
  self.table_name = 'ScanList'
  #belongs_to :BestGuess, foreign_key: 'RecordNumber'
end