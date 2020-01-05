class Gap
  include Mongoid::Document

  field :start_date, type: Integer
  validates :start_date, numericality: { only_integer: true }
  field :end_date, type: Integer
  validates :start_date, numericality: { only_integer: true }
  field :record_type, type: String
  validates_inclusion_of :record_type, in: RecordType::ALL_FREEREG_TYPES + ['All']
  field :reason, type: String
  field :freereg1_csv_file, type: String
  field :note, type: String

  belongs_to :register, index: true

  validate :start_and_end

  index({ freereg1_csv_file: 1 }, name: 'batch')

  class << self
    def batch(id)
      where(freereg1_csv_file: id)
    end

    def register(id)
      where(register: id)
    end
  end

  def start_and_end
    errors.add(:start_date, 'The start date must precede the end date') if start_date > end_date
  end

  def belongs_to_me?(user)
    belongs_to_me = false
    file = Freereg1CsvFile.find_by(_id: freereg1_csv_file)
    belongs_to_me = true if file.present? && file.userid_detail_id == user.id
    belongs_to_me
  end

  def belongs_to_my_county?(user)
    file = Freereg1CsvFile.find_by(_id: freereg1_csv_file)
    belongs_to_my_county = false
    my_counties = user.county_groups
    my_counties <<  user.county_groups if user.county_groups.present?
    belongs_to_my_county = true if file.present? && my_counties.present? && my_counties.include?(file.chapman_code)
    belongs_to_my_county
  end

  def belongs_to_my_syndicate?(user)
    belongs_to_my_syndicate = false
    my_syndicates = user.syndicate_groups
    belongs_to_my_syndicate = true if my_syndicates.present? && my_syndicates.include?(user.syndicate)
    belongs_to_my_syndicate
  end

  def can_be_deleted?(user)
    delete = false
    delete = true if record_type == 'All' && %w[county_coordinator country_coordinator data_manager system_administrator executive_director].include?(user.person_role)
    delete = true if belongs_to_me?(user)
    delete = true if belongs_to_my_syndicate?(user)
    delete = true if belongs_to_my_county?(user)
    delete = true if %w[data_manger system_administrator executive_director].include?(user.person_role)
    delete
  end

  def can_be_edited?(user)
    edit = false
    edit = true if record_type == 'All' && %w[county_coordinator country_coordinator data_manager system_administrator executive_director].include?(user.person_role)
    edit = true if belongs_to_me?(user)
    edit = true if belongs_to_my_syndicate?(user)
    edit = true if belongs_to_my_county?(user)
    edit = true if %w[data_manger system_administrator executive_director].include?(user.person_role)
    edit
  end
end
