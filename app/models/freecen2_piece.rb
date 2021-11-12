class Freecen2Piece
  include Mongoid::Document
  include Mongoid::Timestamps::Short
  require 'freecen_constants'
  # 1841       HO107 plus 3 digits for the piece number
  #              HS4 plus 5 digits; 3 for the piece number and the 2 (most significant digits) for the Parish number

  # 1851       HO107 plus 4 digits for the piece number. So this year starts at 1000. It is uploaded to FreeCEN as HO51 to comply with the old 8 digit filename standard.
  #              HS5 plus 5 digits; 3 for the piece number and the 2 (most significant digits) for the Parish number

  # 1861       RG9 or RG09 plus 4 digits for the piece number
  #               RS6 plus 5 digits  3 for the piece number and the 2 (most significant digits) for the Parish number

  # 1871       RG10 plus 4 digits
  #                RS7 plus 5 digits  3 for the piece number and the 2 (most significant digits) for the Parish number

  # 1881       RG11 plus 4 digits
  #                RS8 plus 5 digits  3 for the piece number and the 2 (most significant digits) for the Parish number

  # 1891       RG12 plus 4 digits
  #              There are none for Scotland but I would anticipate RS9

  #1901       RG13 plus 4 digits

  #1911       RG14 plus 4 digits


  field :name, type: String
  validates :name, presence: true
  field :standard_name, type: String
  field :chapman_code, type: String
  validates_inclusion_of :chapman_code, in: ChapmanCode.values
  field :tnaid, type: String
  field :number, type: String
  validates :number, presence: true
  field :year, type: String
  validates_inclusion_of :year, in: Freecen::CENSUS_YEARS_ARRAY
  field :code, type: String
  field :notes, type: String
  field :prenote, type: String
  field :civil_parish_names, type: String
  field :reason_changed, type: String
  field :action, type: String

  field :parish_number, type: String
  field :film_number, type: String
  field :suffix, type: String
  field :piece_number, type: Integer

  field :status, type: String
  field :remarks, type: String
  field :remarks_coord, type: String # visible to coords, not public
  field :online_time, type: Integer
  field :num_individuals, type: Integer, default: 0
  field :num_dwellings, type: Integer, default: 0
  field :status_date, type: DateTime

  field :vld_files, type: Array, default: []

  belongs_to :freecen2_district, optional: true, index: true
  belongs_to :freecen2_place, optional: true, index: true

  delegate :name, :tnaid, :code, :note, to: :freecen2_district, prefix: :district, allow_nil: true
  delegate :place_name, to: :freecen2_place, prefix: :place

  has_one :freecen_piece, dependent: :restrict_with_error, autosave: true
  has_many :freecen2_civil_parishes, dependent: :restrict_with_error, autosave: true
  has_many :freecen_csv_files, dependent: :restrict_with_error, autosave: true
  has_many :freecen1_vld_files, dependent: :restrict_with_error, autosave: true



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

    def status(status)
      where(status: status)
    end

    def valid_series?(series)
      return true if %w[HO107 RG9 RG10 RG11 RG12 RG13 RG14].include?(series.upcase)

      # Need to add Scotland and Ireland
      false
    end

    def extract_year_and_piece(description, chapman_code)
      # Need to add Ireland
      remove_extension = description.split('.')
      parts = remove_extension[0].split('_')
      case parts[0].upcase
      when 'RG9'
        year = '1861'
        census_fields = Freecen::CEN2_1861
      when 'RG10'
        year = '1871'
        census_fields = Freecen::CEN2_1871
      when 'RG11'
        year = '1881'
        census_fields = Freecen::CEN2_1881
      when 'RG12'
        year = '1891'
        census_fields = Freecen::CEN2_1891
      when 'RG13'
        year = '1901'
        census_fields = Freecen::CEN2_1901
      when 'RG14'
        year = '1911'
        census_fields = Freecen::CEN2_1911
      when 'HO107'
        year = parts[1].delete('^0-9').to_i <= 1465 ? '1841' : '1851'
        census_fields = parts[1].delete('^0-9').to_i <= 1465 ? Freecen::CEN2_1841 : Freecen::CEN2_1851
      when 'HS51'
        year = parts[1].delete('^0-9')[2..3] == '51' ? '1851' : '1841'
        census_fields = parts[1].delete('^0-9')[2..3] == '51' ? Freecen::CEN2_SCT_1851 : Freecen::CEN2_SCT_1841
      when 'RS6'
        year = '1861'
        census_fields = Freecen::CEN2_SCT_1861
      when 'RS7'
        year = '1871'
        census_fields = Freecen::CEN2_SCT_1871
      when 'RS8'
        year = '1881'
        census_fields = Freecen::CEN2_SCT_1881
      when 'RS9'
        year = '1891'
        census_fields = Freecen::CEN2_SCT_1891
      when 'RS10'
        year = '1901'
        census_fields = Freecen::CEN2_SCT_1901
      when 'RS11'
        year = '1911'
        census_fields = Freecen::CEN2_SCT_1911
      end
      piece = parts[1].present? ? parts[0] + '_' + parts[1] : parts[0]
      [year, piece, census_fields]
    end

    def before_year_totals(time)
      last_id = BSON::ObjectId.from_time(time)
      totals_pieces = {}
      totals_pieces_online = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        totals_pieces[year] = Freecen2Piece.where(_id: { '$lte' => last_id }).year(year).count
        totals_pieces_online[year] = Freecen2Piece.where(status_date: { '$lte' => time }).year(year).status('Online').count
      end
      [totals_pieces, totals_pieces_online]
    end

    def before_county_year_totals(chapman_code, time)
      last_id = BSON::ObjectId.from_time(time)
      totals_pieces = {}
      totals_pieces_online = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        totals_pieces[year] = Freecen2Piece.where(_id: { '$lte' => last_id }).chapman_code(chapman_code).year(year).count
        totals_pieces_online[year] = Freecen2Piece.where(status_date: { '$lte' => time }).chapman_code(chapman_code).year(year).status('Online').count
      end
      [totals_pieces, totals_pieces_online]
    end


    def before_place_year_totals(chapman_code, place_id, time)
      last_id = BSON::ObjectId.from_time(time)
      totals_pieces = {}
      totals_pieces_online = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        totals_pieces[year]  = Freecen2Piece.where(_id: { '$lte' => last_id }, freecen2_place_id: place_id).chapman_code(chapman_code).year(year).count
        totals_pieces_online[year] = Freecen2Piece.where(status_date: { '$lte' => time }, freecen2_place_id: place_id).chapman_code(chapman_code).year(year).status('Online').count
      end
      [totals_pieces, totals_pieces_online]
    end


    def between_dates_year_totals(time1, time2)
      totals_pieces_online = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        totals_pieces_online[year] = Freecen2Piece.between(status_date: time1..time2).year(year).status('Online').count
      end
      totals_pieces_online
    end

    def between_dates_county_year_totals(chapman_code, time1, time2)
      last_id = BSON::ObjectId.from_time(time2)
      totals_pieces_online = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        totals_pieces_online[year] = Freecen2Piece.between(status_date: time1..time2).chapman_code(chapman_code).year(year).status('Online').count
      end
      totals_pieces_online
    end

    def between_dates_place_year_totals(chapman_code, place_id, time1, time2)
      totals_pieces_online = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        totals_pieces_online[year] = 0
        totals_pieces_online[year]  = Freecen2Piece.where(:status_date => time1..time2, chapman_code: chapman_code, year: year, freecen2_place_id: place_id, status: 'Online').count
      end
      totals_pieces_online
    end

    def county_year_totals(chapman_code)
      totals_pieces = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        totals_pieces[year] = 0
        Freecen2District.chapman_code(chapman_code).year(year).each do |district|
          totals_pieces[year] = totals_pieces[year] + district.freecen2_pieces.count
        end
      end
      totals_pieces
    end

    def grand_totals(pieces)
      grand_pieces = pieces.values.sum
      grand_pieces
    end

    def county_district_year_totals(id)
      totals_district_pieces = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        totals_district_pieces[year] = Freecen2Piece.where(freecen2_district_id: id, year: year).count
      end
      totals_district_pieces
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
      Freecen2Piece.where(chapman_code: chapman_code, freecen2_place_id: nil).all.order_by(name: 1, year: 1)
    end

    def district_place_name(chapman_code)
      districts = Freecen2District.distinct("freecen2_place_id")
      district_names = Freecen2District.distinct("name")
      pieces = []
      Freecen2Piece.where(chapman_code: chapman_code).all.order_by(name: 1, year: 1).each do |piece|
        pieces << piece if piece.freecen2_place_id.present? && districts.include?(piece.freecen2_place_id) && !district_names.include?(piece.name)
      end
      pieces
    end

    def transform_piece_params(params)
      return params if params.blank?

      new_piece_params = {}
      new_piece_params[:chapman_code] = params['chapman_code']
      new_piece_params[:year] = params['year']
      new_piece_params[:reason_changed] = params['reason_changed']
      new_piece_params[:freecen2_district_id] = params['freecen2_district_id']
      new_piece_params[:name] = params['name'].strip if params['name'].present?
      new_piece_params[:number] = params['number'].strip if params['number'].present?
      new_piece_params[:code] = params['code']
      new_piece_params[:notes] = params['notes']
      new_piece_params[:prenote] = params['prenote']
      new_piece_params[:freecen2_place_id] = Freecen2Place.place_id(params['chapman_code'], params[:freecen2_place_id])
      new_piece_params
    end

    def create_csv_file(chapman_code, year, pieces)
      file = "#{chapman_code}_#{year}_Piece_Index.csv"
      file_location = Rails.root.join('tmp', file)
      success, message = Freecen2Piece.write_csv_file(file_location, chapman_code, year, pieces)

      [success, message, file_location, file]
    end

    def write_csv_file(file_location, chapman_code, year, pieces)
      header = year == 'all' ? Freecen2Piece.all_year_header(chapman_code) : Freecen2Piece.year_header(chapman_code, year)

      CSV.open(file_location, 'wb', { row_sep: "\r\n" }) do |csv|
        csv << header
        record_number = 0
        pieces.each do |rec|
          next if rec.blank?

          record_number += 1
          line = []
          line = year == 'all' ? Freecen2Piece.add_all_year_fields(line, record_number, chapman_code, rec) : Freecen2Piece.add_year_fields(line, record_number, chapman_code, rec)
          csv << line
        end
      end
      [true, '']
    end

    def year_header(chapman_code, year)
      header = []
      header << 'Rec Number'
      header << "Piece Name in #{chapman_code} for #{year}"
      header << 'Piece Number'
      header << 'District Name'
      header << 'Linked to Place'
      header << 'Action Required'
      header
    end

    def all_year_header(chapman_code)
      header = []
      header << 'Rec number'
      header << "Piece name in #{chapman_code}"
      Freecen::CENSUS_YEARS_ARRAY.each do |census|
        header << "#{census}"
      end
      header << 'Action Required'
      header
    end

    def add_year_fields(line, number, chapman_code, rec)
      line << number.to_i
      line << rec.name
      line << rec.number
      line << rec.district_name
      place = rec.freecen2_place.present? ? rec.place_place_name : ''
      line << place
      line
    end

    def add_all_year_fields(line, number, chapman_code, rec)
      line << number.to_i
      line << rec
      Freecen::CENSUS_YEARS_ARRAY.each do |census|
        freecen2_piece = Freecen2Piece.where(chapman_code: chapman_code, name: rec, year: census).exists?
        entry = freecen2_piece ? 'Yes' : ''
        line << entry
      end
      line
    end

    def distinct_places(county)
      places = Freecen2Place.where(chapman_code: county)

      district_places = SortedSet.new
      district_recs = Freecen2District.where(chapman_code: county, name: district_name)
      district_recs.each do |district|
        district_pieces = Freecen2Piece.chapman_code(county).freecen2_district_id(district.id).distinct(:freecen2_place_id)
        district_pieces.each do |place_id|
          place = Freecen2Place.find_by(_id: place_id)
          if place.present?
            district_places << place.place_name
          end
        end
      end
      district_places
    end

    def extract_freecen2_piece_vld(description)
      year, piece, series = FreecenPiece.extract_year_and_piece(description)
      series = 'HO107' if (year == '1841' || year == '1851') && series == 'HO'
      series = 'HS4' if year == '1841' && series == 'HS'
      series = 'HS5' if year == '1851' && series == 'HS'
      if series == 'RG'
        case year
        when '1861'
          series += '9'
        when '1871'
          series += '10'
        when '1881'
          series += '11'
        when '1891'
          series += '12'
        when '1901'
          series += '13'
        when '1911'
          series += '14'
        end

      elsif series == 'RS'
        case year
        when '1861'
          series += '6'
        when '1871'
          series += '7'
        when '1881'
          series += '8'
        when '1891'
          series += '9'
        when '1901'
          series += '13'
        when '1911'
          series += '14'
        end
      else
        p series unless series == 'HO107' || series == 'HS4' || series == 'HS5'
        crash  unless series == 'HO107' || series == 'HS4' || series == 'HS5'
      end
      freecen2_piece_number = series + '_' + piece.to_s
      [year, freecen2_piece_number]
    end


    def calculate_freecen2_piece_number(piece)
      codes = ChapmanCode.remove_codes(ChapmanCode::CODES)
      codes = codes["Scotland"].values
      year = piece.year
      if codes.include?(piece.chapman_code)
        # applies only to Scotland
        series = 'RS'
        series = 'HS4' if year == '1841'
        series = 'HS5' if year == '1851'
        case year
        when '1861'
          series += '6'
        when '1871'
          series += '7'
        when '1881'
          series += '8'
        when '1891'
          series += '9'
        end
      else
        series = 'RG'
        series = 'HO107' if year == '1841' || year == '1851'
        case year
        when '1861'
          series += '9'
        when '1871'
          series += '10'
        when '1881'
          series += '11'
        when '1891'
          series += '12'
        when '1901'
          series += '13'
        when '1911'
          series += '14'
        end
      end
      freecen2_piece_number = series + '_' + piece.piece_number.to_s
    end

  end

  # :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::Instance methods:::::::::::::::::::::::::::::::::::::::::::::::::::

  def add_standard_names
    self.standard_name = Freecen2Place.standard_place(name)
  end

  def check_new_name(new_name, user)
    result = Freecen2Piece.find_by(chapman_code: chapman_code, year: year, freecen2_district_id: freecen2_district_id, name: new_name).present? ? false : true
    result = true if user.person_role == 'system_administrator'
    result
  end

  def copy_to_another_district(chapman_code, new_district_id)
    success = false
    new_piece = Freecen2Piece.new(name: name, chapman_code: chapman_code, tnaid: tnaid, number: number, year: year, code: code, notes: notes, prenote: prenote,
                                  civil_parish_names: civil_parish_names, parish_number: parish_number, film_number: film_number, online_time: online_time,
                                  num_individuals: num_individuals, freecen2_district_id:  new_district_id)
    success = new_piece.save
    [success, new_piece]
  end

  def add_update_civil_parish_list
    return nil if freecen2_civil_parishes.blank?

    @civil_parish_names = ''
    freecen2_civil_parishes.order_by(name: 1).each_with_index do |parish, entry|
      if entry.zero?
        @civil_parish_names = parish.add_hamlet_township_names.empty? ? parish.name : parish.name + ', ' + parish.add_hamlet_township_names
      else
        @civil_parish_names = parish.add_hamlet_township_names.empty? ? @civil_parish_names + ', ' + parish.name : @civil_parish_names + ', ' +
          parish.name + parish.add_hamlet_township_names
      end
    end
    @civil_parish_names
  end

  def display_for_csv_show
    [year, chapman_code, district_name, number]
  end

  def do_we_update_place?
    files = freecen_csv_files.where(incorporated: true).count
    result = files > 0 ? false : true
    result
  end

  def actual_number
    parts = number.split('_')
    number = parts[1].gsub(/[a-z]/i, '').to_i
    case year
    when '1841'
      offset = 10000
    when '1851'
      offset = 20000
    when '1861'
      offset = 30000
    when '1871'
      offset = 40000
    when '1881'
      offset = 50000
    when '1891'
      offset = 60000
    when '1901'
      offset = 70000
    when '1911'
      offset = 80000
    when '1921'
      offset = 90000
    end
    number += offset
  end

  def update_place
    message = 'success'
    return [true, message] unless do_we_update_place?

    place = freecen2_place
    place.cen_data_years.delete_if { |value| value == year }
    place.data_present = false
    success = place.save
    message = 'Failed to update place' unless success
    [success, message]
  end

  def piece_search_records
    records = 0
    freecen1_vld_files.each do |file|
      records += file.num_individuals
    end
    freecen_csv_files.each do |file|
      records += file.total_records
    end
    records
  end

  def piece_names
    pieces = Freecen2Piece.where(chapman_code: chapman_code, year: year, freecen2_district_id: freecen2_district_id).all.order_by(name: 1)
    @pieces = []
    pieces.each do |piece|
      @pieces << piece.name
    end
    @pieces = @pieces.uniq.sort
  end

  def propagate(old_piece_id, old_piece_name, old_place, merge_piece)
    new_place = freecen2_place_id
    update_attribute(:_id, merge_piece.id) if merge_piece.present? && merge_piece.id != old_piece_id
    old_piece = Freecen2Piece.find_by(_id: old_piece_id)
    Freecen2Piece.where(chapman_code: chapman_code, freecen2_district_id: old_piece.freecen2_district_id, name: old_piece_name, year: year).each do |piece|
      piece.update_attributes(freecen2_place_id: new_place, name: name)
      piece.freecen2_civil_parishes.each do |civil_parish|
        old_civil_parish_place = civil_parish.freecen2_place_id
        civil_parish.update_attributes(freecen2_place_id: new_place) if old_civil_parish_place.blank? || old_civil_parish_place.to_s == old_place.to_s
      end
    end
    old_piece.destroy  if merge_piece.present? && merge_piece.id != old_piece.id
  end

  def update_freecen2_place
    result, place_id = Freecen2Place.valid_place(chapman_code, name)
    update_attributes(freecen2_place_id: place_id) if result
  end

  def update_tna_change_log(userid)
    tna = TnaChangeLog.create(userid: userid, year: year, chapman_code: chapman_code, parameters: previous_changes, tna_collection: "#{self.class}")
    tna.save
  end
end
