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
  validate :release_date
  embedded_in :freereg1_csv_entry

  def release_date
    p 'validation'
    p self
    errors.add(:release_date, ' must be in the future') if embargoed && (release_date <= DateTime.now.year)

  end
end
