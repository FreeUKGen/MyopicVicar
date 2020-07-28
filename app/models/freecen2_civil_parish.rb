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

  belongs_to :freecen2_piece, optional: true, index: true
  belongs_to :freecen2_place, optional: true, index: true

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
end
