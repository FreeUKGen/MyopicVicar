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
  belongs_to :register, index: true
  before_save :check_inclusion_of_rule

  module EmbargoRuleOptions
    ALL_OPTIONS = [
      'Embargoed until the end of ', 'Embargoed for the period of '
    ]
  end

  def check_inclusion_of_rule

  end
end
