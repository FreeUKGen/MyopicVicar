class SearchName 
  include MongoMapper::EmbeddedDocument
  key :first_name, String
  key :last_name, String
  key  :origin, String
  key  :role, String
end
