# A collection of Annotations makes up a Transcription
class EmbargoRule
  include Mongoid::Document
  include Mongoid::Timestamps

  field :rule, type: String
  field :record_type, type: String
  validates_inclusion_of :record_type, in: RecordType::ALL_FREEREG_TYPES + [nil]
  field :period, type: Integer
  validates :period, numericality: { only_integer: true }
  field :authority, type: String
  validates :authority, presence: true
  belongs_to :register, index: true
  validate :only_one_rule_per_record_type


  module EmbargoRuleOptions
    ALL_OPTIONS = [
      'Embargoed until the end of ', 'Embargoed for the period of '
    ]
  end

  def only_one_rule_per_record_type
    if EmbargoRule.where(register_id: register_id, rule: rule, record_type: record_type).exists?
      errors.add(:rule, "should only be one rule for a record type" )
    end
    unless (period >= 1 && period < 125) || (period > Date.current.year.to_i && period < Date.current.year.to_i + 25)
      errors.add(:period, "Period must be in the range of between 1 and 125, Or a year between now and 25 years in the future")
    end
  end

end
