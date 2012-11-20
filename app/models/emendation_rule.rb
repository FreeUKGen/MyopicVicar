class EmendationRule
  include MongoMapper::Document
  key :source, String
  key :target, String  
  timestamps!
  
  belongs_to :emendation_type
end
