class District < FreebmdDbBase
  self.table_name = 'Districts'
  has_many :DistrictToCounty, foreign_key: :DistrictNumber
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
    InfoBookmark.present? && InfoBookmark != "xxxx"
  end

  def format_district_name
    gsub(/(?<=\S) *\(.*\) *$/,'')
  end

  def ukbmd_url_distict
    district_name = format_district_name
    district_suffix = '1'
    district_name = district_name.gsub(/&/,"and")
    district_name = district_name.gsub(/ /,"-") if InfoBookmark == "dash"
    district_name = district_name.gsub(/upon/,"on") if InfoBookmark == "upon"
    district_name = district_name.gsub(/ [A-Za-z]*$/,"") if InfoBookmark == "trnc"
    district_name = district_name.gsub(/ [A-Za-z]*$/,district_suffix) if InfoBookmark.match?(/sfx[0-9]/)
    district_name = InfoBookmark unless InfoBookmark.match?(/aaaa|dash|upon|trnc|sfx[0-9]/)
    district_name = district_name.gsub(/ /,"%20")
    district_name
  end
end