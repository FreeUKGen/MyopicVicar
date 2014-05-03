class EmendationRule
  include Mongoid::Document
  include Mongoid::Timestamps
  field :original, type: String
  field :replacement, type: String  
   index({ original: 1, replacement: 1}, { unique: true })
  
  belongs_to :emendation_type
end
