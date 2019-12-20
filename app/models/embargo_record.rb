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

  def release
    errors.add(:release_date, ' must be in the future') if embargoed == true && (DateTime.now.year.to_i > release_date.to_i)
  end
end
