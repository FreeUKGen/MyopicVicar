class EmendationRule
  include Mongoid::Document
  include Mongoid::Timestamps
  field :source, type: String
  field :target, type: String  
  timestamps!
  
  belongs_to :emendation_type
end
