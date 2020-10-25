class Freecen2CivilParish
  include Mongoid::Document
  include Mongoid::Timestamps::Short
  require 'freecen_constants'

  field :chapman_code, type: String
  validates_inclusion_of :chapman_code, in: ChapmanCode.values
  field :year, type: String
  validates_inclusion_of :year, in: Freecen::CENSUS_YEARS_ARRAY
  field :name, type: String
  field :note, type: String
  field :prenote, type: String
  field :number, type: Integer
  validates :number, numericality: { only_integer: true }, allow_blank: true
  field :suffix, type: String
  field :reason_changed, type: String
  field :action, type: String

  belongs_to :freecen2_piece, optional: true, index: true
  belongs_to :freecen2_place, optional: true, index: true
  has_many :freecen_csv_entries

  embeds_many :freecen2_hamlets
  embeds_many :freecen2_townships
  embeds_many :freecen2_wards
  accepts_nested_attributes_for :freecen2_hamlets, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :freecen2_townships, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :freecen2_wards, allow_destroy: true, reject_if: :all_blank

  delegate :year, :name, :tnaid, :number, :code, :note, to: :freecen2_piece, prefix: :piece, allow_nil: true

  index({ chapman_code: 1, year: 1, name: 1 }, name: 'chapman_code_year_name')
  index({ chapman_code: 1, name: 1 }, name: 'chapman_code_name')
  index({ name: 1 }, name: 'chapman_code_name')
  class << self
    def chapman_code(chapman)
      where(chapman_code: chapman)
    end

    def year(year)
      where(year: year)
    end

    def missing_places(chapman_code)
      Freecen2CivilParish.where(chapman_code: chapman_code, freecen2_place_id: nil).all.order_by(name: 1, year: 1)
    end

    def district_place_name(chapman_code)
      civil_parishes = []
      Freecen2CivilParish.where(chapman_code: chapman_code).all.order_by(name: 1, year: 1).each do |civil_piece|
        civil_parishes << civil_piece if civil_piece.freecen2_place_id.present? && (civil_piece.freecen2_place_id.to_s == civil_piece.freecen2_piece.freecen2_district.freecen2_place_id.to_s) &&
          (civil_piece.name != civil_piece.freecen2_piece.freecen2_district.name)
      end
      civil_parishes
    end

  end

  # :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::Instance methods :::::::::::::::::::::::::::::::::::::::

  def copy_to_another_piece(chapman_code, new_piece_id)
    new_civil_parish = Freecen2CivilParish.new(name: name, chapman_code: chapman_code, year: year, note: note, prenote: prenote, number: number,
                                               suffix: suffix, freecen2_piece_id: new_piece_id)
    freecen2_hamlets.each do |hamlet|
      hamlet_object = Freecen2Hamlet.new(name: hamlet.name, note: hamlet.note, prenote: hamlet.prenote)
      new_civil_parish.freecen2_hamlets << hamlet_object
    end
    freecen2_townships.each do |township|
      township_object = Freecen2Township.new(name: township.name, note: township.note, prenote: township.prenote)
      new_civil_parish.freecen2_townships << township_object
    end
    freecen2_wards.each do |ward|
      ward_object = Freecen2Ward.new(name: ward.name, note: ward.note, prenote: ward.prenote)
      new_civil_parish.freecen2_wards << ward_object
    end
    success = new_civil_parish.save
    [success, new_civil_parish]
  end

  def add_hamlet_township_names
    @hamlet_names = ''
    freecen2_hamlets.order_by(name: 1).each do |hamlet|
      @hamlet_names = @hamlet_names.empty? ? hamlet.name : @hamlet_names + ';' + hamlet.name
    end
    freecen2_townships.order_by(name: 1).each do |township|
      @hamlet_names = @hamlet_names.empty? ? township.name : @hamlet_names + ';' + township.name
    end
    freecen2_wards.order_by(name: 1).each do |ward|
      @hamlet_names = @hamlet_names.empty? ? ward.name : @hamlet_names + ';' + ward.name
    end
    @hamlet_names = '(' + @hamlet_names + ')' unless @hamlet_names.empty?
    @hamlet_names
  end

  def update_freecen2_place
    result, place_id = Freecen2Place.valid_place(chapman_code, name)
    update_attributes(freecen2_place_id: place_id) if result
  end

  def update_tna_change_log(userid)
    tna = TnaChangeLog.create(userid: userid, year: year, chapman_code: chapman_code, parameters: previous_changes, tna_collection: "#{self.class}")
    tna.save
  end

  def civil_parish_names
    civil_parishes = Freecen2CivilParish.chapman_code(chapman_code).all.order_by(name: 1)
    @civil_parishes = []
    civil_parishes.each do |civil_parish|
      @civil_parishes << civil_parish.name
    end
    @civil_parishes = @civil_parishes.uniq.sort
  end

  def civil_parish_place_names
    places = Freecen2Place.chapman_code(chapman_code).all.order_by(place_name: 1)
    @places = []
    places.each do |place|
      @places << place.place_name
      place.alternate_freecen2_place_names.each do |alternate_name|
        @places << alternate_name.alternate_name
      end
    end
    @places = @places.uniq.sort
  end

  def civil_parish_place_id(place_name)
    place = Freecen2Place.find_by(chapman_code: chapman_code, place_name: place_name) if chapman_code.present?
    place = place.present? ? place.id : ''
  end

  def propagate_freecen2_place(old_place, old_name)
    new_place = freecen2_place_id
    new_name = name
    return if (new_place.to_s == old_place.to_s) && (new_name == old_name)

    Freecen2CivilParish.where(chapman_code: chapman_code, name: old_name).each do |civil_parish|
      old_civil_parish_place = civil_parish.freecen2_place_id
      civil_parish.update_attributes(name: new_name) if civil_parish.id != _id
      civil_parish.update_attributes(freecen2_place_id: new_place) if old_civil_parish_place.blank? || old_civil_parish_place.to_s == old_place.to_s
    end

    Freecen2CivilParish.where(chapman_code: chapman_code, name: name).each do |civil_parish|
      old_civil_parish_place = civil_parish.freecen2_place_id
      civil_parish.update_attributes(freecen2_place_id: new_place) if old_civil_parish_place.blank? || old_civil_parish_place.to_s == old_place.to_s
    end
  end
end
