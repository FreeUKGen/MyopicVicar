class Freecen2District
  include Mongoid::Document
  include Mongoid::Timestamps::Short

  field :chapman_code, type: String
  validates_inclusion_of :chapman_code, in: ChapmanCode.values
  field :year, type: String
  validates_inclusion_of :year, in: Freecen::CENSUS_YEARS_ARRAY
  field :name, type: String
  validates :name, presence: true
  field :standard_name, type: String
  field :tnaid, type: String
  validates :tnaid, presence: true
  field :type, type: String
  field :code, type: String
  field :notes, type: String
  field :reason_changed, type: String
  field :action, type: String

  field :vld_files, type: Array, default: []

  has_many :freecen2_pieces, dependent: :restrict_with_error
  has_many :freecen_csv_files, dependent: :restrict_with_error
  has_many :freecen1_vld_files, dependent: :restrict_with_error
  belongs_to :freecen2_place, optional: true, index: true
  belongs_to :county, optional: true, index: true
  delegate :county, to: :county, prefix: true, allow_nil: true
  delegate :place_name, to: :freecen2_place, prefix: :place
  before_save :add_standard_names
  before_update :add_standard_names

  index({ chapman_code: 1, year: 1, name: 1 }, name: 'chapman_code_year_name')
  index({ chapman_code: 1, name: 1, year: 1 }, name: 'chapman_code_name_year')
  index({ chapman_code: 1, name: 1 }, name: 'chapman_code_name')
  index({ name: 1 }, name: 'chapman_code_name')

  class << self
    def chapman_code(chapman)
      where(chapman_code: chapman)
    end

    def year(year)
      where(year: year)
    end

    def status(status)
      where(status: status)
    end

    def county_year_totals(chapman_code)
      totals_pieces = {}
      totals_individuals = {}
      totals_dwellings = {}
      totals_csv_files = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        totals_pieces[year] = 0
        totals_dwellings[year] = 0
        totals_individuals[year] = 0
        totals_csv_files[year] = 0
        Freecen2District.chapman_code(chapman_code).year(year).each do |district|
          totals_pieces[year] = totals_pieces[year] + district.freecen2_pieces.count
          district.freecen2_pieces.each do |piece|
            totals_dwellings[year] = totals_dwellings[year] + piece.freecen_dwellings.count
            totals_csv_files[year] = totals_csv_files[year] + piece.freecen_csv_files.count
            totals_individuals[year] = totals_individuals[year] + piece.num_individuals
          end
        end
      end
      [totals_pieces, totals_csv_files, totals_individuals, totals_dwellings]
    end

    def grand_totals(pieces, files, individuals, dwellings)
      grand_pieces = pieces.values.sum
      grand_files = files.values.sum
      grand_individuals = individuals.values.sum
      grand_dwellings = dwellings.values.sum
      [grand_pieces, grand_files, grand_individuals, grand_dwellings]
    end

    def grand_year_totals
      totals_pieces = {}
      totals_pieces_online = {}
      totals_individuals = {}
      totals_dwellings = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        totals_dwellings[year] = 0
        totals_individuals[year] = Freecen2Piece.status('Online').year(year).sum(:num_individuals)
        totals_pieces[year] = Freecen2iece2.year(year).count
        totals_pieces_online[year] = Freecen2Piece.status('Online').year(year).length
        Freecen2Piece.status('Online').year(year).each do |piece|
          totals_dwellings[year] = totals_dwellings[year] + piece.freecen_dwellings.count
        end
      end
      [totals_pieces, totals_pieces_online, totals_individuals, totals_dwellings]
    end

    def missing_places(chapman_code)
      Freecen2District.where(chapman_code: chapman_code, freecen2_place_id: nil).all.order_by(name: 1, year: 1)
    end

    def create_csv_file(chapman_code, year, districts)
      file = "#{chapman_code}_#{year}_District_Index.csv"
      file_location = Rails.root.join('tmp', file)
      success, message = Freecen2District.write_csv_file(file_location, year, chapman_code, districts)

      [success, message, file_location, file]
    end

    def write_csv_file(file_location, year, chapman_code, districts)
      header = year == 'all' ? Freecen2District.all_year_header(chapman_code) : Freecen2District.year_header(chapman_code, year)

      CSV.open(file_location, 'wb', { row_sep: "\r\n" }) do |csv|
        csv << header
        record_number = 0
        districts.each do |rec|
          next if rec.blank?

          record_number += 1
          line = []
          line = year == 'all' ? Freecen2District.add_all_year_fields(line, record_number, chapman_code, rec) : Freecen2District.add_year_fields(line, record_number, chapman_code, rec)
          csv << line
        end
      end
      [true, '']
    end

    def year_header(chapman_code, year)
      header = []
      header << 'Rec Number'
      header << "District Name in #{chapman_code} for #{year}"
      header << 'District Type' if year == '1841'
      header << 'Linked to Place'
      header << 'Action Required'
      header
    end

    def add_year_fields(line, number, chapman_code, rec)
      line << number.to_i
      line << rec.name
      type = rec.type.blank? ? 'Registration District' : rec.type
      line << type  if rec.year == '1841'
      place = rec.freecen2_place.present? ? rec.place_place_name : ''
      line << place
      line
    end

    def all_year_header(chapman_code)
      header = []
      header << 'Rec Number'
      header << "District Name in #{chapman_code}"
      Freecen::CENSUS_YEARS_ARRAY.each do |census|
        header << "#{census}"
      end
      header << 'Action Required'
      header
    end

    def add_all_year_fields(line, number, chapman_code, rec)
      line << number.to_i
      line << rec
      Freecen::CENSUS_YEARS_ARRAY.each do |census|
        freecen2_district = Freecen2District.where(chapman_code: chapman_code, name: rec, year: census).exists?
        entry = freecen2_district ? 'Yes' : ''
        line << entry
      end
      line
    end

  end

  # ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Instance methods::::::::::::::::::::::::::::::::::::::::::::::::::::::
  def add_standard_names
    self.standard_name = Freecen2Place.standard_place(name)
  end

  def check_new_name(new_name)
    result = Freecen2District.find_by(chapman_code: chapman_code, year: year, name: new_name).present? ? false : true
    result
  end

  def copy_to_another_county(chapman_code)
    county = County.find_by(chapman_code: chapman_code)
    new_district = Freecen2District.new(chapman_code: chapman_code, year: year, name: name, tnaid: tnaid, type: type, notes: notes, county_id: county.id)
    freecen2_pieces.each do |piece|
      successa, new_piece = piece.copy_to_another_district(chapman_code, new_district.id)
      if successa
        piece.freecen2_civil_parishes.each do |civil_parish|
          successa, new_civil_parish = civil_parish.copy_to_another_piece(chapman_code, new_piece.id)
        end
      end
    end
    success = new_district.save
    [success, new_district]
  end

  def district_names
    districts = Freecen2District.where(chapman_code: chapman_code, year: year).all.order_by(name: 1)
    @districts = []
    districts.each do |district|
      @districts << district.name
    end
    @districts = @districts.uniq.sort
  end

  def district_place_names
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

  def district_place_id(place_name)
    standard_place_name = Freecen2Place.standard_place(place_name)
    place = Freecen2Place.find_by(chapman_code: chapman_code, standard_place_name: standard_place_name) if chapman_code.present?
    if place.present?
      return place.id
    else
      place = Freecen2Place.find_by("alternate_freecen2_place_names.standard_alternate_name" => standard_place_name)
      if place.present?
        return place.id
      end
      ''
    end
  end

  def get_counties
    @counties = []
    counties = County.application_counties
    counties.each do |county|
      @counties << county.chapman_code
    end
    @counties
  end

  def propagate(old_district_id, old_district_name, old_place, merge_district)
    new_place = freecen2_place_id
    freecen2_pieces.each do |piece|
      piece.update_attribute(:freecen2_district_id, merge_district.id) if merge_district.present? && merge_district.id != old_district_id
    end
    old_district = Freecen2District.find_by(_id: old_district_id)
    old_district.destroy if merge_district.present? && merge_district.id != old_district.id

    Freecen2District.where(chapman_code: chapman_code, year: year, name: old_district_name).each do |district|
      old_place_name = district.freecen2_place_id
      district.update_attributes(freecen2_place_id: new_place, name: name)
      district.freecen2_pieces.each do |piece|
        old_piece_place = piece.freecen2_place_id
        piece.update_attribute(:freecen2_district_id, merge_district.id) if merge_district.present? && merge_district.id != old_district_id
        piece.update_attributes(freecen2_place_id: new_place) if old_piece_place.blank? || old_piece_place.to_s == old_place.to_s
        piece.freecen2_civil_parishes.each do |civil_parish|
          old_civil_parish_place = civil_parish.freecen2_place_id
          civil_parish.update_attributes(freecen2_place_id: new_place) if old_civil_parish_place.blank? || old_civil_parish_place.to_s == old_place.to_s
        end
      end
    end
  end

  def freecen2_pieces_name
    freecen2_pieces = Freecen2Piece.where(freecen2_district_id: _id).all.order_by(name: 1)
    freecen2_pieces_name = []
    freecen2_pieces.each do |piece|
      freecen2_pieces_name << piece.name unless freecen2_pieces_name.include?(piece.name)
    end
    freecen2_pieces_name
  end

  def update_freecen2_place
    result, place_id = Freecen2Place.valid_place(chapman_code, name)
    update_attributes(freecen2_place_id: place_id) if result
  end

  def update_tna_change_log(userid)
    previous_changes
    tna = TnaChangeLog.create(userid: userid, year: year, chapman_code: chapman_code, parameters: previous_changes, tna_collection: "#{self.class}")
    tna.save
  end
end
