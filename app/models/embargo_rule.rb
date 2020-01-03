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

  validate :valid_period
  validate :only_one_rule_per_record_type, on: :create

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
    if EmbargoRule.where(register_id: register_id, rule: rule, record_type: record_type).exists?
      errors.add(:rule, 'should only be one rule for a record type')
    end
  end

  def valid_period
    if rule == 'Embargoed for the period of '
      unless period.blank? || period >= 0 && period <= 125
        errors.add(:period, 'Period must be in the range of between 0 and 125')
      end
    else
      unless period >= Date.current.year.to_i && period < Date.current.year.to_i + 25
        date_future = Date.current.year.to_i + 25
        errors.add(:period, "A year between #{Date.current.year.to_i} and #{date_future}")
      end
    end
  end

  def add_to_rake_register_embargo_list
    processing_file = Rails.root.join(Rails.application.config.register_embargo_list)
    File.open(processing_file, 'a') do |f|
      f.write("#{register_id},#{DateTime.now}\n")
    end
  end
end
