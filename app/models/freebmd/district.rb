class District < FreebmdDbBase
  self.table_name = 'Districts'
  has_many :DistrictToCounty, foreign_key: :DistrictNumber
  has_many :DistrictPseudonym, foreign_key: :DistrictNumber
  has_many :records, foreign_key: :DistrictNumber, class_name: '::BestGuess'
  scope :not_invented, -> { where(Invented: 0) }

  def letterize(names)
    new_list = {}
    remainder = names
    ("A".."Z").each do |letter|
      new_list[letter] = select_elements_starting_with(names, letter)
      remainder -= new_list[letter]
    end
    [new_list, remainder]
  end

  def select_elements_starting_with(arr, letter)
    arr.select { |str| str.start_with?(letter) }
  end

  def district_url_definable?
    self.InfoBookmark.present? && self.InfoBookmark != "xxxx"
  end

  def format_district_name
    self.DistrictName.gsub(/(?<=\S) *\(.*\) *$/,'')
  end

  def ukbmd_url_distict
    district_name = format_district_name
    district_suffix = '1'
    district_name = district_name.gsub(/&/,"and")
    district_name = district_name.gsub(/ /,"-") if self.InfoBookmark == "dash"
    district_name = district_name.gsub(/upon/,"on") if self.InfoBookmark == "upon"
    district_name = district_name.gsub(/ [A-Za-z]*$/,"") if self.InfoBookmark == "trnc"
    district_name = district_name.gsub(/ [A-Za-z]*$/,district_suffix) if self.InfoBookmark.match?(/sfx[0-9]/)
    district_name = self.InfoBookmark unless self.InfoBookmark.match?(/aaaa|dash|upon|trnc|sfx[0-9]/)
    district_name = district_name.gsub(/ /,"%20")
    district_name
  end

  def district_name_display_format
    district_name = format_district_name
    district_suffix = '1'
    district_name = district_name.gsub(/&/,"and")
    district_name = district_name.gsub(/upon/,"on") if self.InfoBookmark == "upon"
    district_name = district_name.gsub(/ [A-Za-z]*$/,"") if self.InfoBookmark == "trnc"
    district_name = district_name.gsub(/ [A-Za-z]*$/,district_suffix) if self.InfoBookmark.match?(/sfx[0-9]/)
    district_name = self.InfoBookmark unless self.InfoBookmark.match?(/aaaa|dash|upon|trnc|sfx[0-9]/)
    district_name
  end

  def district_name_as_filename
    self.DistrictName.gsub(/ /, "_")
  end
  
  def district_name_no_spaces(suffix)
    district_name = self.DistrictName.gsub(/\W/, "_")
    district_name.gsub!(/_+/, '_')
    district_name+'.'+suffix
  end

  def district_friendly_url
    particles = []
    # first the primary names
    particles << self.DistrictName if self.DistrictName

    friendly = "details-of-#{particles.join('-')}-district"
    friendly.gsub!(/\W/, '-')
    friendly.gsub!(/-+/, '-')
    friendly.downcase!
  end

  def District.districts_as_array
    @all_districts = District.not_invented.all
    options = []
    @all_districts.each do |district|
      options << district.DistrictName
    end
    options
  end
  def District.districts_as_hash
    @all_districts = District.not_invented.all
    hash = {}
    @all_districts.each do |district|
      hash[district.DistrictName] = district.DistrictNumber
    end
    hash
  end

  def valid_start district
    valid_start = ''
    if district.YearStart && !(district.YearStart == 1837 && district.QuarterStart == 3)
      district.QuarterStart == 3 ? quarter = '' : quarter = QuarterDetails.quarters.index(district.QuarterStart) 
      valid_start = "#{quarter.to_s.titlecase} #{district.YearStart}"
    end
  end

  def valid_end district
    valid_end = ''
    if district.YearEnd && !(district.YearEnd == 9999 && district.QuarterEnd == 9)
      district.QuarterEnd == 4 ? quarter = '' : quarter = QuarterDetails.quarters.index(district.QuarterEnd)
      valid_end = "#{quarter.to_s.titlecase} #{district.YearEnd}"
    end
  end

  def district_validity_period district
    case
    when valid_start(district).present? && !valid_end(district).present?
      "(from #{valid_start(district)})"
    when !valid_start(district).present? && valid_end(district).present?
      "(to #{valid_end district})"
    when valid_start(district).present? && valid_end(district).present?
      "(#{valid_start(district)} - #{valid_end(district)})"
    else
      "" 
    end
  end

  def formatted_name_for_search district
    logger.warn(clean(district.DistrictName))
    "#{clean(district.DistrictName)} #{district.district_validity_period district}"
  end

  def valid?
    !(self.YearStart == 9999) && !(self.QuarterEnd == 9)
  end

  def clean name
    return '' unless name.present?

    name.gsub(/[\[\(\{].*?[\]\)\}]/, '')
         .gsub(/\s+/, ' ')
         .strip
  end

end