class Freecen2District
  include Mongoid::Document
  include Mongoid::Timestamps::Short

  field :chapman_code, type: String
  validates_inclusion_of :chapman_code, in: ChapmanCode.values
  field :year, type: String
  validates_inclusion_of :year, in: Freecen::CENSUS_YEARS_ARRAY
  field :name, type: String
  validates :name, presence: true
  field :tnaid, type: String
  validates :tnaid, presence: true
  field :code, type: String
  field :notes, type: String

  has_many :freecen2_pieces
  belongs_to :place, optional: true, index: true

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
        totals_dwellings[year] = 0
        totals_individuals[year] = FreecenPiece.status('Online').year(year).sum(:num_individuals)
        totals_pieces[year] = FreecenPiece.year(year).count
        totals_pieces_online[year] = FreecenPiece.status('Online').year(year).length
        FreecenPiece.status('Online').year(year).each do |piece|
          totals_dwellings[year] = totals_dwellings[year] + piece.freecen_dwellings.count
        end
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
end
