class Freecen2CivilParish
  include Mongoid::Document
  include Mongoid::Timestamps::Short
  require 'freecen_constants'

  field :chapman_code, type: String
  validates_inclusion_of :chapman_code, in: ChapmanCode.values
  field :year, type: String
  validates_inclusion_of :year, in: Freecen::CENSUS_YEARS_ARRAY
  field :name, type: String
  field :standard_name, type: String
  field :note, type: String
  field :prenote, type: String
  field :number, type: Integer
  validates :number, numericality: { only_integer: true }, allow_blank: true
  field :suffix, type: String
  field :reason_changed, type: String
  field :action, type: String

  field :vld_files, type: Array, default: []

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
  delegate :place_name, to: :freecen2_place, prefix: :place

  before_save :add_standard_names
  before_update :add_standard_names

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

    def civil_name(name)
      where(name: name)
    end

    def missing_places(chapman_code)
      Freecen2CivilParish.where(chapman_code: chapman_code, freecen2_place_id: nil).all.order_by(name: 1, year: 1)
    end

    def district_place_name(chapman_code)
      districts = Freecen2District.distinct("freecen2_place_id")
      district_names = Freecen2District.distinct("name")
      civil_parishes = []
      Freecen2CivilParish.where(chapman_code: chapman_code).all.order_by(name: 1, year: 1).each do |civil_piece|
        civil_parishes << civil_piece if civil_piece.freecen2_place_id.present? && districts.include?(civil_piece.freecen2_place_id) && !district_names.include?(civil_piece.name)
      end
      civil_parishes
    end

    def transform_civil_parish_params(params)
      return params if params.blank?
      place = Freecen2Place.find_by(chapman_code: params['chapman_code'], place_name: params['freecen2_place_id'])
      new_civil_parish_params = {}
      new_civil_parish_params[:chapman_code] = params['chapman_code']
      new_civil_parish_params[:year] = params['year']
      new_civil_parish_params[:reason_changed] = params['reason_changed']
      new_civil_parish_params[:freecen2_piece_id] = params['freecen2_piece_id']
      new_civil_parish_params[:name] = params['name'].strip if params['name'].present?
      new_civil_parish_params[:number] = params['number']
      new_civil_parish_params[:suffix] = params['suffix']
      new_civil_parish_params[:note] = params['note']
      new_civil_parish_params[:prenote] = params['prenote']
      new_civil_parish_params[:freecen2_place_id] = Freecen2Place.place_id(params['chapman_code'], params[:freecen2_place_id])
      new_civil_parish_params
    end

    def add_hamlet(params)
      hamlet = params[:freecen2_civil_parish][:freecen2_hamlets_attributes]['0']
      return nil if hamlet['name'].blank?

      hamlet_name = hamlet['name']
      hamlet_note = hamlet['note']
      hamlet_prenote = hamlet['prenote']
      hamlet_object = Freecen2Hamlet.new(name: hamlet_name, note: hamlet_note, prenote: hamlet_prenote)
      hamlet_object
    end

    def add_township(params)
      township = params[:freecen2_civil_parish][:freecen2_townships_attributes]['0']
      return nil if township['name'].blank?

      township_name = township['name']
      township_note = township['note']
      township_prenote = township['prenote']
      township_object = Freecen2Township.new(name: township_name, note: township_note, prenote: township_prenote)
      township_object
    end

    def add_ward(params)
      ward = params[:freecen2_civil_parish][:freecen2_wards_attributes]['0']
      return nil if ward['name'].blank?

      ward_name = ward['name']
      ward_note = ward['note']
      ward_prenote = ward['prenote']
      ward_object = Freecen2Ward.new(name: ward_name, note: ward_note, prenote: ward_prenote)
      ward_object
    end

    def create_csv_file(chapman_code, year, civil_parishes)
      file = "#{chapman_code}_#{year}_Civil_Parish_Index.csv"
      file_location = Rails.root.join('tmp', file)
      success, message = Freecen2CivilParish.write_csv_file(file_location, year, chapman_code, civil_parishes)

      [success, message, file_location, file]
    end

    def write_csv_file(file_location, year, chapman_code, civil_parishes)
      header = year == 'all' ? Freecen2CivilParish.all_year_header(chapman_code) : Freecen2CivilParish.year_header(chapman_code, year)

      CSV.open(file_location, 'wb', { row_sep: "\r\n" }) do |csv|
        csv << header
        record_number = 0
        civil_parishes.each do |rec|
          next if rec.blank?

          record_number += 1
          line = []
          line = year == 'all' ? Freecen2CivilParish.add_all_year_fields(line, record_number, chapman_code, rec) : Freecen2CivilParish.add_year_fields(line, record_number, chapman_code, rec)
          csv << line
        end
      end
      [true, '']
    end

    def year_header(chapman_code, year)
      header = []
      header << 'Rec Number'
      header << "Civil Parish name in #{chapman_code} for #{year}"
      header << 'Piece Number'
      header << 'District Name'
      header << 'Linked to Place'
      header << 'Action Required'
      header
    end

    def all_year_header(chapman_code)
      header = []
      header << 'Rec Number'
      header << "Civil Parish name in #{chapman_code}"
      Freecen::CENSUS_YEARS_ARRAY.each do |census|
        header << "#{census}"
      end
      header << 'Action Required'
      header
    end

    def add_year_fields(line, number, chapman_code, rec)
      line << number.to_i
      line << rec.name
      line << rec.piece_number
      district = rec.freecen2_piece.freecen2_district
      line << district.name
      place = rec.freecen2_place.present? ? rec.place_place_name : ''
      line << place
      line
    end

    def add_all_year_fields(line, number, chapman_code, rec)
      line << number.to_i
      line << rec
      Freecen::CENSUS_YEARS_ARRAY.each do |census|
        freecen2_piece = Freecen2CivilParish.where(chapman_code: chapman_code, name: rec, year: census).exists?
        entry = freecen2_piece ? 'Yes' : ''
        line << entry
      end
      line
    end

  end

  # :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::Instance methods :::::::::::::::::::::::::::::::::::::::

  def add_standard_names
    self.standard_name = Freecen2Place.standard_place(name) unless self.standard_name.nil?
  end

  def check_new_name(new_name)
    result = Freecen2CivilParish.find_by(chapman_code: chapman_code, year: year, freecen2_piece_id: freecen2_piece_id, name: new_name).present? ? false : true
    result
  end

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
    civil_parishes = Freecen2CivilParish.where(chapman_code: chapman_code, year: year, freecen2_piece_id: freecen2_piece_id).all.order_by(name: 1)
    @civil_parishes = []
    civil_parishes.each do |civil_parish|
      @civil_parishes << civil_parish.name
    end
    @civil_parishes = @civil_parishes.uniq.sort
  end

  def do_we_update_place?(file)
    if freecen2_place.present?
      files = []
      FreecenCsvFile.where(chapman_code: chapman_code, year: year, incorporated: true).all.each do |my_file|
        files << my_file if my_file.enumeration_districts.keys.include?(name)
      end
      result = files.count.zero? ? true : false
    else
      result = false
    end
    result
  end

  def update_place(file)
    message = 'success'
    return [true, message] unless do_we_update_place?(file)

    place = freecen2_place
    place.cen_data_years.delete_if { |value| value == year }
    place.data_present = false
    success = place.save
    message = 'Failed to update place' unless success
    [success, message]
  end

  def propagate(old_civil_parish_id, old_civil_parish_name, old_place, merge_civil_parish)
    new_place = freecen2_place_id
    update_attribute(:_id, merge_civil_parish.id) if merge_civil_parish.present? && merge_civil_parish.id != old_civil_parish_id
    old_civil_parish = Freecen2CivilParish.find_by(_id: old_civil_parish_id)

    Freecen2CivilParish.where(chapman_code: chapman_code, freecen2_piece_id: old_civil_parish.freecen2_piece_id, name: old_civil_parish_name, year: year).each do |civil_parish|
      old_civil_parish_place = civil_parish.freecen2_place_id
      civil_parish.update_attributes(freecen2_place_id: new_place) if old_civil_parish_place.blank? || old_civil_parish_place.to_s == old_place.to_s
      civil_parish.update_attributes(name: name)
    end
    old_civil_parish.destroy if merge_civil_parish.present? && merge_civil_parish.id != old_civil_parish_id
  end
end
