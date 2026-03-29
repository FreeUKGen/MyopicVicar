class EmendationRule
  include Mongoid::Document
  include Mongoid::Timestamps

  field :original, type: String
  field :replacement, type: String
  field :gender, type: String #m=male, f=female (nil if rule applies to both)
  
  index({ original: 1, replacement: 1}, { unique: true })
  index({emendation_type_id: 1})

  belongs_to :emendation_type, index: true

  class << self
    def all_original_by_replacement(req_replacement)
      # Instead of pulling the whole document and iterating through array,
      # we pluck the specific field we want directly at the DB level.
      EmendationRule.where(replacement: req_replacement).pluck(:original)
    end

    def sort_by_initial_letter(replacement_array)
      hash_letter = Hash.new { |hash, key| hash[key] = [] }
      replacement_array.each do |replacement|
        hash_letter[replacement[0]].push(replacement)
      end
      hash_letter.sort.to_h
    end

  end

end
