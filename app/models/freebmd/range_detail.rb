class RangeDetail < FreebmdDbBase
  self.pluralize_table_names = false
  self.table_name = 'Range'
  #has_many :ranges, primary_key: 'SourceID', foreign_key: 'SourceID'
  belongs_to :source, foreign_key: 'SourceID', primary_key: 'SourceID', class_name: '::Source'
  has_many :image_files, foreign_key: 'RangeID', primary_key: 'RangeID', class_name: '::ImageFile'
end