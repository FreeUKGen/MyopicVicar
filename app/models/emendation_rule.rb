class EmendationRule
  include Mongoid::Document
  include Mongoid::Timestamps
  field :original, type: String
  field :replacement, type: String  
   index({ original: 1, replacement: 1}, { unique: true })
   index({emendation_type_id: 1})
  
  belongs_to :emendation_type
end
