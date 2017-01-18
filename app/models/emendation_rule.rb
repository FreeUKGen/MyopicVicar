class EmendationRule
  include Mongoid::Document
  include Mongoid::Timestamps
  field :original, type: String
  field :replacement, type: String  
  field :gender, type: String #m=male, f=female (nil if rule applies to both)
   index({ original: 1, replacement: 1}, { unique: true })
   index({emendation_type_id: 1})
  
  belongs_to :emendation_type

  class << self
    def all_original_by_replacement(replacement)
      originals = []
      EmendationRule.where(replacement:  replacement ).to_a.each do |emendation_rule_original|
        originals << emendation_rule_original.original
      end
      originals
    end
  end

end
