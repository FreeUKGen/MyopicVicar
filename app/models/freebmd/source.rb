class Source < FreebmdDbBase
  self.pluralize_table_names = false
  self.table_name = 'Source'
  has_many :ranges, primary_key: 'SourceID', foreign_key: 'SourceID', class_name: '::RangeDetail'
end