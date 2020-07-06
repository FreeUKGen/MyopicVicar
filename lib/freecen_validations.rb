module FreecenValidations

  VALID_UCF = /[\}\{\?\*\_\]\[\,]/
  VALID_NAME = /[\w\'\"\ \.\;\:]/
  VALID_NUMERIC = /\d/
  VALID_NUMBER  = /\A\d+\z/
  VALID_NUMBER_PLUS_SUFFIX = /\A\d+/
  VALID_ENUMERATOR_SPECIAL = /\A\d#\d\z/
  VALID_SPECIAL_LOCATION_CODES = %w[b n u v x].freeze
  VALID_TEXT = /(\w*|-)/
  VALID_PIECE = /\A(R|H)(G|O|S)/i
  VALID_AGE_MAXIMUM = { 'd' => 100, 'w' => 100, 'm' => 100, 'y' => 120, 'h' => 100, '?' => 100, 'years' => 120, 'months' => 100, 'weeks' => 100,
                        'days' => 100, 'hours' => 100 }.freeze
  VALID_DATE = /\A\d{1,2}[\s+\/\-][A-Za-z\d]{0,3}[\s+\/\-]\d{2,4}\z/ #modern date no UCF or wildcard
  VALID_DAY = /\A\d{1,2}\z/
  VALID_MONTH = %w[JAN FEB MAR APR MAY JUN JUL AUG SEP SEPT OCT NOV DEC * JANUARY FEBRUARY MARCH APRIL MAY JUNE JULY AUGUST SEPTEMBER
                   OCTOBER NOVEMBER DECEMBER].freeze
  VALID_NUMERIC_MONTH = /\A\d{1,2}\z/
  VALID_YEAR = /\A\d{4,5}\z/
  DATE_SPLITS = { ' ' => /\s/, '-' => /\-/, '/' => /\\/ }.freeze
  WILD_CHARACTER = /[\*\[\]\-\_\?]/
  VALID_MARITAL_STATUS = %w[m s u w d -].freeze
  VALID_SEX = %w[M F -].freeze
  VALID_LANGUAGE = %w[E G GE I IE M ME W WE].freeze
  class << self
    def valid_piece?(field)
      return false if field.blank?

      parts = field.split('_')
      return false if parts.length.zero?

      return false unless Freecen2Piece.valid_series?(parts[0])

      true
    end

    def valid_civil_parish?(field)
      return [false, 'blank'] if field.blank?

      return [false, 'INVALID_TEXT'] unless field =~ VALID_TEXT

      [true, '']
    end

    def enumeration_district?(field)
      return [true, ''] if field.blank?

      return [true, ''] if field =~ VALID_NUMBER

      return [true, ''] if field =~ VALID_NUMBER_PLUS_SUFFIX

      return [true, ''] if field =~ VALID_ENUMERATOR_SPECIAL

      [false, 'invalid']
    end

    def text?(field)
      return [true, ''] if field.blank?

      return [false, 'INVALID_TEXT'] unless field =~ VALID_TEXT

      [true, '']
    end

    def location_flag?(field)
      return [true, ''] if field.blank?

      return [true, ''] if field.downcase == 'x'

      [false, 'invalid value']
    end

    def folio_number?(field)
      return [true, ''] if field.blank?

      return [true, ''] if field =~ VALID_NUMBER && field.length <= 4
      shorten_field = field
      shorten_field = field.slice(0..-2) if (/\D/ =~ field.slice(-1, 1)).present?
      return [true, ''] if shorten_field =~ VALID_NUMBER && shorten_field.length <= 4

      [false, 'invalid number']
    end

    def page_number?(field)
      return [true, ''] if field =~ VALID_NUMBER && field.length <= 4

      [false, 'invalid number']
    end

    def schedule_number?(field)
      return [true, ''] if field.present? && field =~ VALID_NUMBER

      return [true, ''] if field.present? && field =~ VALID_NUMBER_PLUS_SUFFIX

      return [false, 'blank'] if field.blank?

      [false, 'invalid number']
    end

    def house_number?(field)
      return [true, ''] if field.blank?

      return [true, ''] if field.present? && field =~ VALID_NUMBER

      return [true, ''] if field.present? && field =~ VALID_NUMBER_PLUS_SUFFIX

      [false, 'invalid number']
    end

    def house_address?(field)
      return [true, ''] if field.blank?

      return [true, ''] if field.present? && field =~ VALID_TEXT

      return [false, '?'] if field.present? && field.slice(-1).downcase == '?' && field =~ VALID_TEXT

      [false, 'invalid address']
    end

    def walls?(field)
      return [true, ''] if field.blank?

      return [true, ''] if [0, 1].include?(field.to_i)

      [false, 'Not 0 or 1 or blank']
    end

    def roof_type?(field)
      return [true, ''] if field.blank?

      return [true, ''] if [0, 1].include?(field.to_i)

      [false, 'Not 0 or 1 or blank']
    end

    def rooms_with_windows?(field)
      return [true, ''] if field.blank?

      return [true, ''] if field =~ VALID_NUMBER

      [false, 'Not valid number']
    end

    def class_of_house?(field)
      return [true, ''] if field.blank?

      return [true, ''] if field =~ VALID_TEXT

      [false, 'Not valid class']
    end

    def uninhabited_flag?(field)
      return [true, ''] if field.blank?

      return [true, ''] if VALID_SPECIAL_LOCATION_CODES.include?(field.downcase)

      [false, 'invalid value']
    end

    def address_flag?(field)
      return [true, ''] if field.blank?

      return [true, ''] if field.downcase == 'x'

      [false, 'invalid value']
    end


    def surname?(field)
      return [false, 'blank'] if field.blank?

      return [false, '?'] if field.present? && field.slice(-1).downcase == '?' && field =~ VALID_TEXT

      return [true, ''] if field =~ VALID_TEXT

      [false, 'invalid value']
    end

    def forenames?(field)
      return [false, 'blank'] if field.blank?

      return [false, '?'] if field.present? && field.slice(-1).downcase == '?' && field =~ VALID_TEXT

      return [true, ''] if field =~ VALID_TEXT

      [false, 'invalid value']
    end

    def name_question?(field)
      return [true, ''] if field.blank?

      return [true, ''] if field =~ VALID_TEXT

      [false, 'invalid value']
    end

    def relationship?(field)
      return [true, ''] if field.blank?

      return [true, ''] if field =~ VALID_TEXT

      [false, 'invalid value']
    end

    def marital_status?(field)
      return [true, ''] if field.blank?

      return [true, ''] if VALID_MARITAL_STATUS.include?(field.downcase) && field.length <= 1

      [false, 'invalid value']
    end

    def sex?(field)
      return [false, 'blank'] if field.blank?

      return [true, ''] if VALID_SEX.include?(field.upcase) && field.length <= 1

      [false, 'invalid value']
    end

    def age?(field, martial, sex)
      return [false, 'blank'] if field.blank?

      return [true, ''] if field =~ VALID_NUMBER && field.to_i == 999

      return [true, ''] if field =~ VALID_NUMBER && field.length <= 3 && field.to_i != 0 && field.to_i <= 120

      return [true, ''] if field.slice(-1).downcase == 'y'  && field[0...-1].to_i >= 14 && field[0...-1].to_i <= 120 && ['m', 'w'].include?(martial) && ['M', '-'].include?(sex)

      return [true, ''] if field.slice(-1).downcase == 'y'  && field[0...-1].to_i >= 12 && field[0...-1].to_i <= 120 && ['m', 'w'].include?(martial) && sex == 'F'

      return [true, ''] if field.slice(-1).downcase == 'y'  && field[0...-1].to_i > 0 && field[0...-1].to_i <= 120 && ['s', 'u', '-'].include?(martial)

      return [true, ''] if field.slice(-1).downcase == 'm'  && field[0...-1].to_i != 0 && field[0...-1].to_i <= 24

      return [true, ''] if field.slice(-1).downcase == 'w'  && field[0...-1].to_i != 0 && field[0...-1].to_i <= 20

      return [true, ''] if field.slice(-1).downcase == 'd'  && field[0...-1].to_i != 0 && field[0...-1].to_i <= 30

      [false, 'invalid value, check age, marital status and sex fields']
    end

    def school_children?(field)
      return [true, ''] if field =~ VALID_NUMBER

      [false, 'Not valid number']
    end

    def years_married?(field)
      return [true, ''] if field =~ VALID_NUMBER && field.to_i <= 100

      [false, 'Not valid number']
    end

    def children_born_alive?(field)
      return [true, ''] if field =~ VALID_NUMBER && field.to_i <= 30

      [false, 'Not valid number']
    end

    def children_living?(field)
      return [true, ''] if field =~ VALID_NUMBER && field.to_i <= 30

      [false, 'Not valid number']
    end

    def children_deceased?(field)
      return [true, ''] if field =~ VALID_NUMBER && field.to_i <= 30

      [false, 'Not valid number']
    end

    def religion?(field)
      return [true, ''] if field =~ VALID_TEXT

      [false, 'Not valid text']
    end

    def read_write?(field)
      return [true, ''] if field =~ VALID_TEXT

      [false, 'Not valid text']
    end

    def uncertainty_status?(field)
      return [true, ''] if field.blank?

      return [true, ''] if field.downcase == 'x'

      [false, 'invalid value']
    end

    def occupation?(field, age)
      return [true, ''] if field.blank?

      if age.present?

        return [false, 'invalid use of Scholar'] if age =~ VALID_NUMBER && (age.to_i < 2 || age.to_i > 17) && field.downcase =~ /(scholar)/

        return [false, 'invalid use of Scholar'] if age.slice(-1).downcase == 'y' && (age[0...-1].to_i < 2 || age[0...-1].to_i > 17) && field.downcase =~ /(scholar)/

      end
      return [false, '?'] if field.slice(-1).downcase == '?'

      [true, '']
    end

    def industry?(field)
      return [true, ''] if field =~ VALID_TEXT

      [false, 'Not valid text']
    end

    def occupation_category?(field)
      return [true, ''] if field.blank?

      return [true, ''] if field.length == 1 && ['e', 'r', 'n'].include?(field.downcase)

      [false, 'invalid value']
    end

    def uncertainty_occupation?(field)
      return [true, ''] if field.blank?

      return [true, ''] if field.downcase == 'x'

      [false, 'invalid value']
    end

    def verbatim_birth_county?(field)
      return [false, 'blank'] if field.blank?

      return [true, ''] if ChapmanCode.freecen_birth_codes.include?(field.upcase)

      [false, 'invalid value']
    end

    def verbatim_birth_place?(field)
      return [false, 'blank'] if field.blank?

      return [true, ''] if field =~ VALID_TEXT

      [false, 'invalid value']
    end

    def nationality?(field)
      return [true, ''] if field =~ VALID_TEXT

      [false, 'Not valid text']
    end

    def father_place_of_birth?(field)
      return [true, ''] if field =~ VALID_TEXT

      [false, 'Not valid text']
    end

    def uncertainy_birth?(field)
      return [true, ''] if field.blank?

      return [true, ''] if field.downcase == 'x'

      [false, 'invalid value']
    end

    def language?(field)
      return [true, ''] if field.blank?

      return [true, ''] if VALID_LANGUAGE.include?(field.upcase)

      [false, 'invalid value']
    end

    def disability?(field)
      return [true, ''] if field.blank?

      return [true, ''] if field =~ VALID_TEXT

      [false, 'invalid value']
    end

    def disability_notes?(field)
      return [true, ''] if field.blank?

      return [true, ''] if field =~ VALID_TEXT

      [false, 'invalid value']
    end

    def notes?(field)
      return [true, ''] if field.blank?

      return [true, ''] if field =~ VALID_TEXT

      [false, 'invalid value']
    end

    def at_home?(field)
      return [true, ''] if field.downcase == 'h' && field.length == 1

      return [true, ''] if field.downcase == 'at home' && field.length == 7

      [false, 'invalid value']
    end

    def rooms?(field, year)
      return [true, ''] if field =~ VALID_NUMBER && year == '1901' && field.to_i <= 5

      return [true, ''] if field =~ VALID_NUMBER && year == '1911' && field.to_i <= 19

      [false, 'invalid value']
    end
  end
end
