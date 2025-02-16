module FreecenValidations
  VALID_UCF = /[\}\{\?\*\_\]\[\,]/.freeze
  VALID_NUMERIC = /\d/.freeze
  VALID_NUMBER  = /\A\d+\z/.freeze
  HOUSE_NUMBER = /\A\d\S*\z/.freeze
  DOUBLE_SCHEDULE = /\A\d+&\d+\z/.freeze
  FRACTIONAL_SCHEDULE = /\A\d+\s[12]\/[23]\z/.freeze
  VALID_NUMBER_PLUS = /\A[\da-z?]*\z/i.freeze
  VALID_NUMBER_PLUS_SUFFIX = /\A\d+[a-z]\z/i.freeze
  VALID_ENUMERATOR_NUMBER_PLUS_SUFFIX1 = /\A\d+[a-z]{1,2}\z/i.freeze
  VALID_ENUMERATOR_NUMBER_PLUS_SUFFIX2 = /\A\d+[a-z][0-9]\z/i.freeze
  VALID_ENUMERATOR_SPECIAL = /\A\d#\d\z/.freeze
  VALID_SPECIAL_LOCATION_CODES = %w[b n u v x].freeze
  NARROW_VALID_TEXT = /\A[-\w\s,'\.]*\z/.freeze
  PARISH_TEXT = /\A[-\w\s,']*\z/.freeze
  TIGHT_VALID_TEXT = /\A[\w\s,'\.]*\z/.freeze
  NARROW_VALID_TEXT_PLUS = /\A[-\w\s,'\.]*\z/.freeze
  BROAD_VALID_TEXT = /\A[-\w\s()\.,&'":;]*\z/.freeze
  BROAD_VALID_TEXT_PLUS = /\A[-\w\s()\/\.,&'":;?]*\z/.freeze
  VALID_PIECE = /\A(R|H)(G|O|S)/i.freeze
  VALID_AGE_MAXIMUM = { 'd' => 100, 'w' => 100, 'm' => 100, 'y' => 120, 'h' => 100, '?' => 100, 'years' => 120, 'months' => 100, 'weeks' => 100,
                        'days' => 100, 'hours' => 100 }.freeze
  VALID_DATE = /\A\d{1,2}[\s+\/\-][A-Za-z\d]{0,3}[\s+\/\-]\d{2,4}\z/.freeze #modern date no UCF or wildcard
  VALID_DAY = /\A\d{1,2}\z/.freeze
  VALID_MONTH = %w[JAN FEB MAR APR MAY JUN JUL AUG SEP SEPT OCT NOV DEC * JANUARY FEBRUARY MARCH APRIL MAY JUNE JULY AUGUST SEPTEMBER
                   OCTOBER NOVEMBER DECEMBER].freeze
  VALID_NUMERIC_MONTH = /\A\d{1,2}\z/.freeze
  VALID_YEAR = /\A\d{4,5}\z/.freeze
  DATE_SPLITS = { ' ' => /\s/, '-' => /\-/, '/' => /\\/ }.freeze
  WILD_CHARACTER = /[\*\[\]\-\_\?]/.freeze
  VALID_MARITAL_STATUS = %w[m s u w d -].freeze
  VALID_MARITAL_STATUS_PLUS = %w[ba md fd bd].freeze
  VALID_SEX = %w[M F -].freeze
  VALID_LANGUAGE = %w[E G GE I IE M ME W WE].freeze

  class << self
    def valid_piece?(field)
      return false if field.blank?

      parts = field.split('_')
      return false if parts.length == 1

      return false unless Freecen2Piece.valid_series?(parts[0])

      true
    end

    def valid_location?(field)
      return [false, 'blank'] if field.blank?

      unless field.match? NARROW_VALID_TEXT
        if field[-1] == '?' && (field.chomp('?').match? NARROW_VALID_TEXT)
          return [false, '?']
        else
          return [false, 'invalid text']
        end
      end

      [true, '']
    end

    def tight_location?(field)
      return [false, 'blank'] if field.blank?

      unless field.match? TIGHT_VALID_TEXT
        if field[-1] == '?' && (field.chomp('?').match? TIGHT_VALID_TEXT)
          return [false, '?']
        else
          return [false, 'invalid text']
        end
      end
      [true, '']
    end

    def valid_parish?(field)
      return [false, 'blank'] if field.blank?

      unless field.match? PARISH_TEXT
        if field[-1] == '?' && (field.chomp('?').match? PARISH_TEXT)
          return [false, '?']
        else
          return [false, 'invalid text']
        end
      end
      [true, '']
    end


    def enumeration_district?(field)
      return [false, 'blank'] if field.blank?

      if field[-1] == '?'
        strip_field = field[0...-1].strip
        return [false, '?'] if (strip_field.match? VALID_NUMBER) || (strip_field.match? VALID_ENUMERATOR_NUMBER_PLUS_SUFFIX1) || (strip_field.match? VALID_ENUMERATOR_NUMBER_PLUS_SUFFIX2)

        return [false, '?'] if (strip_field.match? VALID_ENUMERATOR_SPECIAL) && field[0] == '0'

      elsif (field.match? VALID_ENUMERATOR_SPECIAL) && field[0] == '0'
        return [true, ''] unless field[-1] == '0'

      elsif (field.match? VALID_NUMBER) || (field.match? VALID_ENUMERATOR_NUMBER_PLUS_SUFFIX1) || (field.match? VALID_ENUMERATOR_NUMBER_PLUS_SUFFIX2)
        return [true, '']
      end
      [false, 'invalid']
    end

    def valid_county_court_district?(field)
      return [false, 'blank'] if field.blank?

      unless field.match? NARROW_VALID_TEXT
        if field[-1] == '?' && (field.chomp('?').match? NARROW_VALID_TEXT)
          return [false, '?']
        else
          return [false, 'invalid text']
        end
      end
      [true, '']
    end

    def valid_petty_sessional_division?(field)
      return [false, 'blank'] if field.blank?

      unless field.match? NARROW_VALID_TEXT
        if field[-1] == '?' && (field.chomp('?').match? NARROW_VALID_TEXT)
          return [false, '?']
        else
          return [false, 'invalid text']
        end
      end
      [true, '']
    end


    def text?(field)
      return [true, ''] if field.blank?

      return [false, '?']  if field[-1] == '?'

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

      return [true, 'blank'] if field.blank?

      [false, 'invalid number']
    end

    def schedule_number?(field)
      return [true, ''] if field.present? && (field.match? VALID_NUMBER)

      return [true, ''] if field.present? && (field.match? VALID_NUMBER_PLUS_SUFFIX)

      return [true, ''] if field.present? && (field.match? DOUBLE_SCHEDULE)

      return [true, ''] if field.present? && (field.match? FRACTIONAL_SCHEDULE)

      return [false, 'blank'] if field.blank?

      [false, 'invalid number']
    end

    def house_number?(field)
      return [true, ''] if field.blank?

      return [true, ''] if field.present? && (field.match? HOUSE_NUMBER)

      [false, 'invalid number']
    end

    def house_address?(field)
      return [true, ''] if field.blank?

      unless field.match? BROAD_VALID_TEXT
        if field[-1] == '?' && (field.chomp('?').match? BROAD_VALID_TEXT)
          return [false, '?']
        else
          return [false, 'invalid text']
        end
      end

      [true, '']
    end

    def rooms?(field, year)
      return [true, ''] if field =~ VALID_NUMBER

      [false, 'invalid value']
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

      unless field.match? NARROW_VALID_TEXT
        if field[-1] == '?' && (field.chomp('?').match? NARROW_VALID_TEXT)
          return [false, '?']
        else
          return [false, 'invalid text']
        end
      end

      [true, '']
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

      unless field.match? BROAD_VALID_TEXT
        if field[-1] == '?' && (field.chomp('?').match? BROAD_VALID_TEXT)
          return [false, '?']
        else
          return [false, 'invalid text']
        end
      end

      [true, '']
    end

    def forenames?(field)
      return [false, 'blank'] if field.blank?

      unless field.match? BROAD_VALID_TEXT
        if field[-1] == '?' && (field.chomp('?').match? BROAD_VALID_TEXT)
          return [false, '?']
        else
          return [false, 'invalid text']
        end
      end
      [true, '']
    end

    def name_question?(field)
      return [true, ''] if field.blank?

      return [true, ''] if field.downcase == 'x'

      [false, 'invalid value']
    end

    def relationship?(field)
      return [true, ''] if field.blank?

      unless field.match? NARROW_VALID_TEXT
        if field[-1] == '?' && (field.chomp('?').match? NARROW_VALID_TEXT)
          return [false, '?']
        else
          return [false, 'invalid text']
        end
      end

      [true, '']
    end

    def marital_status?(field, year)
      return [true, ''] if field.blank?

      return [true, ''] if VALID_MARITAL_STATUS.include?(field.downcase) && field.length <= 1

      return [true, ''] if year == '1921' && VALID_MARITAL_STATUS_PLUS.include?(field.downcase) && field.length == 2


      return [false, '?']  if field[-1] == '?'

      [false, 'invalid value']
    end

    def sex?(field)
      return [false, 'blank'] if field.blank?

      return [true, ''] if VALID_SEX.include?(field.upcase) && field.length <= 1

      return [false, '?']  if field[-1] == '?'

      [false, 'invalid value']
    end

    def age?(field, martial, sex)
      return [false, 'blank'] if field.blank?

      return [false, '?'] if field[-1] == '?'

      return [false, 'Unusual Age 999'] if %w[999y 999Y].include?(field)

      return [false, 'Unusual Age 999'] if (field.match? VALID_NUMBER) && field.to_i == 999

      return [true, ''] if (field.match? VALID_NUMBER) && field.length <= 3 && field.to_i != 0 && field.to_i <= 120

      result, message = simple_period?(field) ? check_simple_period(field) : check_complex_period(field)
      if result
        message = 'invalid age, check age, marital status and sex fields'
        martial = martial.downcase if martial.present?
        sex = sex.downcase if sex.present?
        unit = field.slice(-1)
        stem = field[0...-1].to_i
        if simple_period?(field)
          return [false, message] if unit.casecmp('y').zero? && (stem < 14 || stem > 120) && %w[m w d].include?(martial) && %w[m -].include?(sex)

          return [false, message] if (field.match? VALID_NUMBER) && (stem < 14 || stem > 120) && %w[m w d].include?(martial) && %w[m -].include?(sex)

          return [false, message] if unit.casecmp('y').zero? && (stem < 12 || stem > 120) && %w[m w d].include?(martial) && sex == 'f'

          return [false, message] if (field.match? VALID_NUMBER) && (stem || stem > 120) && %w[m w d].include?(martial) && sex == 'f'

          message = ''
        else
          year = extract_year_from_complex(field)
          return [false, message] if (year < 14 || year > 120) && %w[m w d].include?(martial) && %w[m -].include?(sex)

          return [false, message] if (year < 12 || year > 120) && %w[m w d].include?(martial) && sex == 'f'

          message = ''
        end
      end
      [result, message]
    end

    def extract_year_from_complex(field)
      field_parts = field.split(' ')
      field_parts.each do |part|
        unit = part.slice(-1)
        stem = part[0...-1].to_i
        if unit.casecmp('y').zero?
          return stem
        else
          return 2
        end
      end
    end

    def school_children?(field)
      return [true, ''] if field =~ VALID_NUMBER

      [false, 'invalid number']
    end

    def years_married?(field)
      return [false, '?'] if field[-1] == '?'

      return [true, ''] if field =~ VALID_NUMBER && field.to_i < 100 && field.to_i >= 1

      result, message = simple_period?(field) ? check_simple_period(field) : check_complex_period(field)
      [result, message]
    end

    def simple_period?(field)
      result = field.split(' ').length > 1 ? false : true
      result
    end

    def check_simple_period(field)
      unit = field.slice(-1)
      stem = field[0...-1].to_i
      if unit.casecmp('y').zero? && stem > 0 && stem <= 120
        result = true
      elsif unit.casecmp('m').zero? && stem > 0 && stem <= 24
        result = true
      elsif unit.casecmp('w').zero? && stem > 0 && stem <= 20
        result = true
      elsif unit.casecmp('d').zero? && stem > 0 && stem <= 30
        result = true
      else
        result = false
      end
      message = result ? '' : 'invalid number'
      [result, message]
    end

    def check_complex_period(field)
      field_parts = field.split(' ')
      field_parts.each do |part|
        unit = part.slice(-1)
        stem = part[0...-1].to_i
        if unit.casecmp('y').zero? && stem >= 1 && stem <= 99
          @part_valid = true
        elsif unit.casecmp('m').zero? && stem >= 1 && stem <= 12
          @part_valid = true
        elsif unit.casecmp('w').zero? && stem >= 1 && stem <= 4
          @part_valid = true
        elsif unit.casecmp('d').zero? && stem >= 1 && stem <= 7
          @part_valid = true
        else
          @part_valid = false
          break
        end
      end
      message = @part_valid ? '' : 'invalid number'
      [@part_valid, message]
    end

    def children_born_alive?(field)
      field = field.to_i
      return [false, 'is an unusual number'] if field >= 0 && field > 15

      return [true, ''] if field >= 0 && field <= 15

      [false, 'invalid number']
    end

    def children_living?(field)
      field = field.to_i
      return [false, 'is an unusual number'] if field >= 0 && field > 15

      return [true, ''] if field >= 0 && field <= 15

      [false, 'invalid number']
    end

    def children_deceased?(field)
      field = field.to_i
      return [false, 'is an unusual number'] if field >= 0 && field > 15

      return [true, ''] if field >= 0 && field <= 15

      [false, 'invalid number']
    end

    def children_under_sixteen?(field)
      field = field.to_i
      return [false, 'is an unusual number'] if field >= 0 && field > 10

      return [true, ''] if field >= 0 && field <= 10

      [false, 'invalid number']
    end

    def religion?(field)
      return [true, ''] if field.blank?

      unless field.match? NARROW_VALID_TEXT
        if field[-1] == '?' && (field.chomp('?').match? NARROW_VALID_TEXT)
          return [false, '?']
        else
          return [false, 'invalid text']
        end
      end

      [true, '']
    end

    def read_write?(field)
      return [true, ''] if field.blank?

      unless field.match? NARROW_VALID_TEXT
        if field[-1] == '?' && (field.chomp('?').match? NARROW_VALID_TEXT)
          return [false, '?']
        else
          return [false, 'invalid text']
        end
      end

      [true, '']
    end

    def uncertainty_status?(field)
      return [true, ''] if field.blank?

      return [true, ''] if field.downcase == 'x'

      [false, 'invalid value']
    end

    def education?(field)
      return [true, ''] if field.blank?

      return [true, ''] if field.length == 1 && ['w', 'p'].include?(field.downcase)

      [false, 'invalid text']
    end

    def occupation?(field, age)
      return [true, ''] if field.blank?

      if age.present?

        return [false, 'unusual use of Scholar'] if age =~ VALID_NUMBER && (age.to_i < 2 || age.to_i > 17) && field.downcase =~ /(scholar)/

        return [false, 'unusual use of Scholar'] if age.slice(-1).downcase == 'y' && (age[0...-1].to_i < 2 || age[0...-1].to_i > 17) && field.downcase =~ /(scholar)/

        return [false, 'unusual use of Scholar'] if %w[m w d].include?(age.slice(-1).downcase) && field.downcase =~ /(scholar)/

      end

      return [false, '?'] if field[-1] == '?'

      [true, '']
    end

    def employment?(field)
      return [true, ''] if field.blank?

      unless field.match? NARROW_VALID_TEXT
        if field[-1] == '?' && (field.chomp('?').match? NARROW_VALID_TEXT)
          return [false, '?']
        else
          return [false, 'invalid text']
        end
      end

      [true, '']
    end

    def place_of_work(field)
      return [true, ''] if field.blank?

      unless field.match? NARROW_VALID_TEXT
        if field[-1] == '?' && (field.chomp('?').match? NARROW_VALID_TEXT)
          return [false, '?']
        else
          return [false, 'invalid text']
        end
      end

      [true, '']
    end

    def industry?(field)
      return [true, ''] if field.blank?

      unless field.match? BROAD_VALID_TEXT
        if field[-1] == '?' && (field.chomp('?').match? BROAD_VALID_TEXT)
          return [false, '?']
        else
          return [false, 'invalid text']
        end
      end

      [true, '']
    end

    def occupation_category?(field)
      return [true, ''] if field.blank?

      return [true, ''] if field.length == 1 && ['e', 'r', 'n'].include?(field.downcase)

      [false, 'invalid value']
    end

    def at_home?(field)
      return [true, ''] if field.downcase == 'h' && field.length == 1

      return [true, ''] if field.downcase == 'at home' && field.length == 7

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

      return [true, ''] if %w[ENG SCT IRL WLS CHI].include?(field.upcase)

      [false, 'invalid value']
    end

    def verbatim_birth_place?(field)
      return [false, 'blank'] if field.blank?

      unless field.match? BROAD_VALID_TEXT
        if field[-1] == '?' && (field.chomp('?').match? BROAD_VALID_TEXT)
          return [false, '?']
        else
          return [false, 'invalid text']
        end
      end

      [true, '']
    end

    def birth_place?(field)
      return [false, 'blank'] if field.blank?

      unless field.match? BROAD_VALID_TEXT
        if field[-1] == '?' && (field.chomp('?').match? BROAD_VALID_TEXT)
          return [false, '?']
        else
          return [false, 'invalid text']
        end
      end

      [true, '']
    end

    def nationality?(field)
      return [true, ''] if field.blank?

      unless field.match? NARROW_VALID_TEXT
        if field[-1] == '?' && (field.chomp('?').match? NARROW_VALID_TEXT)
          return [false, '?']
        else
          return [false, 'invalid text']
        end
      end

      [true, '']
    end

    def father_place_of_birth?(field)
      return [true, ''] if field.blank?

      unless field.match? BROAD_VALID_TEXT
        if field[-1] == '?' && (field.chomp('?').match? BROAD_VALID_TEXT)
          return [false, '?']
        else
          return [false, 'invalid text']
        end
      end

      [true, '']
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

      unless field.match? BROAD_VALID_TEXT
        if field[-1] == '?' && (field.chomp('?').match? BROAD_VALID_TEXT)
          return [false, '?']
        else
          return [false, 'invalid text']
        end
      end

      [true, '']
    end

    def disability_notes?(field)
      return [true, ''] if field.blank?

      unless field.match? BROAD_VALID_TEXT
        if field[-1] == '?' && (field.chomp('?').match? BROAD_VALID_TEXT)
          return [false, '?']
        else
          return [false, 'invalid text']
        end
      end

      [true, '']
    end

    def notes?(field)
      return [true, ''] if field.blank?

      return [false, 'invalid text'] unless field.match? BROAD_VALID_TEXT_PLUS

      [true, '']
    end
  end
end
