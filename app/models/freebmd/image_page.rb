class ImagePage < FreebmdDbBase
  self.pluralize_table_names = false
  self.table_name = 'ImagePage'
  has_many :image_files, foreign_key: 'ImageID', primary_key: 'ImageID', class_name: '::ImageFile'
end