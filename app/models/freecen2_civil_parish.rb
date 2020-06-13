class Freecen2CivilParish
  include Mongoid::Document
  include Mongoid::Timestamps::Short
  require 'freecen_constants'
  field :name, type: String
  field :note, type: String
  field :prenote, type: String
  field :number, type: Integer
  validates :number, numericality: { only_integer: true }, allow_blank: true
  field :suffix, type: String

  belongs_to  :freecen2_piece, optional: true, index: true

  embeds_many :freecen2_hamlets
  embeds_many :freecen2_townships

  delegate :year, :name, :tnaid, :number, :code, :note, to: :freecen2_piece, prefix: :piece, allow_nil: true

  index(piece_name: 1, piece_year: 1, name: 1)

  def add_hamlet_names
    @hamlet_names = ''
    freecen2_hamlets.each_with_index do |hamlet, entry|
      @hamlet_names = entry.zero? ? hamlet.name : @hamlet_names + ';' + hamlet.name
    end
    @hamlet_names = '(' + @hamlet_names + ')'
    @hamlet_names
  end

  def add_township_names
    @township_names = ''
    freecen2_townships.each_with_index do |township, entry|
      @township_names = entry.zero? ? township.name : @township_names + ';' + township.name
    end
    @township_names = '(' + @township_names + ')'
    @township_names
  end

  def add_hamlet_township_names
    @hamlet_names = ''
    freecen2_hamlets.order_by(name: 1).each do |hamlet|
      @hamlet_names = @hamlet_names.empty? ? hamlet.name : @hamlet_names + ';' + hamlet.name
    end
    freecen2_townships.order_by(name: 1).each do |township|
      @hamlet_names = @hamlet_names.empty? ? township.name : @hamlet_names + ';' + township.name
    end
    @hamlet_names = '(' + @hamlet_names + ')' unless @hamlet_names.empty?
    @hamlet_names
  end
end
