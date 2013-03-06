class Register 
  include MongoMapper::EmbeddedDocument
  
  key :status, String
  key :register_type, String
  key :record_types, Array
  
  key :start_year, Integer
  key :end_year, Integer 
  key :transcribers, Array
  
  one :freereg1_csv_file
  
end
