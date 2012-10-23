class SearchQuery
  require 'chapman_code'
  # consider extracting this from entities
  RECORD_TYPES = ['Baptism', 'Marriage', 'Death']
  ROLES = ['Father', 'Mother', 'Son', 'Daughter', 'Groom', 'Bride']
  
  include MongoMapper::Document
  key :first_name, String, :required => false
  key :last_name, String, :required => false
  key :fuzzy, Boolean
  key :role, String, :required => false, :in => ROLES+[nil] # I'm not sure why in and required=>false seem incompatible; the +[nil] is a work-around
  key :record_type, String, :required => false, :in => RECORD_TYPES+[nil]
  key :chapman_code, String, :required => false, :in => ChapmanCode::values+[nil]
#  key :extern_ref, String
  key :inclusive, Boolean

#  key :has_thumbnails, Boolean, :default => false
  
#  many :assets 
  
end
