class ImageFile < FreebmdDbBase
  self.pluralize_table_names = false
  self.table_name = 'ImageFile'
  #belongs_to :BestGuess, foreign_key: 'RecordNumber'
  belongs_to :range, foreign_key: 'RangeID', primary_key: 'RangeID', class_name: '::RangeDetail'
  has_many :image_pages, foreign_key: 'ImageID', primary_key: 'ImageID', class_name: '::ImagePage'
end