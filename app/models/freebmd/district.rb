class District < FreebmdDbBase
  self.table_name = 'Districts'
  has_many :DistrictToCounty, foreign_key: :DistrictNumber
  has_many :records, foreign_key: :DistrictNumber, class_name: '::BestGuess'
  scope :not_invented, -> { where(Invented: 0) }
  require 'record_type'
  DEFAULT_TYPE = 'birth'
  UNIQ_NAME_TYPE= '1'

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

  def district_friendly_url
    particles = []
    # first the primary names
    particles << self.DistrictName if self.DistrictName

    friendly = "details-of-#{particles.join('-')}-district"
    friendly.gsub!(/\W/, '-')
    friendly.gsub!(/-+/, '-')
    friendly.downcase!
  end

  def self.fetch_uniq_names params_hash
    self.clean_uniq_name_param_hash params_hash
    record_type = params_hash[:record_type]
    record_type_id = RecordType::FREEBMD_OPTIONS[record_type.upcase]
    name_type = params_hash[:name_type]
    district_number = params_hash[:id]
    district = District.where(DistrictNumber: district_number).first
    name_doc = DistrictUniqueName.where(district_number: district_number, record_type: record_type_id).first
    unique_names = name_type == '0' ? name_doc.unique_surnames : name_doc.unique_forenames
    unique_names, remainders = district.letterize(unique_names)
    [record_type, name_type, district, unique_names, remainders]
  end

  private

  def self.clean_uniq_name_param_hash params_hash
    params_hash[:record_type] ||= DEFAULT_TYPE
    params_hash[:name_type] ||= UNIQ_NAME_TYPE
    params_hash
  end
end