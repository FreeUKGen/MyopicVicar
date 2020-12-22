class ComponentFile < FreebmdDbBase
  self.pluralize_table_names = false
  self.table_name = 'ComponentFile'
  #belongs_to :BestGuess, foreign_key: 'RecordNumber'
  belongs_to :image_file, foreign_key: 'ImageID', primary_key: 'ImageID', class_name: '::ImageFile'
end