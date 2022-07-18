class ScanLink < FreebmdDbBase
  self.pluralize_table_names = false
  self.table_name = 'ScanLink'
  belongs_to :BestGuess, foreign_key: 'ChunkNumber'
  #belongs_to :ScanList
  #test
end