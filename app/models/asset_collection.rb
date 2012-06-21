#
# TODO: Move Scribe-originated models into an engine or other usefully-separated format
#
# The collection of images forming a book
class AssetCollection
  include MongoMapper::Document
  key :title, String, :required => true
  key :author, String, :required => false
  key :extern_ref, String
  
  many :assets 
end