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
  field :tnaid, type: String
  field :number, type: String
  validates :number, presence: true
  field :year, type: String
  validates_inclusion_of :year, in: Freecen::CENSUS_YEARS_ARRAY
  field :code, type: String
  field :notes, type: String
  field :prenote, type: String
  field :civil_parish_names, type: String




  field :film_number, type: String

  field :status, type: String
  field :remarks, type: String
  field :remarks_coord, type: String # visible to coords, not public
  field :online_time, type: Integer
  field :num_individuals, type: Integer, default: 0

  belongs_to :freecen2_district, optional: true, index: true

  delegate :chapman_code, :name, :tnaid, :code, :note, to: :freecen2_district, prefix: :district, allow_nil: true

  belongs_to :place, optional: true, index: true
  has_many :freecen2_civil_parishes, dependent: :restrict_with_error
  has_many :freecen_dwellings, dependent: :restrict_with_error
  has_many :freecen_csv_files, dependent: :restrict_with_error
  has_many :freecen_individuals, dependent: :restrict_with_error
  index(district_chapman_code: 1, year: 1, name: 1)
  index(district_chapman_code: 1, year: 1, number: 1)

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

    def extract_year_and_piece(description)
      parts = description.split('.')
      stem = parts[0]
      first_two_characters = stem.slice(0, 2).upcase if stem.slice(0, 2).present?
      third_character = stem.slice(2, 1)
      third_and_fourth = stem.slice(2, 2)
      last_three = stem.slice(5, 3)
      last_four = stem.slice(4, 4)
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
        if third_and_fourth == '51'
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
        elsif third_and_fourth == '7'
          piece = last_three
          year = '1871'
        elsif third_and_fourth == '8'
          piece = last_three
          year = '1881'
        elsif third_and_fourth == '9'
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
      [year, piece.to_i]
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
  end

  def add_update_civil_parish_list
    return nil if freecen2_civil_parishes.blank?

    @civil_parish_names = ''
    freecen2_civil_parishes.order_by(name: 1).each_with_index do |parish, entry|
      if entry.zero?
        @civil_parish_names = parish.add_hamlet_township_names.empty? ? parish.name : parish.name + parish.add_hamlet_township_names
      else
        @civil_parish_names = parish.add_hamlet_township_names.empty? ? @civil_parish_names + ', ' + parish.name : @civil_parish_names + ', ' +
          parish.name + parish.add_hamlet_township_names
      end
    end
    @civil_parish_names
  end
end
