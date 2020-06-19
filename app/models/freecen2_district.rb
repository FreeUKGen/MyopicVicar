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
  field :type, type: String
  field :code, type: String
  field :notes, type: String

  has_many :freecen2_pieces, dependent: :restrict_with_error
  belongs_to :freecen2_place, optional: true, index: true
  belongs_to :county, optional: true, index: true
  delegate :county, to: :county, prefix: true, allow_nil: true

  index(county_county: 1, year: 1, name: 1)

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

  end
end
