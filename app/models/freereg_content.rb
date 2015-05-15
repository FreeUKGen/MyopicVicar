class FreeregContent
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short

  require 'chapman_code'
  field :county, type: String#, :required => false
  field :chapman_codes,  type: Array, default: []
  validates_inclusion_of :county, :in => ChapmanCode::values+[nil]
  field :place, type: String
  field :church, type: String
  field :record_type, type: String#, :required => false
  field :place_ids, type: String
  validates_inclusion_of :record_type, :in => RecordType::ALL_TYPES+[nil]
  validate :place_ids_is_valid
  validate :county_is_valid

  before_validation :clean_blanks

  def search
    Place.where(search_params).order_by(:place_name.asc).all

  end
  def search_params
    params = Hash.new
    params[:chapman_code] = county if county
    params
  end
  def get_alternate_place_names
    @names = Array.new
    @alternate_place_names = self.alternateplacenames.all
    @alternate_place_names.each do |acn|
      name = acn.alternate_name
      @names << name
    end
    @names
  end

  def county_is_valid
    if self.chapman_codes[0].nil?
      errors.add(:chapman_codes, "At least one county must be selected.")
    end
  end

  def place_ids_is_valid
    if self.place_ids.nil? 
      errors.add(:place_ids, "At least one place must be selected. If there are none then there are no places transcribed")
    end
  end
  def clean_blanks
    chapman_codes.delete_if { |x| x.blank? }
  end
end
