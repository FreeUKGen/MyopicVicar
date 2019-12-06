# A collection of Annotations makes up a Transcription
class EmbargoRule
  include Mongoid::Document
  include Mongoid::Timestamps
  field :authority, type: String
  validates :authority, presence: true
  field :period, type: Integer
  validates :period, numericality: { only_integer: true }
  field :period_type, type: String
  field :reason, type: String
  validates :reason, presence: true
  field :record_type, type: String
  validates_inclusion_of :record_type, in: RecordType::ALL_FREEREG_TYPES + [nil]
  field :rule, type: String
  belongs_to :register, index: true
  validate :only_one_rule_per_record_type

  before_save :add_period_type
  after_save :add_to_rake_register_embargo_list
  before_destroy :add_to_rake_register_embargo_list

  module EmbargoRuleOptions
    ALL_OPTIONS = [
      'Embargoed until the end of ', 'Embargoed for the period of '
    ]
  end

  def add_period_type
    self.period_type = period < 125 ? 'period' : 'end'
  end

  def only_one_rule_per_record_type
    if EmbargoRule.where(register_id: register_id, rule: rule, record_type: record_type).exists?
      errors.add(:rule, 'should only be one rule for a record type')
    end
    unless (period >= 1 && period < 125) || (period > Date.current.year.to_i && period < Date.current.year.to_i + 25)
      errors.add(:period, 'Period must be in the range of between 1 and 125, Or a year between now and 25 years in the future')
    end
  end

  def add_to_rake_register_embargo_list
    processing_file = Rails.application.config.register_embargo_list
    File.open(processing_file, 'a') do |f|
      f.write("#{register_id},#{DateTime.now}\n")
    end
  end

end
