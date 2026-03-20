class EmbargoRecord
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  field :embargoed, type: Boolean, default: false
  field :who, type: String
  validates :who, presence: true
  field :why, type: String
  validates :why, presence: true
  field :when, type: DateTime
  field :rule_applied, type: String
  field :rule_date, type: String
  field :release_year, type: Integer # This is the computed release year
  field :release_date, type: Integer # This is the manual entry of a release year
  validate :release
  embedded_in :freereg1_csv_entry

  def self.process_embargo_year(rule, year)
    end_year = DateTime.now.year.to_i
    case rule.period_type
    when 'end'
      end_year = rule.period.to_i
    when 'period'
      end_year = rule.period.to_i + year.to_i if year.present?
    end
    end_year
  end

  def already_applied?(rule)
    result = false
    result = true if rule_date.present? && rule_date.to_s == rule.updated_at.utc.to_s
    result
  end

  def release
    return if release_date.blank?
    # When release_date has passed, existing records are effectively released - allow updates
    # (e.g. removing birth date from 1925 records now visible in 2026). Only enforce "must be
    # in the future" when creating a NEW embargo record.
    return if DateTime.now.year.to_i > release_date.to_i && !new_record?
    errors.add(:release_date, ' must be in the future') if embargoed == true && (DateTime.now.year.to_i > release_date.to_i)
  end
end
