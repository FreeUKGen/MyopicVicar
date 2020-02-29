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
  field :piece_number, type: Integer
  field :district_name, type: String # same as place.name, copied for performance
  field :place_latitude, type: String # copy from place for performance
  field :place_longitude, type: String # copy from place for performance
  field :place_country, type: String # copy from place for performance
  field :subplaces, type: Array
  field :subplaces_sort, type: String
  field :parish_number, type: Integer
  field :suffix, type: String
  field :year, type: String
  field :film_number, type: String
  field :freecen1_filename, type: String
  field :status, type: String
  field :remarks, type: String
  field :remarks_coord, type: String #visible to coords, not public
  field :online_time, type: Integer
  field :num_individuals, type: Integer, default: 0
  belongs_to :freecen1_fixed_dat_entry, index: true
  belongs_to :place, optional: true, index: true
  has_many :freecen_dwellings

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
        totals_dwellings[year] = 0
        totals_individuals[year] = FreecenPiece.chapman_code(chapman_code).status('Online').year(year).sum(:num_individuals)
        totals_pieces[year] = FreecenPiece.chapman_code(chapman_code).year(year).count
        totals_pieces_online[year] = FreecenPiece.chapman_code(chapman_code).status('Online').year(year).length
        FreecenPiece.chapman_code(chapman_code).status('Online').year(year).each do |piece|
          totals_dwellings[year] = totals_dwellings[year] + piece.freecen_dwellings.count
        end
      end
      [totals_pieces, totals_pieces_online, totals_individuals, totals_dwellings]
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
  end
end
