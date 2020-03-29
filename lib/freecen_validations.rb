module FreecenValidations

  VALID_UCF = /[\}\{\?\*\_\]\[\,]/
  VALID_NAME = /[\w\'\"\ \.\;\:]/
  VALID_NUMERIC = /\d/
  VALID_NUMBER  = /\A\d+\z/
  VALID_NUMBER_PLUS_SUFFIX = /\A\d+\D\z/
  VALID_ENUMERATOR_SPECIAL = /\A\d#\d\z/
  VALID_SPECIAL_LOCATION_CODES = ['b', 'n', 'u', 'v', 'x', '']
  VALID_TEXT = /(\w*|-)/
  VALID_PIECE = /\A(R|H)(G|O|S)/i
  VALID_AGE_MAXIMUM = {'d' => 100, 'w' => 100 , 'm' => 100 , 'y' => 120 , 'h' => 100, '?' => 100, 'years' => 120, 'months' => 100, 'weeks' => 100, 'days' => 100, 'hours' => 100}
  VALID_DATE = /\A\d{1,2}[\s+\/\-][A-Za-z\d]{0,3}[\s+\/\-]\d{2,4}\z/ #modern date no UCF or wildcard
  VALID_DAY = /\A\d{1,2}\z/
  VALID_MONTH = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP","SEPT", "OCT", "NOV", "DEC", "*","JANUARY","FEBRUARY","MARCH","APRIL","MAY","JUNE","JULY","AUGUST","SEPTEMBER","OCTOBER","NOVEMBER","DECEMBER"]
  VALID_NUMERIC_MONTH = /\A\d{1,2}\z/
  VALID_YEAR = /\A\d{4,5}\z/
  DATE_SPLITS = {
    " " => /\s/,
    "-" => /\-/,
  "/" => /\\/}
  WILD_CHARACTER = /[\*\[\]\-\_\?]/
  VALID_MARITAL_STATUS = ['m', 's', 'u', 'w', '-']
  VALID_SEX = ['M', 'F', '-']

  def FreecenValidations.fixed_valid_piece?(field)
    return false if field.blank?

    return false unless field =~ VALID_TEXT

    return false unless field =~ VALID_PIECE

    true
  end

  def FreecenValidations.fixed_valid_civil_parish?(field)
    return [false, 'blank'] if field.blank?

    return [false, 'VALID_TEXT'] unless field =~ VALID_TEXT

    [true, '']
  end

  def FreecenValidations.fixed_enumeration_district?(field)
    return [true, ''] if field.blank?

    return [true, ''] if field =~ VALID_NUMBER

    return [true, ''] if field =~ VALID_NUMBER_PLUS_SUFFIX

    return [true, ''] if field =~ VALID_ENUMERATOR_SPECIAL

    [false, 'invalid']
  end

  def FreecenValidations.fixed_folio_number?(field)
    return [true, ''] if field.blank?

    return [true, ''] if field =~ VALID_NUMBER && field.length <= 4
    shorten_field = field
    shorten_field = field.slice(0..-2) if (/\D/ =~ field.slice(-1, 1)).present?
    return [true, ''] if shorten_field =~ VALID_NUMBER && shorten_field.length <= 4

    [false, 'invalid number']
  end

  def FreecenValidations.fixed_page_number?(field)
    return [true, ''] if field =~ VALID_NUMBER && field.length <= 4

    [false, 'invalid number']
  end

  def FreecenValidations.fixed_schedule_number?(field)
    return [true, ''] if field.present? && field =~ VALID_NUMBER

    return [true, ''] if field.present? && field =~ VALID_NUMBER_PLUS_SUFFIX

    return [false, 'blank'] if field.blank?

    [false, 'invalid number']
  end

  def FreecenValidations.fixed_house_number?(field)
    return [true, ''] if field.present? && field =~ VALID_NUMBER

    return [true, ''] if field.present? && field =~ VALID_NUMBER_PLUS_SUFFIX

    return [true, ''] if field.blank?

    [false, 'invalid number']
  end

  def FreecenValidations.fixed_house_address?(field)
    return [false, '?'] if field.present? && field.slice(-1).downcase == '?' && field =~ VALID_TEXT

    return [true, ''] if field.present? && field =~ VALID_TEXT

    return [false, 'blank'] if field.blank?

    [false, 'invalid address']
  end

  def FreecenValidations.fixed_uninhabited_flag?(field)
    return [true, ''] if field.blank?

    return [true, ''] if VALID_SPECIAL_LOCATION_CODES.include?(field.downcase)

    [false, 'invalid value']
  end

  def FreecenValidations.fixed_surname?(field)
    return [false, 'blank'] if field.blank?

    return [false, '?'] if field.present? && field.slice(-1).downcase == '?' && field =~ VALID_TEXT

    return [true, ''] if field =~ VALID_TEXT

    [false, 'invalid value']
  end

  def FreecenValidations.fixed_forenames?(field)
    return [false, 'blank'] if field.blank?

    return [false, '?'] if field.present? && field.slice(-1).downcase == '?' && field =~ VALID_TEXT

    return [true, ''] if field =~ VALID_TEXT

    [false, 'invalid value']
  end

  def FreecenValidations.fixed_name_question?(field)
    return [true, ''] if field.blank?

    return [true, ''] if field =~ VALID_TEXT

    [false, 'invalid value']
  end

  def FreecenValidations.fixed_relationship?(field)
    return [false, 'blank'] if field.blank?

    return [true, ''] if field =~ VALID_TEXT

    [false, 'invalid value']
  end

  def FreecenValidations.fixed_marital_status?(field)
    return [true, ''] if field.blank?

    return [true, ''] if VALID_MARITAL_STATUS.include?(field.downcase) && field.length <= 1

    [false, 'invalid value']
  end

  def FreecenValidations.fixed_sex?(field)
    return [false, 'blank'] if field.blank?

    return [true, ''] if VALID_SEX.include?(field.upcase) && field.length <= 1

    [false, 'invalid value']
  end

  def FreecenValidations.fixed_age?(field, martial, sex)
    return [false, 'blank'] if field.blank?

    return [true, ''] if field =~ VALID_NUMBER && field.length <= 3 && field.to_i != 0 && field.to_i <= 120

    return [true, ''] if field.slice(-1).downcase == 'y'  && field[0...-1].to_i >= 14 && field[0...-1].to_i <= 120 && ['m', 'w'].include?(martial) && ['M', '-'].include?(sex)

    return [true, ''] if field.slice(-1).downcase == 'y'  && field[0...-1].to_i >= 12 && field[0...-1].to_i <= 120 && ['m', 'w'].include?(martial) && sex == 'F'

    return [true, ''] if field.slice(-1).downcase == 'y'  && field[0...-1].to_i > 0 && field[0...-1].to_i <= 120 && ['s', 'u', '-'].include?(martial)

    return [true, ''] if field.slice(-1).downcase == 'm'  && field[0...-1].to_i != 0 && field[0...-1].to_i <= 24

    return [true, ''] if field.slice(-1).downcase == 'w'  && field[0...-1].to_i != 0 && field[0...-1].to_i <= 20

    return [true, ''] if field.slice(-1).downcase == 'd'  && field[0...-1].to_i != 0 && field[0...-1].to_i <= 30

    [false, 'invalid value, check age, marital status and sex fields']
  end

  def FreecenValidations.fixed_uncertainty_status?(field)
    return [true, ''] if field.blank?

    return [true, ''] if field.downcase == 'x'

    [false, 'invalid value']
  end

  def FreecenValidations.fixed_occupation?(field, age)
    return [true, ''] if field.blank?

    return [false, 'invalid use of Scholar'] if age =~ VALID_NUMBER && (age.to_i < 2 || age.to_i > 17) && field.downcase =~ /(scholar)/

    return [false, 'invalid use of Scholar'] if age.slice(-1).downcase == 'y' && (age[0...-1].to_i < 2 || age[0...-1].to_i > 17) && field.downcase =~ /(scholar)/

    return [false, '?'] if field.slice(-1).downcase == '?'

    return [true, '']

  end

  def FreecenValidations.fixed_occupation_category?(field)
    return [true, ''] if field.blank?

    return [true, ''] if field.length == 1 && ['e', 'r', 'n'].include?(field.downcase)

    [false, 'invalid value']
  end

  def FreecenValidations.fixed_uncertainty_occupation?(field)
    return [true, ''] if field.blank?

    return [true, ''] if field.downcase == 'x'

    [false, 'invalid value']
  end
  def FreecenValidations.fixed_verbatim_birth_county?(field)
    return [false, 'blank'] if field.blank?

    return [true, ''] if ChapmanCode.freecen_birth_codes.include?(field.upcase)

    [false, 'invalid value']
  end

  def FreecenValidations.fixed_verbatim_birth_place?(field)
    return [false, 'blank'] if field.blank?

    return [true, ''] if field =~ VALID_TEXT

    [false, 'invalid value']
  end
  def FreecenValidations.fixed_uncertainy_birth?(field)
    return [true, ''] if field.blank?

    return [true, ''] if field.downcase == 'x'

    [false, 'invalid value']
  end

  def FreecenValidations.fixed_language?(field)
    return [true, ''] if field.blank?

    return [true, ''] if ['w', 'e', 'g', 'b'].include?(field.downcase)

    [false, 'invalid value']
  end

  def FreecenValidations.fixed_disability?(field)
    return [true, ''] if field.blank?

    return [true, ''] if field =~ VALID_TEXT

    [false, 'invalid value']
  end

  def FreecenValidations.fixed_notes?(field)
    return [true, ''] if field.blank?

    return [true, ''] if field =~ VALID_TEXT

    [false, 'invalid value']
  end
  def FreecenValidations.at_home?(field)
    return [true, ''] if field.blank?

    return [true, ''] if field.downcase == 'h' && field.length == 1

    return [true, ''] if field.downcase == 'at home' && field.length == 7

    [false, 'invalid value']
  end
  def FreecenValidations.rooms?(field, year)
    return [true, ''] if field.blank?

    return [true, ''] if field =~ VALID_NUMBER && year == '1901' && field.to_i <= 5

    return [true, ''] if field =~ VALID_NUMBER && year == '1911' && field.to_i <= 19

    [false, 'invalid value']

  end
end
