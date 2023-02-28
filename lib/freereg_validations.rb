module FreeregValidations

  VALID_UCF = /[\}\{\?\*\_\]\[\,]/
  VALID_NAME =/[\p{L}\'\"\ \.\;\:]/
  VALID_NUMERIC  = /[\p{N}]/
  VALID_TEXT = /[\p{C}\p{P}p{N}\p{S}]/
  VALID_CREDIT = /@+/
  VALID_AGE_WORDS = ["infant", "child", "minor", "of age","full age","of full age","above", "over", "+"]
  VALID_AGE_MAXIMUM = {'d' => 100, 'w' => 100 , 'm' => 100 , 'y' => 120 , 'h' => 100, '?' => 100, 'years' => 120, 'months' => 100, 'weeks' => 100, 'days' => 100, 'hours' => 100}
  VALID_AGE_TYPE1 = /\A\d{1,3}\z/
  VALID_AGE_TYPE2 = /^(\d{1,3})([hdwmy\*\[\]\-\_\?])/
  VALID_AGE_TYPE2A = /^(\d{1,3})(years)/
  VALID_AGE_TYPE2B = /^(\d{1,3})(months)/
  VALID_AGE_TYPE2C = /^(\d{1,3})(days)/
  VALID_AGE_TYPE2D = /^(\d{1,3})(weeks)/
  VALID_AGE_TYPE2E = /^(\d{1,3})(hours)/
  VALID_AGE_TYPE3 =  /^(\d{1,3})([hdwmy\*\[\]\-\_\?])(\d{1,2})([hdwmy\*\[\]\-\_\?])/
  VALID_AGE_TYPE4 = /\A [[:xdigit:]] \z/
  #\A\d{1,2}[\s+\/][A-Za-z\d]{0,3}[\s+\/]\d{2,4}\/?\d{0,2}?\z checks 01 mmm 1567/8
  #\A[\d{1,2}\*\-\?][\s+\/][A-Za-z\d\*\-\?]{0,3}[\s+\/][\d\*\-\?]{0,4}\/?[\d\*\-\?]{0,2}?\z
  VALID_DATE = /\A\d{1,2}[\s+\/\-][A-Za-z\d]{0,3}[\s+\/\-]\d{2,4}\z/ #modern date no UCF or wildcard
  VALID_DAY = /\A(\d*|_)(\d|_)\z/
  VALID_MONTH = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec *].freeze
  VALID_NUMERIC_MONTH = /\A\d{1,2}\z/
  VALID_YEAR = /\A\d{4,5}\z/
  DATE_SPLITS = {
    " " => /\s/,
    "-" => /\-/,
  "/" => /\\/}
  WILD_CHARACTER = /[\*\[\]\-\_\?]/
  YEAR_MAX = Date.today.year
  YEAR_MIN = 1300
  VALID_MALE_SEX = ["M","M." ,"SON","MALE","MM","SON OF"]
  UNCERTAIN_MALE_SEX = ["M?","SON?","[M]" ,"MF"]
  UNCERTAIN_FEMALE_SEX = ["F?", "DAU?"]
  UNCERTAIN_SEX = ["?", "-", "*","_","??",""," "]
  VALID_FEMALE_SEX = ["F","FF","FFF","FM","F.","FEMALE","DAUGHTER","WIFE","DAUGHTER OF","DAU", "DAU OF"]
  VALID_MARRIAGE_CONDITIONS = {
    'Singleman' => 'Single Man',
    'Singlaman' => 'Single Man',
    'Singlewoman' => 'Single Woman',
    'Singl Woman' => 'Single Woman',
    'Single Person' => 'Single',
    'Virgine' => 'Virgin',
    'Bach' => 'Bachelor',
    'Bac' => 'Bachelor',
    'Bch' => 'Bachelor',
    'Batchelor' => 'Bachelor',
    'Batcher' => 'Bachelor',
    'Bachelore' => 'Bachelor',
    'B' => 'Bachelor',
    'Sing' => 'Single',
    'Spin' => 'Spinster',
    'Spin.' => 'Spinster',
    'Spiinster' => 'Spinster',
    'Spinister' => 'Spinster',
    'Spinspter' => 'Spinster',
    'Maiden and Spinster' => 'Spinster',
    'Maiden' => 'Spinster',
    'Single Woman and Spinster' => 'Spinster',
    'Minor and Spinster' => 'Spinster',
    'Spinster and Minor' => 'Spinster',
    'Spinster Minor' => 'Spinster',
    'Sp' => 'Spinster',
    'Spr' => 'Spinster',
    'Singl' => 'Single',
    'S' => 'Single',
    'Wid' => 'Widowed',
    'Wid.' => 'Widowed',
    'Widw' => 'Widow',
    'Widdow' => 'Widow',
    'A Widowe' => 'Widow',
    'Spinster Widow' => 'Widow',
    'Widowe' => 'Widow',
    'Wido' => 'Widow',
    'Br Widow' => 'Widow',
    'Widower [sic]' => 'Widower',
    'Widdower' => 'Widower',
    'Widwr' => 'Widower',
    'Widr' => 'Widower',
    'Wdr' => 'Widower',
    'W' => 'Widowed',
    'Relict' => 'Widow',
    'Jun' => 'Minor',
    'A Minor' => 'Minor',
    '*' => '*',
    '?' => '*',
    'Divorcee' => "Divorcee",
  'Juvenis' => 'Minor'}


  def FreeregValidations.cleantext(field)
    #not convinced this code is effective or needed
    return true if field.nil? || field.empty?
    return true if field =~ VALID_TEXT
    return true
  end
  def FreeregValidations.cleancredit(field)
    return true if field.nil? || field.empty?
    return false if field =~ VALID_CREDIT
    return true
  end
  def FreeregValidations.cleanname(field)

    #not convinced this code is effective or needed
    return true if field.nil? || field.empty?
    return false unless field =~ VALID_NAME || field =~ VALID_UCF
    return true
  end
  def FreeregValidations.cleannumeric(field)
    #not convinced this code is effective or needed
    return true if field.nil? || field.empty?
    return true if field =~ VALID_UCF
    return true if field =~ WILD_CHARACTER

    return true if (field =~ VALID_NUMERIC || field =~ VALID_NAME)

    return false
  end
  #clean up the age field
  # check that the age is in one of several acceptable formats - infant
  # 1d (day), 2w (week), 3m (month), 2y5m (2 years, 5 months), or - for 'no age'
  # max 30d, 30w, 30m and 150y
  def FreeregValidations.cleanage(field)

    #the planning team requested this code be deactivated for burials
    return true if field.nil? || field.empty?
    return true if field =~ VALID_UCF
    return true if field =~ WILD_CHARACTER
    return false unless FreeregValidations.cleannumeric(field)

    #test for valid words
    return true if VALID_AGE_WORDS.include?(Unicode::downcase(field))
    #test for straight years
    case

    when field =~ VALID_AGE_TYPE1
      return true unless field.to_i > VALID_AGE_MAXIMUM["y"]
      return false

      #permit the n(hdwmy)
    when field.downcase.gsub(' ','') =~ VALID_AGE_TYPE2 || field.downcase.gsub(' ','') =~ VALID_AGE_TYPE2A || field.downcase.gsub(' ','') =~ VALID_AGE_TYPE2B ||
        field.downcase.gsub(' ','') =~ VALID_AGE_TYPE2C ||  field.downcase.gsub(' ','') =~ VALID_AGE_TYPE2D ||  field.downcase.gsub(' ','') =~ VALID_AGE_TYPE2E
      duration = $1.to_i

      unit = $2.to_s

      p field unless VALID_AGE_MAXIMUM.has_key?(unit)
      return true unless duration > VALID_AGE_MAXIMUM[unit]
      return false

      #permit the n(dwmy) m(dwmy)
    when field =~ VALID_AGE_TYPE3

      duration1 = $1.to_i
      unit1 = $2.to_s
      duration2 = $1.to_i
      unit2 = $2.to_s
      p field unless VALID_AGE_MAXIMUM.has_key?(unit1)
      p field unless VALID_AGE_MAXIMUM.has_key?(unit2)
      return true unless duration1 > VALID_AGE_MAXIMUM[unit1]
      return true unless duration2 > VALID_AGE_MAXIMUM[unit2]
      return false
    when  field =~ VALID_AGE_TYPE4

      #permit the vulgar fractions
      return true

    else
      return false
    end
  end



  def  FreeregValidations.cleansex(field)
    case
    when field.nil?
      return true
    when UNCERTAIN_SEX.include?(field.upcase)
      return true
    when VALID_MALE_SEX.include?(field.upcase)
      return true
    when UNCERTAIN_MALE_SEX.include?(field.upcase)
      return true
    when VALID_FEMALE_SEX.include?(field.upcase)
      return true
    when UNCERTAIN_FEMALE_SEX.include?(field.upcase)
      return true
    when field =~ VALID_UCF
      return true
    else
      return false
    end
  end

  def FreeregValidations.cleancondition(field)
    return true if field.nil? || field.empty?
    field = field.capitalize
    field = VALID_MARRIAGE_CONDITIONS[field] if VALID_MARRIAGE_CONDITIONS.has_key?(field)
    return true if VALID_MARRIAGE_CONDITIONS.has_value?(field)
    return false
  end

  def FreeregValidations.birth_date_less_than_baptism_date(birth,baptism)
    return true if birth.nil? || birth =~ VALID_UCF || birth =~ WILD_CHARACTER || baptism.nil? || baptism =~ VALID_UCF || baptism =~ WILD_CHARACTER
    birth_days = Freereg1CsvFile.convert_date(birth)
    baptism_days = Freereg1CsvFile.convert_date(baptism)
    if birth_days <= baptism_days
      return true
    else
      return false
    end
  end

  def FreeregValidations.cleandate(field)
    return true if field.nil? || field.empty?

    a = field.split(' ')
    case
    when a.length == 3
      # work with  dd Mmm yyyy/y
      # firstly deal with the dd and allow the wild character
      return false unless a[0].to_s =~ VALID_DAY || a[0] == '*'

      if a[0] =~ /\A\d{1,2}\z/
        return false if a[0].to_i > 31 || a[0].to_i <= 0
      end
      # deal with the month allowing for the wild character
      return false unless VALID_MONTH.include?(a[1]) || a[1] == '*'

      # deal with the year and split year
      check = FreeregValidations.check_year(a[2])
      return check

    when a.length == 2
      # deal with dates that are mmm yyyy firstly the Mmm then the split year
      return false unless VALID_MONTH.include?(a[0]) || a[0] == '*'

      check = FreeregValidations.check_year(a[1])
      return check

    when a.length == 1
      # deal with dates that are year only
      check = FreeregValidations.check_year(a[0])
      return check

    else
      p 'unknown date format'
      return false
    end
  end

  def self.check_year(yyyy)
    return true if yyyy == '*' || yyyy =~ /\d{2}\*/ || yyyy =~ /\d{3}_/ || yyyy =~ /\d{2}_{1}/ || yyyy =~ /\d{4}\?/

    characters = yyyy.split('')
    if characters.length == 4
      # deal with the yyyy and permit the wild character

      if yyyy.present?
        return false if yyyy.to_i > YEAR_MAX || YEAR_MIN > yyyy.to_i
      end
      return true
    end
    if (characters.length >= 6 && characters.length <= 9) && characters[4] == "/"
      #deal with the split year
      year = characters
      last = 2
      last = 3 if characters.length == 7
      last = 4 if characters.length == 8
      last = 5 if characters.length == 9
      year = characters.reverse.drop(last).reverse.join
      ext = characters.drop(5).join
      return false unless year.to_s =~ VALID_YEAR

      return false if year.to_i > YEAR_MAX || 1753 < year.to_i

      return false if ext.to_i < 0 || ext.to_i > 1753

      return true
    else
      p 'greater than 9 digits and character position 5 was not / '
      return false
    end
  end

  def FreeregValidations.year_extract(field)
    if field.blank?
      year = nil
      return
    else
      a = field.split(" ")
      case
      when a.length == 3
        year = a[2]
      when a.length == 2
        year = a[1]
      when a.length == 1
        year = a[0]
      end #end case
      if year.present? && year.length > 4
        year = year[0..-(year.length-3)]
      end #end if
    end #end if
    year = nil if year.to_s =~ VALID_UCF
    year
  end


  def FreeregValidations.modern_date_valid?(field)
    # determines if the modern date of creation or modification is valid
    return true if field.blank?
    if  field =~ VALID_DATE
      DATE_SPLITS.each_pair do |date_splitter, date_split|
        date_parts = field.split(date_split)
        unless date_parts[1].nil?
          return true if VALID_MONTH.include?(date_parts[1].titleize) || date_parts[1] =~ VALID_NUMERIC_MONTH
        end
      end
    end
    return false
  end

  def FreeregValidations.valid_chapman_code?(field)
    return true if ChapmanCode::values.include?(field) &&
      !FreeregOptionsConstants::CHAPMAN_CODE_ELIMINATIONS.include?(ChapmanCode.has_key(field))
  end

  def FreeregValidations.valid_place?(field,chapman)
    field = field.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase unless field.blank?
    place = Place.chapman_code(chapman).modified_place_name(field).not_disabled.first
    return false unless place.present?
    return true
  end

  def FreeregValidations.valid_church?(church_name,chapman_code,place_name)
    place = Place.chapman_code(chapman_code).place(place_name).not_disabled.first
    place.churches.each do |church|
      if church.church_name.downcase == church_name.downcase
        return true
      end
    end
    return false
  end
end
