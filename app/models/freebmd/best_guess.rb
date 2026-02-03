# Entry Information
class BestGuess < FreebmdDbBase
  require 'application_text'
  self.pluralize_table_names = false
  self.table_name = 'BestGuess'
  has_one :best_guess_maariages, class_name: '::BestGuessMarriage', foreign_key: 'RecordNumber'
  has_one :best_guess_hash, class_name: '::BestGuessHash', foreign_key: 'RecordNumber'

  belongs_to :CountyCombos, foreign_key: 'CountyComboID', primary_key: 'CountyComboID', class_name: '::CountyCombo'
  belongs_to :district, foreign_key: 'DistrictNumber', primary_key: 'DistrictNumber', class_name: '::District'
  has_many :ScanLinks, primary_key: 'ChunkNumber', foreign_key: 'ChunkNumber'
  has_many :best_guess_links, class_name: '::BestGuessLink', foreign_key: 'RecordNumber' #, primary_key: ['RecordNumber', 'AccessionNumber', 'SequenceNumber']
  scope :birth_records,   -> { where(RecordTypeID: 1) }
  scope :death_records,   -> { where(RecordTypeID: 2) }
  scope :marriage_records,   -> { where(RecordTypeID: 3) }
  extend SharedSearchMethods
  require 'security_hash'

  ENTRY_SYSTEM = 8
  ENTRY_LINK = 256
  ENTRY_REFERENCE = 512
  DISTRICT_ALIAS = 1
  DISTRICT_MISSPELT = 2
  DISTRICT_UNKNOWN = 4
  BAD_VOLUME_FOR_DISTRICT = 8
  BAD_DATE_FOR_DISTRICT = 16
  PAGE_OUTSIDE_EXECTED_RANGE_FOR_DISTRICT = 32
  PAGE_RANGE_NOT_CHECKED = 64
  EVENT_YEAR_ONLY = 589

  ################################# self methods ###########################
  
  def self.birth_month_hash
    {
      "ja" => "Jan",
      "fe" => "Feb",
      "mr" => "Mar",
      "ap" => "Apr",
      "my" => "May",
      "je" => "Jun",
      "jy" => "Jul",
      "au" => "Aug",
      "se" => "Sep",
      "oc" => "Oct",
      "no" => "Nov",
      "de" => "Dec",
    }
  end
  
  def self.build_image_server_request(url)
    uri = URI(url)
    logger.warn(uri)
    request = Net::HTTP::Get.new(uri)
    security_hash = SecurityHash.make_security_hash
    query_params = URI.decode_www_form(uri.query || '')
    query_params << ['security_hash', security_hash]
    new_query = URI.encode_www_form(query_params)
    "#{uri.scheme}://#{uri.host}#{uri.path}#{uri.query ? '?' + uri.query : ''}"
  end

  def self.get_best_guess_records(hash_array)
    hash_array.map{|h| BestGuessHash.find_by(Hash: h).best_guess}
  end
    
  def self.get_birth_unique_names birth_records
    get_unique_names(birth_records, ["AssociateName", "GivenName", "Surname"])
  end

  def self.get_death_unique_names death_records
    get_unique_names(death_records, ["Surname", "GivenName"])
  end

  def self.get_marriage_unique_names marriage_records
    get_unique_names(marriage_records, ["AssociateName", "GivenName", "Surname"])
  end

  def self.get_records(result_array)
    result_array.map{|result| BestGuess.find(result.to_i)}
  end

  def self.get_unique_names records, fields
    entries = Hash.new

    fields.each do |field|
      field_array = []
      records.each do |rec|
        field_array << rec.send("#{field}")
      end
      entries[field] = field_array.uniq.compact.sort
    end
    entries.delete_if { |_, v| v.blank? }.sort.to_h    
  end

  def self.results_hash(result_array)
    self.get_records(result_array).map{|result| result.record_hash }
  end

####################################################################

  def accession_info
    raw_pages = find_accessions.pluck(:Page)
    @pages = raw_pages + raw_pages.select{|m| m.length > 3}.map{|m| m.last(3)}
    @sources = find_accessions.pluck(:SourceID)
    @qne = event_quarter_number
  end

  def all_acc_scans
    best_probable_scans || scans_with_out_file_character_check
  end

  def all_scans
    page_scans || series_scans || filename_scans
  end

  def approved_scanslists
    get_scan_lists.approved
  end

  def bad_date_for_district
    not (self.DistrictFlag & BAD_DATE_FOR_DISTRICT).zero?
  end

  def bad_page_range_for_district
    not (self.DistrictFlag & PAGE_OUTSIDE_EXECTED_RANGE_FOR_DISTRICT).zero?
  end

  def bad_volume_for_district
    not (self.DistrictFlag & BAD_VOLUME_FOR_DISTRICT).zero?
  end

  def best_probable_scans
    surname_start_letter = self.Surname[0].upcase
    non_implied_scans.select{|scan|
      if scan.StartLetters.present? && scan.EndLetters.present?
        (scan.StartLetters.upcase..scan.EndLetters.upcase).include?(surname_start_letter)
      elsif scan.range.StartLetters.present? && scan.range.EndLetters.present?
        (scan.range.StartLetters.upcase..scan.range.EndLetters.upcase).include?(surname_start_letter)
      else
      end
    } if non_implied_scans.present?
  end

  def combined_scans
    scans = page_scans if page_scans.present?
    unless page_scans.present?
      if series_scans.present? && filename_scans.present?
        scans = series_scans + filename_scans
      elsif series_scans.present? && !filename_scans.present?
        scans = series_scans if series_scans.present?
      else 
        scans =  filename_scans
      end
    end
    scans
  end

  def component_images
    ComponentFile.where(ImageID: multiple_best_probable_scans.pluck(:ImageID))
  end

    def define_url_distict
    get_district.ukbmd_url_distict
  end

  def display_district_name
    get_district.district_name_display_format
  end

  def district_linkable?
    valid_district && get_district.present? && get_district_name.present? && district_url_definable
  end

  def district_url_definable
    get_info_bookmark.present? && get_info_bookmark != "xxxx"
  end

  def district_alternative_form
    not (self.DistrictFlag & DISTRICT_ALIAS).zero?
  end

  def district_invented
    not (self.DistrictFlag & DISTRICT_UNKNOWN).zero?
  end

  def district_misspelt
    not (self.DistrictFlag & DISTRICT_MISSPELT).zero?
  end

  def filename_scans
    accession_info
    if page_scans.blank?
      ImageFile
        .select(image_fileds)
        .joins(:image_pages, range:[:source])
        .where('ImageFile.Filename' => @sources )
    end
  end

    def entries_in_the_page
    BestGuess.where(Volume: self.Volume, Page: self.Page, QuarterNumber: self.QuarterNumber, RecordTypeID: self.RecordTypeID).order(:Surname, :GivenName).pluck(:RecordNumber)
  end

  def entry_link_check?
    (self.Confirmed & ENTRY_LINK).zero?
  end

  def event_entry_number
    submissions = Submission.find_by(AccessionNumber: record_accessions, SequenceNumber: record_sequence_number)
    submissions.EntryNumber if submissions.present?
  end

  def event_quarter_number
    # return (($year - 1837)*4 + $quarter)*3 + $event;
    qne = []
    find_accessions.each {|acc|
      qne << ((acc.Year - 1837) * 4 + acc.EntryQuarter) * 3 + acc.RecordTypeID
    }
    qne
  end

  def event_registration
    submissions = Submission.find_by(AccessionNumber: record_accessions, SequenceNumber: record_sequence_number)
    submissions.Registered if submissions.present?
  end

  def event_registration_number
    if Submission.column_names.include?('RegistrationNumber')
      submissions = Submission.find_by(AccessionNumber: record_accessions, SequenceNumber: record_sequence_number)
      submissions.RegistrationNumber if submissions.present?
    end
  end

  def event_quarter
    quarter = self[:QuarterNumber]
    quarter >= EVENT_YEAR_ONLY ? QuarterDetails.quarter_year(quarter) : QuarterDetails.quarter_human(quarter)
  end

  def final_acc_scans
    all_acc_scans unless scanlists.present?
  end

  def find_accessions
    Accession.where(AccessionNumber: record_accessions)
  end

  def format_district_name
    get_district_name.gsub(/(?<=\S) *\(.*\) *$/,'')
  end

  def friendly_url
    particles = []
    # first the primary names
    particles << self.GivenName if self.GivenName
    particles << self.Surname if self.Surname

    # then the record types
    particles << RecordType.display_name(self.RecordTypeID)
    # then county name
    county_code = self.CountyCombos.County if self.CountyCombos.present?
    particles << ChapmanCode.name_from_code(county_code) if county_code.present?
    # then location
    particles << self.District if self.District
    # then volume
    particles << "v#{self.Volume}" if self.Volume
    # then page
    particles << "p#{self.Page}" if self.Page
    friendly = particles.join('-')
    friendly.gsub!(/\W/, '-')
    friendly.gsub!(/-+/, '-')
    friendly.downcase!
  end

  def get_comments
    CommentLink.includes(:comment).where(AccessionNumber: record_accessions, SequenceNumber: record_sequence_number)
  end

  def get_comment_text
  end

  def get_district
    district = District.where(DistrictNumber: self.DistrictNumber).first
    district = District. first unless district.present?
    district
  end

  def get_district_name
    get_district.DistrictName
  end

  def get_info_bookmark
    get_district.InfoBookmark
  end

  def get_reference_record_numbers
    pointed_record_information.pluck("BestGuessLink.RecordNumber")
  end

  def get_non_multiple_scans
    unless uniq_scanlists.present?
      all_acc_scans.select{|scan| scan.MultipleFiles = 0 }.uniq[0..6] if all_acc_scans.present?
    end
  end

  def get_rec_hash
    BestGuessHash.where(Hash: self.record_hash).first
  end

  def get_rec_hash_old
    self.best_guess_hash
  end

  def get_rec_links
    self.best_guess_links
  end

  def get_scan_lists
    get_rec_hash.scan_lists
  end

  def get_spouse_record
    BestGuess.where(
      Surname: self.AssociateName,
      Volume: self.Volume,
      Page: self.Page,
      QuarterNumber: self.QuarterNumber,
      DistrictNumber: self.DistrictNumber,
      RecordTypeID: self.RecordTypeID
    ).where.not(RecordNumber: self.RecordNumber).first
  end

  def image_fileds
    'ImagePage.PageNumber, ImagePage.Implied, ImageFile.ImageID, ImageFile.MultipleFiles, ImageFile.Filename, ImageFile.StartLetters, ImageFile.EndLetters, Range.RangeID, Range.Range, Source.SourceID, Source.SeriesID'
  end

  def late_entry_description_text_display?
    (self.Confirmed & ENTRY_REFERENCE).zero?
  end  

  def late_entry_detail
    sorted_reference_records.select{|rec| !(rec.Confirmed & ENTRY_LINK).zero?}.pluck(:RecordNumber)
  end

  def late_entry_pointer
    sorted_reference_records.select{|rec| (rec.Confirmed & ENTRY_LINK).zero?}.pluck(:RecordNumber)
  end

  def multi_image_filenames
    component_images.pluck(:Filename)
  end

  def multiple_best_probable_scans
    unless uniq_scanlists.present?
      all_acc_scans.reject{|scan| scan.MultipleFiles = 0 }.uniq[0..6] if all_acc_scans.present?
    end
  end

  def non_alias_district
    (self.DistrictFlag & DISTRICT_ALIAS).zero?
    #$primaryDistrictFlag & $BMD::Const::DistrictAlias && $primaryDistrictName ne $canDistrictName
  end

  def non_definite_scan_lists
    get_scan_lists.non_definite
  end

  def non_implied_scans
    all_scans.where('ImagePage.Implied' => 0) if all_scans.present?
  end

  def page_scans
    accession_info
    ImageFile
    .select(image_fileds)
    .joins(:image_pages, range:[:source])
    .where('ImagePage.PageNumber' => @pages, 'Source.QuarterEventNumber' => @qne )
  end

   def page_range_not_checked
    not (self.DistrictFlag & PAGE_RANGE_NOT_CHECKED).zero?
  end

  def pointed_record_information
    Accession.joins(:acc_files)
      .joins(:best_guess_links)
      .joins("INNER JOIN BestGuessLink as b1 ON b1.RecordNumber !=BestGuessLink.RecordNumber AND b1.AccessionNumber = acc_files_Accessions.AccessionNumber AND acc_files_Accessions.StartLine+b1.SequenceNumber=Accessions.StartLine+BestGuessLink.SequenceNumber INNER JOIN BestGuess as b ON b.RecordNumber = b1.RecordNumber AND (b.Confirmed & 8 OR b.Confirmed & 512 OR Accessions.SourceType = '+Z')")
      .where('b.RecordNumber' => self.RecordNumber)
      .select('Accessions.Year,Accessions.EntryQuarter, Accessions.RecordTypeID, BestGuessLink.RecordNumber, b.Confirmed').group("BestGuessLink.RecordNumber")
  end

  def possible_alternate_names
    preferred_records = possible_alternate_names_by_vol_page_registration_number
    return preferred_records if preferred_records.present? && preferred_records.any?
    
    possible_alternate_names_by_accession_number_and_sequence_number
  end

  def possible_alternate_names_by_accession_number_and_sequence_number
    record_submission = self.get_submission
    submissions = Submission.where(AccessionNumber: record_submission.AccessionNumber,  RegistrationNumber: record_submission.RegistrationNumber)
    get_record_links = BestGuessLink.where(AccessionNumber: submissions.pluck(:AccessionNumber), SequenceNumber: submissions.pluck(:SequenceNumber))
    records = BestGuess.where(RecordNumber: get_record_links.pluck(:RecordNumber))
    records
  end

  def possible_alternate_names_by_vol_page_registration_number
    record_submission = self.get_submission
    submissions = Submission.where(RomanVolume: record_submission.RomanVolume, EntryNumber: record_submission.EntryNumber, RegistrationNumber: record_submission.RegistrationNumber)
    get_record_links = BestGuessLink.where(AccessionNumber: submissions.pluck(:AccessionNumber), SequenceNumber: submissions.pluck(:SequenceNumber))
    records = BestGuess.where(RecordNumber: get_record_links.pluck(:RecordNumber), DistrictNumber: self.DistrictNumber, RecordTypeID: self.RecordTypeID)
    records
  end

  def postems_list
    if get_rec_hash.present?
      get_hash = get_rec_hash.Hash
      Postem.where(Hash: get_hash).all
    end
  end

  def record_accessions
    get_rec_links.pluck(:AccessionNumber) if get_rec_links.present?
  end

  def record_accession_pages
    #Accession.where(AccessionNumber: record_accessions).pluck(:Page)
    #self.best_guess_links.each {|link|
     # link.accession.Page
    #}
  end

  def record_accession_sources
    Accession.where(AccessionNumber: record_accessions).pluck(:SorceID)
    #self.best_guess_links.each {|link|
     # link.accession.Page
    # }
  end

  def record_hash
    surname = self.Surname.encode('ISO-8859-1').upcase
    given_name = self.GivenName.encode('ISO-8859-1').upcase
    Rails.env.development? ? district_name = self.District.upcase : district_name = self.district.DistrictName.upcase
    volume = self.Volume.upcase
    page = self.Page.upcase
    year = QuarterDetails.quarter_year(self.QuarterNumber)
    quarter = QuarterDetails.quarter(self.QuarterNumber)
    record_type = self.RecordTypeID
    record_hash = Digest::MD5.base64digest("#{surname}/#{given_name}/#{district_name}/#{volume}/#{page}/#{year}/#{quarter}/#{record_type}")
    record_hash.strip.chomp('==')
  end

  def record_sequence_number
    get_rec_links.pluck(:SequenceNumber) if get_rec_links.present?
  end  

  def reference_entry_description_text_display?
    !(self.Confirmed & ENTRY_REFERENCE).zero? && (self.Confirmed & ENTRY_LINK).zero?
  end

  def reference_record_information
    BestGuess.where(RecordNumber: get_reference_record_numbers)#.order(:Surname, :GivenName).pluck(:RecordNumber)
  end
  
  def register_entry_number_format
    year, event_type = record_year_and_event_type
    
    # New format: 1993 with birth/death records, or any record from 1994+
    (year >= 1993 && event_type < 3)# || ( year >= 1994 && event_type < 3 )
  end

  def post_1994_marriage?
    year, event_type = record_year_and_event_type
    
    # Marriage records from 1994 or later
    year >= 1994 && event_type == 3
  end

  def get_scans
    scan_links = self.uniq_scanlists if self.uniq_scanlists.present?
    acc_scans = self.get_non_multiple_scans if self.get_non_multiple_scans.present?
    acc_mul_scans = self.multiple_best_probable_scans if self.multiple_best_probable_scans.present?
    [scan_links, acc_scans, acc_mul_scans]
  end

  def get_submission
    bg_link = BestGuessLink.where(RecordNumber: self.RecordNumber, PrimaryEntry: 1).first
    #Submission.find_by(Surname: self.Surname, GivenName: self.GivenName, District: self.District, Volume: self.Volume, Page: page)
    Submission.find_by(AccessionNumber: bg_link.AccessionNumber, SequenceNumber: bg_link.SequenceNumber)
  end

  def get_submission_old
    page = self.Page.rjust(4, '0') if self.Page.present? && self.Page.length < 4
    Submission.find_by(Surname: self.Surname, GivenName: self.GivenName, District: self.District, Volume: self.Volume, Page: page)
  end

  def rejected_likely_scanslists
    rejected_non_definite_scan_lists.can_be_confirm if rejected_possible_scanslists.blank?
  end

  def rejected_non_definite_scan_lists
    non_definite_scan_lists.rejected
  end

  def rejected_possible_scanslists
    rejected_non_definite_scan_lists.possibly_confirm if rejected_probable_scanslists.blank?
  end

  def rejected_probable_scanslists
    rejected_non_definite_scan_lists.probably_confirm if unapproved_probable_scanslists.blank?
  end

  def scan_with_range
    non_implied_scans.reject{|s| s.Range = ""} if non_implied_scans.present?
  end

  def scanlists
    approved_scanslists.to_a + unapproved_definitive_scanslists.to_a + unapproved_probable_scanslists.to_a + rejected_probable_scanslists.to_a + rejected_possible_scanslists.to_a + rejected_likely_scanslists.to_a
  end

  def scans_with_out_file_character_check
    if best_probable_scans.to_a.count < 3
      non_implied_scans.all if non_implied_scans.present?
    end
  end

  def series_scans
    accession_info
    if page_scans.blank?
      ImageFile
        .select(image_fileds)
        .joins(:image_pages, range:[:source])
        .where('Source.SeriesID' => @sources )
    end
  end

  def sorted_reference_records
    reference_record_information.order(:Surname, :GivenName)
  end  

  def transcribers
    users = []
    # record_info = BestGuess.includes(:best_guess_links).where(RecordNumber: record).first
    get_rec_links.includes(:accession).each do |link|
      users << link.try(:accession).try(:bmd_file).try(:submitter).try(:UserID) if self.Confirmed & ENTRY_SYSTEM || self.Confirmed & ENTRY_REFERENCE
    end
    users.reject!(&:blank?)
    users
    # record_info = BestGuess.where(RecordNumber: record).first
    # accession_numbers = BestGuessLink.where(RecordNumber: record).pluck(:AccessionNumber)
    # accessions = Accession.where(AccessionNumber: accession_numbers)
    # accessions_all = accessions# || accessions.where(SourceType: '+Z')
    # accession_files = accessions_all.pluck(:FileNumber)
    # file_submitters =  BmdFile.where(FileNumber: accession_files).pluck(:SubmitterNumber)
    # @transcribers = Submitter.where(SubmitterNumber: file_submitters).pluck(:UserID)
    # return @transcribers if record_info.Confirmed & ENTRY_SYSTEM || record_info.Confirmed & ENTRY_REFERENCE
  end

  def unapproved_definitive_scanslists
    unrejected_non_definite_scan_lists.definitive if approved_scanslists.blank?
  end

  def unapproved_probable_scanslists
    unrejected_non_definite_scan_lists.probable if unapproved_definitive_scanslists.blank?
  end

  def uniq_scanlists
    scanlists.uniq[0..5] if scanlists.present?
  end

  def unrejected_non_definite_scan_lists
    non_definite_scan_lists.unrejected
  end

  def valid_district
    (self.DistrictFlag & DISTRICT_MISSPELT).zero?
  end

  private
  def record_year_and_event_type
    [
      QuarterDetails.quarter_year(self[:QuarterNumber]),
      self[:RecordTypeID]
    ]
  end
end