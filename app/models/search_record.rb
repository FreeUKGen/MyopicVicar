class SearchRecord
  include MongoMapper::Document
  SEARCHABLE_KEYS = [:first_name, :last_name]

  
  # For the moment, this will merely mirror the Bicker 18c template

  key :first_name, String, :required => false
  key :last_name, String, :required => false
  


end
