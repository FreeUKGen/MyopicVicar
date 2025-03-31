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

  field :vld_files, type: Array, default: [] # used for Scotland pieces where there can be multiple files for a single piece
  field :shared_vld_file, type: String # used when a file has multiple pieces; usually only occurs with piece has been broken into parts
  field :admin_county, type: String # used by County Stats drilldown - can be different to chapman_code if a piece crosses county boundaries
  field :piece_availability, type: String, default: 'Y'
  field :piece_digitised, type: String, default: 'N'
  validates_inclusion_of :admin_county, in: ChapmanCode.values

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

    def admin_chapman_code(chapman)
      where(admin_county: chapman)
    end

    def year(year)
      where(year: year)
    end

    def status(status)
      where(status: status)
    end

    def valid_series?(series)
      return true if %w[HS4 HS5 HO107 RG9 RG10 RG11 RG12 RG13 RG14].include?(series.upcase)

      # Need to add Scotland after 1861 -> and Ireland
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
      when 'HS4'
        year = '1841'
        census_fields = Freecen::CEN2_SCT_1841
      when 'HS5'
        year = '1851'
        census_fields = Freecen::CEN2_SCT_1851
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

    def check_piece_parts(piece)
      piece_parts = piece.split('_')
      continue = true
      if piece_parts.count > 1
        part = piece_parts[1].delete('^0-9')
        continue = piece_parts[1] != part
        piece = "#{piece_parts[0]}_#{part}"
      else
        continue = false
      end
      [continue, piece]
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
      piece_ids = {}
      totals_pieces = {}
      totals_pieces_online = {}
      totals_records_online = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|

        totals_pieces_all = Freecen2Piece.chapman_code(chapman_code).year(year).count
        totals_pieces_to_ignore = Freecen2Piece.where(_id: { '$gt' => last_id }).chapman_code(chapman_code).year(year).count
        totals_pieces[year] = totals_pieces_all - totals_pieces_to_ignore

        piece_ids_all = Freecen2Piece.where(chapman_code: chapman_code, year: year).pluck(:id)
        piece_ids_to_ignore = Freecen2Piece.where(_id: { '$gt' => last_id }, chapman_code: chapman_code, year: year).pluck(:id)
        piece_ids[year] = piece_ids_all - piece_ids_to_ignore

        totals_pieces_online_all = Freecen2Piece.chapman_code(chapman_code).year(year).status('Online').count
        totals_pieces_online_to_ignore = Freecen2Piece.where(status_date: { '$gt' => time }).chapman_code(chapman_code).year(year).status('Online').count
        totals_pieces_online[year] = totals_pieces_online_all - totals_pieces_online_to_ignore

        totals_records_online_all = SearchRecord.where(chapman_code: chapman_code, record_type: year).count
        totals_records_online_to_ignore = SearchRecord.where(_id: { '$gt' => last_id }, chapman_code: chapman_code, record_type: year).count
        totals_records_online[year] = totals_records_online_all - totals_records_online_to_ignore

      end
      [totals_pieces, totals_pieces_online, totals_records_online, piece_ids]
    end

    def before_place_year_totals(place_id, time)
      last_id = BSON::ObjectId.from_time(time)
      piece_ids = {}
      totals_pieces = {}
      totals_pieces_online = {}
      totals_records_online = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        piece_ids_array = []
        vld_total_pieces = 0
        csv_total_pieces = 0
        vld_total_pieces_online = 0
        csv_total_pieces_online = 0

        pieces_all = Freecen2Piece.where(freecen2_place_id: place_id, year: year)
        pieces_to_ignore = Freecen2Piece.where(_id: { '$gt' => last_id }, freecen2_place_id: place_id, year: year)
        pieces = pieces_all - pieces_to_ignore

        pieces.each do |piece|
          unless SearchRecord.where(freecen2_piece_id: piece._id).present? # CSVProc data
            vld_total_pieces += 1
            piece_ids_array << piece._id
            vld_total_pieces_online += 1  if piece.status == 'Online'
          end
        end

        csv_piece_ids_all = SearchRecord.where(record_type: year, freecen2_place_id: place_id).pluck(:freecen2_piece_id).uniq
        csv_piece_ids_to_ignore = SearchRecord.where(_id: { '$gt' => last_id }, record_type: year, freecen2_place_id: place_id).pluck(:freecen2_piece_id).uniq
        csv_piece_ids = csv_piece_ids_all - csv_piece_ids_to_ignore

        if csv_piece_ids.present?
          csv_piece_ids.each do |csv_piece_id|
            if csv_piece_id.present?
              csv_total_pieces += 1
              csv_total_pieces_online += 1 if Freecen2Piece.find_by(_id: csv_piece_id, status: 'Online').present?
              piece_ids_array << csv_piece_id
            end
          end
        end
        totals_pieces[year] = vld_total_pieces + csv_total_pieces
        totals_pieces_online[year] = vld_total_pieces_online + csv_total_pieces_online
        piece_ids[year] = piece_ids_array

        totals_records_online_all = SearchRecord.where(freecen2_place_id: place_id, record_type: year).count
        totals_records_online_to_ignore = SearchRecord.where(_id: { '$gt' => last_id }, freecen2_place_id: place_id, record_type: year).count
        totals_records_online[year] = totals_records_online_all - totals_records_online_to_ignore
      end
      [totals_pieces, totals_pieces_online, totals_records_online, piece_ids]
    end

    def between_dates_year_totals(time1, time2)
      totals_pieces_online = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        totals_pieces_online[year] = Freecen2Piece.between(status_date: time1..time2).year(year).status('Online').count
      end
      totals_pieces_online
    end

    def between_dates_county_year_totals(chapman_code, time1, time2)
      first_id = BSON::ObjectId.from_time(time1)
      last_id = BSON::ObjectId.from_time(time2)
      totals_pieces_online = {}
      totals_records_online = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        totals_pieces_online[year] = Freecen2Piece.between(status_date: time1..time2).chapman_code(chapman_code).year(year).status('Online').count
        totals_records_online_all = SearchRecord.where(chapman_code: chapman_code, record_type: year).count
        totals_records_online_to_ignore_before = SearchRecord.where(_id: { '$lt' => first_id }, chapman_code: chapman_code, record_type: year).count
        totals_records_online_to_ignore_after = SearchRecord.where(_id: { '$gt' => last_id }, chapman_code: chapman_code, record_type: year).count
        totals_records_online[year] = totals_records_online_all - totals_records_online_to_ignore_before - totals_records_online_to_ignore_after
      end
      [totals_pieces_online, totals_records_online]
    end

    def between_dates_place_year_totals(place_id, time1, time2)
      totals_pieces_online = {}
      totals_records_online = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        totals_pieces_online[year] = 0
        vld_total_pieces_online = 0
        csv_total_pieces_online = 0
        vld_total_records_online = 0
        csv_total_records_online = 0
        pieces_online = Freecen2Piece.where(status_date: (time1..time2), freecen2_place_id: place_id, year: year, status:'Online')
        pieces_online.each do |piece|
          unless SearchRecord.where(freecen2_piece_id: piece._id).present? # CSVProc data
            vld_total_pieces_online += 1
            vld_total_records_online += piece.num_individuals
          end
        end
        csv_piece_ids = SearchRecord.where(c_at: (time1..time2), record_type: year, freecen2_place_id: place_id).pluck(:freecen2_piece_id).uniq
        if csv_piece_ids.present?
          csv_piece_ids.each do |csv_piece_id|
            if csv_piece_id.present?
              if Freecen2Piece.find_by(_id: csv_piece_id, status: 'Online').present?
                csv_total_pieces_online += 1
                csv_total_records_online = SearchRecord.where(freecen2_piece_id: csv_piece_id).count
              end
            end
          end
        end
        totals_pieces_online[year] = vld_total_pieces_online + csv_total_pieces_online
        totals_records_online[year] = vld_total_records_online + csv_total_records_online
      end
      [totals_pieces_online, totals_records_online]
    end

    def between_dates_pieces_online(start_date, end_date)
      @pieces_online = []
      @pieces = Freecen2Piece.where(status_date: start_date..end_date, status: 'Online').or(Freecen2Piece.where(status_date: start_date..end_date, status: 'Part'))
      @pieces.each do |piece|
        if piece.status == 'Online'
          num_records = piece.num_individuals.positive? ? piece.num_individuals : SearchRecord.where(freecen2_piece_id: piece.id).count
        else
          csv_files = FreecenCsvFile.where(freecen2_piece_id: piece.id, incorporated_date: start_date..end_date)
          num_records = 0
          csv_files.each do |file|
            num_records += file.total_individuals
          end
        end
        @pieces_online << [piece.chapman_code, piece.year, piece.number, piece.name, piece.civil_parish_names, piece.status, piece.status_date.strftime('%d/%b/%Y'), num_records]
      end
      @pieces_online.sort
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

    def create_csv_export_listing(chapman_code, year)
      @freecen2_pieces = Freecen2Piece.where(admin_county: chapman_code, year: year).order_by('status_date DESC, number ASC')
      file = "Piece_Status_#{chapman_code}_#{year}.csv"
      file_location = Rails.root.join('tmp', file)
      success, message = write_csv_listing_file(file_location, @freecen2_pieces, chapman_code)

      [success, message, file_location, file]
    end

    def write_csv_listing_file(file_location, pieces, chapman_code)
      column_headers = %w(piece_number piece_name status online_vld_files incorporated_csv_fles unincorporated_csv_files)

      CSV.open(file_location, 'wb', { row_sep: "\r\n" }) do |csv|
        csv << column_headers
        pieces.each do |rec|
          line = []
          line = add_csv_listing_fields(line, rec, chapman_code)
          csv << line
        end
      end
      [true, '']
    end

    def add_csv_listing_fields(line, record, chapman_code)
      line << record.display_piece_number(chapman_code)
      line << record.name
      if record.display_piece_status.blank?
        line << ' '
      else
        line << record.display_piece_status
      end
      if record.display_vld_files_piece == 'There are no VLD files'
        line << ' '
      else
        line << record.display_vld_files_piece
      end
      if record.display_csv_files_piece_incorporated == 'There are no incorporated CSV files'
        line << ' '
      else
        line << record.display_csv_files_piece_incorporated
      end
      if record.display_csv_files_piece_unincorporated == 'There are no unincorporated CSV files'
        line << ' '
      else
        line << record.display_csv_files_piece_unincorporated
      end
      line
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
      new_piece_params[:admin_county] = params['chapman_code']
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

  def display_piece_number(chap)
    if chapman_code != admin_county
      display_number = number + '(' + chapman_code + ')'
    elsif chapman_code != chap
      display_number = number + '(' + chap + ')'
    else
      display_number = number
    end
    display_number
  end

  def display_piece_status
    if status.present?
      display_status = status_date.present? ? status + " (" + status_date.to_datetime.strftime("%d/%b/%Y %R") + ")" : status
    else
      display_status = ''
    end
    display_status
  end

  def display_vld_files_piece
    if freecen1_vld_files.present?
      # normal link to vld file (usually only 1)
      files = []
      freecen1_vld_files.order_by(file_name: 1).each do |file|
        if file.userid.blank?
          files << file.file_name
        else
          files << file.file_name + ' (' + file.userid + ')'
        end
      end
      files
    elsif vld_files.present?
      # used for Scotland pieces where there can be multiple files for a single piece
      vld_files
    elsif shared_vld_file.present?
      # used when a file has multiple pieces; usually only occurs with piece has been broken into parts
      file = Freecen1VldFile.find_by(_id: shared_vld_file)
      "#{file.file_name}(shared)" if file.present?
    else
      'There are no VLD files'
    end
  end

  def display_csv_files_piece_unincorporated
    if freecen_csv_files.present?
      files = []
      freecen_csv_files.incorporated(false).order_by(file_name: 1).each do |file|
        if file.userid.blank?
          files << file.file_name + ' ()'
        else
          files << file.file_name + ' (' + file.userid + ')'
        end
      end
      files
    else
      'There are no unincorporated CSV files'
    end
  end

  def display_csv_files_piece_incorporated
    if freecen_csv_files.present?
      files = []
      freecen_csv_files.incorporated(true).order_by(file_name: 1).each do |file|
        if file.userid.blank?
          files << file.file_name + ' ()'
        else
          files << file.file_name + ' (' + file.userid + ')'
        end
      end
      files
    else
      'There are no incorporated CSV files'
    end
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

  def transcription_status
    csv_files = self.freecen_csv_files
    vld_files = self.freecen1_vld_files
    if csv_files.present?
      inprogress_csv_files = csv_files.where(validation: false, incorporated: false)
    end
    if inprogress_csv_files.present?
      inprogress_status = 'In Progress'
      userids = inprogress_csv_files.pluck(:userid)
      count = inprogress_csv_files.count
    end
    [inprogress_status, userids, count]
  end

  def piece_being_transcribed
    csv_files = self.freecen_csv_files
    vld_files = self.freecen1_vld_files
    uploaded_vld_files = self.freecen1_vld_files.where("userid" => {'$ne': nil}) if vld_files.present?
    if uploaded_vld_files.present?
      unincorporated =  []
      uploaded_vld_files.each{|vld_file|
        next if vld_file.search_records.count > 0
        unincorporated << vld_file.search_records.count == 0
      }
    end
    if csv_files.present?
      inprogress_csv_files = csv_files.where(incorporated: false, "userid" => {'$exists': true})
    end
    if inprogress_csv_files.present?
      inprogress_status = 'Yes'
    elsif unincorporated.present?
      inprogress_status = 'Yes'
    else
      inprogress_status = 'No'
    end
    #inprogress_status = inprogress_csv_files.present? ? 'Yes' : 'No'
    [inprogress_status]
  end

  def validation_status
    csv_files = self.freecen_csv_files
    vld_files = self.freecen1_vld_files
    if csv_files.present?
      validatation_in_progress_files = csv_files.where(validation: true, incorporated: false)
    end
    if validatation_in_progress_files.present?
      inprogress_status = 'In Progress'
      userids = validatation_in_progress_files.pluck(:userid)
      count = validatation_in_progress_files.count
    end
    [inprogress_status, userids, count]
  end


  def incorpoation_status
    csv_files = self.freecen_csv_files
    vld_files = self.freecen1_vld_files
    incorporated_and_complete = csv_files.where(incorporated: true, completes_piece: true)
    incorporated_and_part_complete = csv_files.where(incorporated: true, completes_piece: false)
    status = 'Yes' if incorporated_and_complete.present?
    status = 'Part' if  incorporated_and_part_complete.present?
    status = 'Vld' if vld_files.exists?
    status
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

  def update_parts_status_on_file_upload(file, freecen1_piece)
    return if file.blank? || freecen1_piece.blank?

    piece2_number = Freecen2Piece.calculate_freecen2_piece_number(freecen1_piece)
    regexp = BSON::Regexp::Raw.new('^' + piece2_number + '\D')
    parts = Freecen2Piece.where(number: regexp).order_by(number: 1)
    return if parts.count.zero?

    parts.each do |part|
      part.update_attributes(status: 'Online', status_date: file._id.generation_time.to_datetime.in_time_zone('London'), shared_vld_file: file.id)
    end
  end

  def  update_parts_status_on_file_deletion(file, freecen1_piece)
    return if file.blank? || freecen1_piece.blank?

    piece2_number = Freecen2Piece.calculate_freecen2_piece_number(freecen1_piece)
    regexp = BSON::Regexp::Raw.new('^' + piece2_number + '\D')
    parts = Freecen2Piece.where(number: regexp).order_by(number: 1)

    return if parts.count.zero?

    parts.each do |part|
      part.update_attributes(status: '', status_date: '', shared_vld_file: '')
    end
  end

  def self.find_by_vld_file_name(freecen1_piece)
    return if freecen1_piece.blank?

    piece2_number = Freecen2Piece.calculate_freecen2_piece_number(freecen1_piece)
    freecen2_piece = Freecen2Piece.find_by(number: piece2_number)
    freecen2_place = freecen2_piece.freecen2_place if freecen2_piece.present?
    return [freecen2_piece, freecen2_place] if freecen2_piece.present?

    regexp = BSON::Regexp::Raw.new('^' + piece2_number + '\D')
    parts = Freecen2Piece.where(number: regexp).order_by(number: 1)

    return if parts.count.zero?

    freecen2_place = parts[0].freecen2_place
    [parts[0], freecen2_place]
  end
end
