# A collection of Annotations makes up a Transcription
class EmbargoRule
  include Mongoid::Document
  include Mongoid::Timestamps
  require 'record_type'
  field :authority, type: String
  validates :authority, presence: true
  field :period, type: Integer
  validates :period, numericality: { only_integer: true }
  field :period_type, type: String
  field :reason, type: String
  validates :reason, presence: true
  field :record_type, type: String
  validates :record_type, inclusion: { in: RecordType.all_types }
  field :rule, type: String
  field :member_who_created, type: String
  validates :member_who_created, presence: true
  belongs_to :register, index: true

  validate :only_one_rule_per_record_type, on: :create
  validate :valid_period


  after_create  :add_to_rake_register_embargo_list
  after_update  :add_to_rake_register_embargo_list
  before_destroy :add_to_rake_register_embargo_list

  module EmbargoRuleOptions
    ALL_OPTIONS = [
      'Embargoed until the beginning of ', 'Embargoed for the period of '
    ]
  end

  def add_period_type
    self.period_type = period <= 125 ? 'period' : 'end'
  end

  def only_one_rule_per_record_type
    errors.add(:rule, 'Need a rule selected') if rule.blank?
    if EmbargoRule.where(register_id: register_id, rule: rule, record_type: record_type).exists?
      errors.add(:rule, 'should only be one rule for a record type')
    end
  end

  def valid_period
    errors.add(:period, 'Period must entered') if period.blank?
    errors.add(:period, 'Period must be in the range of between 0 and 125') if period.present? && rule == 'Embargoed for the period of ' && period < 0
    errors.add(:period, 'Period must be in the range of between 0 and 125') if period.present? && rule == 'Embargoed for the period of ' && period > 125
    if period.present? && rule == 'Embargoed until the beginning of ' && (period < Date.current.year.to_i || period > Date.current.year.to_i + 25)
      date_future = Date.current.year.to_i + 25
      errors.add(:period, "A year between #{Date.current.year.to_i} and #{date_future}")
    end
  end

  def add_to_rake_register_embargo_list
    processing_file = Rails.root.join(Rails.application.config.register_embargo_list)
    File.open(processing_file, 'a') do |f|
      f.write("#{register_id},#{DateTime.now}\n")
    end
  end

  def process_embargo_records(email = nil)
    rake_lock_file = File.join(Rails.root, 'tmp', "#{self.id}_rake_lock_file.txt")
    if File.exist?(rake_lock_file)
      logger.warn("FREEREG:EMBARGO_PROCESSING: rake lock file #{rake_lock_file} already exists")
      return OpenStruct.new(success?: false, error: "The embargo records are being processed")
    else
      logger.warn("FREEREG:EMBARGO_PROCESSING: Starting embargo processing rake task for #{self.register} for record type #{self.record_type}")
      pid1 = spawn("rake foo:process_embargo_records[\"#{self.id}\",\"#{email}\"]")
      return OpenStruct.new(success?: true, message: "The embargo records are being processed. You will recieve an email when completed ")
    end
  end
end
