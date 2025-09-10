class FreecenPiece
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

  field :chapman_code, type: String
  validates_inclusion_of :chapman_code, in: ChapmanCode.values
  field :piece_number, type: Integer
  validates :piece_number, presence: true
  validates :piece_number, numericality: { only_integer: true }
  field :district_name, type: String # same as place.name, copied for performance
  validates :district_name, presence: true
  field :place_latitude, type: String # copy from place for performance
  field :place_longitude, type: String # copy from place for performance
  field :place_country, type: String # copy from place for performance
  field :subplaces, type: Array
  field :subplaces_sort, type: String
  field :parish_number, type: Integer
  validates :parish_number, numericality: { only_integer: true }, allow_blank: true
  field :suffix, type: String
  field :year, type: String
  validates_inclusion_of :year, in: Freecen::CENSUS_YEARS_ARRAY
  field :film_number, type: String
  field :freecen1_filename, type: String
  field :status, type: String
  field :status_date, type: DateTime
  field :remarks, type: String
  field :remarks_coord, type: String #visible to coords, not public
  field :online_time, type: Integer
  field :num_entries, type: Integer, default: 0
  field :num_individuals, type: Integer, default: 0
  field :num_dwellings, type: Integer, default: 0

  belongs_to :freecen1_fixed_dat_entry, index: true, optional: true
  belongs_to :place, optional: true, index: true
  belongs_to :freecen2_place, optional: true, index: true
  belongs_to :freecen2_piece, optional: true, index: true
  has_many :freecen_dwellings, dependent: :restrict_with_error
  has_many :freecen1_vld_files, dependent: :restrict_with_error


  index(:piece_number => 1, :chapman_code => 1)
  index(:piece_number => 1, :chapman_code => 1, :year => 1, :suffix => 1, :parish_number => 1)

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
      totals_pieces_online = {}
      totals_individuals = {}
      totals_dwellings = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        totals_individuals[year] = FreecenPiece.chapman_code(chapman_code).year(year).status('Online').hint('chapman_code_1__year_1_status_1').sum(:num_individuals)
        totals_pieces[year] = FreecenPiece.chapman_code(chapman_code).year(year).hint('chapman_code_1__year_1_status_1').count
        totals_pieces_online[year] = FreecenPiece.chapman_code(chapman_code).year(year).hint('chapman_code_1__year_1_status_1').status('Online').count
        totals_dwellings[year] = FreecenPiece.chapman_code(chapman_code).year(year).hint('chapman_code_1__year_1_status_1').status('Online').sum(:num_dwellings)
      end
      [totals_pieces, totals_pieces_online, totals_individuals, totals_dwellings]
    end

    def before_county_year_totals(chapman_code, time)
      last_id = BSON::ObjectId.from_time(time)
      totals_pieces = {}
      totals_pieces_online = {}
      totals_individuals = {}
      totals_dwellings = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        totals_individuals[year] = FreecenPiece.where(_id: { '$lte' => last_id }).chapman_code(chapman_code).year(year).status('Online').hint('id_chapman_code_year_status').sum(:num_individuals)
        totals_pieces[year] = FreecenPiece.where(_id: { '$lte' => last_id }).chapman_code(chapman_code).year(year).hint('id_chapman_code_year_status').count
        totals_pieces_online[year] = FreecenPiece.where(_id: { '$lte' => last_id }).chapman_code(chapman_code).year(year).status('Online').hint('id_chapman_code_year_status').count
        totals_dwellings[year] = FreecenPiece.where(_id: { '$lte' => last_id }).chapman_code(chapman_code).year(year).status('Online').hint('id_chapman_code_year_status').sum(:num_dwellings)
      end
      [totals_pieces, totals_pieces_online, totals_individuals, totals_dwellings]
    end

    def between_dates_county_year_totals(chapman_code, time1, time2)
      last_id = BSON::ObjectId.from_time(time2)
      first_id = BSON::ObjectId.from_time(time1)
      totals_pieces = {}
      totals_pieces_online = {}
      totals_individuals = {}
      totals_dwellings = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        totals_individuals[year] = FreecenPiece.between(_id: first_id..last_id).chapman_code(chapman_code).year(year).status('Online').hint('id_chapman_code_year_status').sum(:num_individuals)
        totals_pieces[year] = FreecenPiece.between(_id: first_id..last_id).chapman_code(chapman_code).year(year).hint('id_chapman_code_year_status').count
        totals_pieces_online[year] = FreecenPiece.between(_id: first_id..last_id).chapman_code(chapman_code).year(year).status('Online').hint('id_chapman_code_year_status').count
        totals_dwellings[year] = FreecenPiece.between(_id: first_id..last_id).chapman_code(chapman_code).year(year).status('Online').hint('id_chapman_code_year_status').sum(:num_dwellings)
      end
      [totals_pieces, totals_pieces_online, totals_individuals, totals_dwellings]
    end

    def before_year_totals(time)
      last_id = BSON::ObjectId.from_time(time)
      totals_pieces = {}
      totals_pieces_online = {}
      totals_individuals = {}
      totals_dwellings = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        totals_pieces[year] = FreecenPiece.where(_id: { '$lte' => last_id }).year(year).hint('id_year_status').count
        totals_pieces_online[year] = FreecenPiece.where(_id: { '$lte' => last_id }).year(year).status('Online').hint('id_year_status').count
      end
      [totals_pieces, totals_pieces_online]
    end

    def between_dates_year_totals(time1, time2)
      last_id = BSON::ObjectId.from_time(time2)
      first_id = BSON::ObjectId.from_time(time1)
      totals_pieces = {}
      totals_pieces_online = {}
      totals_individuals = {}
      totals_dwellings = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        totals_individuals[year] = FreecenPiece.between(_id: first_id..last_id).year(year).status('Online').hint('id_year_status').sum(:num_individuals)
        totals_pieces[year] = FreecenPiece.between(_id: first_id..last_id).year(year).hint('id_year_status').count
        totals_pieces_online[year] = FreecenPiece.between(_id: first_id..last_id).year(year).status('Online').hint('id_year_status').count
        totals_dwellings[year] = FreecenPiece.between(_id: first_id..last_id).year(year).status('Online').hint('id_year_status').sum(:num_dwellings)
      end
      [totals_pieces, totals_pieces_online, totals_individuals, totals_dwellings]
    end

    def extract_year_and_piece(description)
      parts = description.split('.')
      stem = parts[0]
      first_two_characters = stem.slice(0, 2).upcase if stem.slice(0, 2).present?
      third_character = stem.slice(2, 1)
      third_and_fourth = stem.slice(2, 2)
      last_three = stem.slice(5, 3)
      last_four = stem.slice(4, 4)
      last_five = stem.slice(3, 5)
      case first_two_characters
      when 'RG'
        if third_character == '9' || third_and_fourth == '09'
          year = '1861'
          piece = last_four
        elsif third_and_fourth == '10'
          piece = last_four
          year = '1871'
        elsif third_and_fourth == '11'
          piece = last_four
          year = '1881'
        elsif third_and_fourth == '12'
          piece = last_four
          year = '1891'
        elsif third_and_fourth == '13'
          piece = last_four
          year = '1901'
        elsif third_and_fourth == '14'
          piece = last_four
          year = '1911'
        end
      when 'HO'
        if third_and_fourth == '51'
          piece = last_four
          year = '1851'
        else
          piece = last_three
          year = '1841'
        end
      when 'HS'
        if third_character == '5'
          piece = last_three
          year = '1851'
        else
          piece = last_three
          year = '1841'
        end
      when 'RS'
        if third_character == '6'
          year = '1861'
          piece = last_three
        elsif third_character == '7'
          piece = last_three
          year = '1871'
        elsif third_character == '8'
          piece = last_three
          year = '1881'
        elsif third_character == '9'
          piece = last_three
          year = '1891'
        elsif third_and_fourth == '10'
          piece = last_three
          year = '1901'
        elsif third_and_fourth == '11'
          piece = last_three
          year = '1911'
        else
          year = ''
          piece = ''
        end
      end

      [year, piece.to_i, first_two_characters]
    end

    def grand_totals(pieces, pieces_online, individuals, dwellings)
      grand_pieces = pieces.values.sum
      grand_pieces_online = pieces_online.values.sum
      grand_individuals = individuals.values.sum
      grand_dwellings = dwellings.values.sum
      [grand_pieces, grand_pieces_online, grand_individuals, grand_dwellings]
    end

    def grand_year_totals
      totals_pieces = {}
      totals_pieces_online = {}
      totals_individuals = {}
      totals_dwellings = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        totals_individuals[year] = FreecenPiece.status('Online').year(year).sum(:num_individuals)
        totals_pieces[year] = FreecenPiece.year(year).count
        totals_pieces_online[year] = FreecenPiece.status('Online').year(year).length
        totals_dwellings[year] = FreecenPiece.status('Online').year(year).sum(:num_dwellings)
      end
      [totals_pieces, totals_pieces_online, totals_individuals, totals_dwellings]
    end

    def check_piece_params(piece_params, controller_name)
      error_list = []
      piece = FreecenPiece.find_by(year: piece_params[:year], chapman_code: piece_params[:chapman_code], piece_number: piece_params[:piece_number])
      error_list << 'The piece number must be unique for a year and county' if piece.present? && controller_name == 'create'
      sp_names_err = false
      sp_lat_err = false
      sp_long_err = false
      piece_params[:subplaces].each do |sp|
        sp_names_err = true if sp['name'].blank? || sp['name'].length < 1
        sp_lat_err = true if sp['lat'].to_f < -90.0 || sp['lat'].to_f > 90.0
        sp_long_err = true if sp['long'].to_f < -180.0 || sp['long'].to_f > 180.0
      end
      if sp_lat_err || piece_params['latitude'].to_f < -90.0 || piece_params['latitude'].to_f > 90.0
        error_list << 'Latitudes must be between -90 and 90 (UK is between 49 and 61).'
      end
      if sp_long_err || piece_params['longitude'].to_f < -180.0 || piece_params['longitude'].to_f > 180.0
        error_list << 'Longitudes must be between -180 and 180 (UK is between -11 and 2).'
      end
      if sp_names_err
        error_list << 'Sub-place names are required.'
      end
      # parish number should be empty if not SCT
      is_scot = piece_params[:chapman_code] == 'SCS' || ChapmanCode::CODES['Scotland'].values.include?(piece_params[:chapman_code])
      error_list << 'Par number currently only supported for Scotland' if !is_scot && piece_params[:parish_number].present? && piece_params[:parish_number].length > 0
      # file name should agree with parish number if SCT
      if is_scot
        file_partnum = piece_params[:freecen1_filename][3, 2]
        error_list << 'Par number seems to disagree with FreeCEN1 Filename' if file_partnum != piece_params[:parish_number]
      end
      error_list
    end

    def transform_piece_params(piece_params)
      return piece_params if piece_params.blank?

      @new_piece_params = {}
      subplaces = []
      (0..piece_params['subplaces_max_id'].to_i).each do |ii|
        unless piece_params["subplaces_#{ii}_name"].nil?
          sp_name = piece_params["subplaces_#{ii}_name"].strip
          piece_params.delete("subplaces_#{ii}_name")
        end
        unless piece_params["subplaces_#{ii}_lat"].nil?
          sp_lat = piece_params["subplaces_#{ii}_lat"].strip
          piece_params.delete("subplaces_#{ii}_lat")
        end
        unless piece_params["subplaces_#{ii}_long"].nil?
          sp_long = piece_params["subplaces_#{ii}_long"].strip
          piece_params.delete("subplaces_#{ii}_long")
        end
        if sp_name && sp_lat && sp_long
          subplaces << {'name' => sp_name.to_s, 'lat' => sp_lat.to_f, 'long' => sp_long.to_f}
        else
          puts "*** ERROR! missing piece_params[freecen_piece_subplaces_#{ii}_*] in freecen_pieces_controller.rb check_and_transform_param()\n\n"
          puts piece_params.inspect
        end
      end
      subplaces_sort = ''
      subplaces.each do |sp|
        unless sp.blank? || sp['name'].strip.blank?
          subplaces_sort += ', ' unless '' == subplaces_sort
          subplaces_sort += sp['name'].strip.downcase
        end
      end
      @new_piece_params[:chapman_code] = piece_params['chapman_code']
      @new_piece_params[:year] = piece_params['year']
      @new_piece_params[:piece_number] = piece_params['piece_number']
      @new_piece_params[:subplaces] = subplaces
      @new_piece_params[:subplaces_sort] = subplaces_sort
      piece_params.delete('subplaces_max_id') if piece_params['subplaces_max_id'].present?
      # strip stray whitespace from parameters
      @new_piece_params[:district_name] = piece_params['district_name']
      @new_piece_params[:place_latitude] = piece_params['place_latitude']
      @new_piece_params[:place_longitude] = piece_params['place_longitude']
      @new_piece_params[:suffix] = piece_params['suffix']
      @new_piece_params[:film_number] = piece_params['film_number']
      @new_piece_params[:freecen1_filename] = piece_params['freecen1_filename']
      @new_piece_params[:status] = piece_params['status']
      @new_piece_params[:remarks] = piece_params['remarks']
      @new_piece_params[:remarks_coord] = piece_params['remarks_coord']
      @new_piece_params
    end

    def set_piece_place(piece)
      place = Place.find_by(chapman_code: piece.chapman_code, place_name: piece.district_name)
      unless place # create the new place
        place = Place.new
        place.chapman_code = piece.chapman_code
        place.place_name = piece.district_name
        place.latitude = 0
        place.longitude = 0
        place.save!
      end
      place.freecen_pieces << piece unless piece.place_id == place.id
      place_params = {}
      place_params[:place_country] = place.country
      place_params[:place_latitude] = place.latitude
      place_params[:place_longitude] = place.longitude
      [true, place_params]
    end
  end
  # ############################################################################## instances
end
