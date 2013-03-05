class Church 
  include MongoMapper::EmbeddedDocument
  
  key :church_name
  many :registers
end
