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
  field :release_year, type: Integer
  validates :release_year, presence: true
  validates :release_year, numericality: { only_integer: true }
  validate :release_date

  embedded_in :freereg1_csv_entry

  def release_date
    errors.add(:release_year, ' must be in the future') if release_year <= DateTime.now.year
  end
end
