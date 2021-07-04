# Entry Information
class BestGuess < FreebmdDbBase
  require 'application_text'
  self.pluralize_table_names = false
  self.table_name = 'BestGuess'
  has_one :best_guess_maariages, class_name: '::BestGuessMarriage', foreign_key: 'RecordNumber'
  has_one :best_guess_hash, class_name: '::BestGuessHash', foreign_key: 'RecordNumber'

  belongs_to :CountyCombos, foreign_key: 'CountyComboID', primary_key: 'CountyComboID', class_name: '::CountyCombo'
  has_many :ScanLinks, primary_key: 'ChunkNumber', foreign_key: 'ChunkNumber'
  has_many :best_guess_links, class_name: '::BestGuessLink', foreign_key: 'RecordNumber' #, primary_key: ['RecordNumber', 'AccessionNumber', 'SequenceNumber']
  extend SharedSearchMethods
  ENTRY_SYSTEM = 8
  ENTRY_LINK = 256
  ENTRY_REFERENCE = 512
  DISTRICT_MISSPELT = 2
  DISTRICT_ALIAS = 1

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

  def get_rec_links
    self.best_guess_links
  end

  def get_rec_hash
    self.best_guess_hash
  end

  def transcribers
    users = []
    # record_info = BestGuess.includes(:best_guess_links).where(RecordNumber: record).first
    get_rec_links.includes(:accession).each do |link|
      users << link.accession.bmd_file.submitter.UserID if self.Confirmed & ENTRY_SYSTEM || self.Confirmed & ENTRY_REFERENCE
    end
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

  def get_scan_lists
    get_rec_hash.scan_lists
  end

  def approved_scanslists
    get_scan_lists.approved
  end

  def unapproved_definitive_scanslists
    get_scan_lists.non_definite.unrejected.definitive if approved_scanslists.blank?
  end

  def unapproved_probable_scanslists
    get_scan_lists.non_definite.unrejected.probable if unapproved_definitive_scanslists.blank?
  end

  def rejected_probable_scanslists
    get_scan_lists.non_definite.rejected.probably_confirm if unapproved_probable_scanslists.blank?
  end

  def rejected_possible_scanslists
    get_scan_lists.non_definite.rejected.possibly_confirm if rejected_probable_scanslists.blank?
  end

  def rejected_likely_scanslists
    get_scan_lists.non_definite.rejected.can_be_confirm if rejected_possible_scanslists.blank?
  end

  def scanlists
    approved_scanslists + unapproved_definitive_scanslists + unapproved_probable_scanslists + rejected_probable_scanslists + rejected_possible_scanslists + rejected_likely_scanslists
  end

  def uniq_scanlists
    scanlists.uniq[0..5] if scanlists.present?
  end

  def record_accessions
    get_rec_links.pluck(:AccessionNumber) if get_rec_links.present?
  end

  def record_sequence_number
    get_rec_links.pluck(:SequenceNumber) if get_rec_links.present?
  end

  def get_comments
    CommentLink.includes(:comment).where(AccessionNumber: record_accessions, SequenceNumber: record_sequence_number)
  end

  def get_comment_text
  end

  def record_accession_pages
    #Accession.where(AccessionNumber: record_accessions).pluck(:Page)
    #self.best_guess_links.each {|link|
     # link.accession.Page
    #}
  end

  def find_accessions
    Accession.where(AccessionNumber: record_accessions)
  end

  def accession_info
    raw_pages = find_accessions.pluck(:Page)
    @pages = raw_pages + raw_pages.select{|m| m.length > 3}.map{|m| m.last(3)}
    @sources = find_accessions.pluck(:SourceID)
    @qne = event_quarter_number
  end

  def page_scans
    accession_info
    ImageFile
    .select(image_fileds)
    .joins(:image_pages, range:[:source])
    .where('ImagePage.PageNumber' => @pages, 'Source.QuarterEventNumber' => @qne )
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

  def filename_scans
    accession_info
    if page_scans.blank?
      ImageFile
        .select(image_fileds)
        .joins(:image_pages, range:[:source])
        .where('ImageFile.Filename' => @sources )
    end
  end

  def image_fileds
    'ImagePage.PageNumber, ImagePage.Implied, ImageFile.ImageID, ImageFile.MultipleFiles, ImageFile.Filename, ImageFile.StartLetters, ImageFile.EndLetters, Range.RangeID, Range.Range, Source.SourceID, Source.SeriesID'
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

  def all_scans
    page_scans || series_scans || filename_scans
  end

  def non_implied_scans
    all_scans.where('ImagePage.Implied' => 0) if all_scans.present?
  end

  def scan_with_range
    non_implied_scans.reject{|s| s.Range = ""} if non_implied_scans.present?
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

  def scans_with_out_file_character_check
    if best_probable_scans.to_a.count < 3
      non_implied_scans.all if non_implied_scans.present?
    end
  end

  def all_acc_scans
    best_probable_scans || scans_with_out_file_character_check
  end

  def multiple_best_probable_scans
    unless uniq_scanlists.present?
      all_acc_scans.reject{|scan| scan.MultipleFiles = 0 }.uniq[0..6] if all_acc_scans.present?
    end
  end

  def get_non_multiple_scans
    unless uniq_scanlists.present?
      all_acc_scans.select{|scan| scan.MultipleFiles = 0 }.uniq[0..6] if all_acc_scans.present?
    end
  end

  def final_acc_scans
    all_acc_scans unless scanlists.present?
  end

  def component_images
    ComponentFile.where(ImageID: multiple_best_probable_scans.pluck(:ImageID))
  end

  def multi_image_filenames
    component_images.pluck(:Filename)
  end

  def event_quarter_number
    # return (($year - 1837)*4 + $quarter)*3 + $event;
    qne = []
    find_accessions.each {|acc|
      qne << ((acc.Year - 1837) * 4 + acc.EntryQuarter) * 3 + acc.RecordTypeID
    }
    qne
  end

  def record_accession_sources
    Accession.where(AccessionNumber: record_accessions).pluck(:SorceID)
    #self.best_guess_links.each {|link|
     # link.accession.Page
    # }
  end
  def postems_list
    get_hash = get_rec_hash.Hash
    Postem.where(Hash: get_hash).all
  end

  def entries_in_the_page
    BestGuess.where(Volume: self.Volume, Page: self.Page, QuarterNumber: self.QuarterNumber, RecordTypeID: self.RecordTypeID).order(:Surname, :GivenName).pluck(:RecordNumber)
  end

  def pointed_record_information
    Accession.joins(:acc_files)
      .joins(:best_guess_links)
      .joins("INNER JOIN BestGuessLink as b1 ON b1.RecordNumber !=BestGuessLink.RecordNumber AND b1.AccessionNumber = acc_files_Accessions.AccessionNumber AND acc_files_Accessions.StartLine+b1.SequenceNumber=Accessions.StartLine+BestGuessLink.SequenceNumber INNER JOIN BestGuess as b ON b.RecordNumber = b1.RecordNumber AND (b.Confirmed & 8 OR b.Confirmed & 512 OR Accessions.SourceType = '+Z')")
      .where('b.RecordNumber' => self.RecordNumber)
      .select('Accessions.Year,Accessions.EntryQuarter, Accessions.RecordTypeID, BestGuessLink.RecordNumber, b.Confirmed').group("BestGuessLink.RecordNumber")
  end

  def get_reference_record_numbers
    pointed_record_information.pluck("BestGuessLink.RecordNumber")
  end

  def reference_record_information
    BestGuess.where(RecordNumber: get_reference_record_numbers)#.order(:Surname, :GivenName).pluck(:RecordNumber)
  end

  def reference_entry_description_text_display?
    !(self.Confirmed & ENTRY_REFERENCE).zero? && (self.Confirmed & ENTRY_LINK).zero?
  end

  def late_entry_description_text_display?
    (self.Confirmed & ENTRY_REFERENCE).zero?
  end

  def entry_link_check?
    (self.Confirmed & ENTRY_LINK).zero?
  end

  def sorted_reference_records
    reference_record_information.order(:Surname, :GivenName)
  end

  def late_entry_pointer
    sorted_reference_records.select{|rec| (rec.Confirmed & ENTRY_LINK).zero?}.pluck(:RecordNumber)
  end

  def late_entry_detail
    sorted_reference_records.select{|rec| !(rec.Confirmed & ENTRY_LINK).zero?}.pluck(:RecordNumber)
  end

  def valid_district
    (self.DistrictFlag & DISTRICT_MISSPELT).zero?
  end

  def non_alias_district
    (self.DistrictFlag & DISTRICT_ALIAS).zero?
    #$primaryDistrictFlag & $BMD::Const::DistrictAlias && $primaryDistrictName ne $canDistrictName
  end

  def get_district
    District.where(DistrictNumber: self.DistrictNumber).first
  end

  def get_district_name
    get_district.DistrictName
  end

  def format_district_name
    get_district_name.gsub(/(?<=\S) *\(.*\) *$/,'')
  end

  def get_info_bookmark
    get_district.InfoBookmark
  end

  def district_url_definable
    get_info_bookmark.present? && get_info_bookmark != "xxxx"
  end

  def district_linkable?
    valid_district && get_district.present? && get_district_name.present? && district_url_definable
  end

  def define_url_distict
    district_name = format_district_name
    district_suffix = '1'
    district_name = district_name.gsub(/&/,"and")
    district_name = district_name.gsub(/ /,"-") if get_info_bookmark == "dash"
    district_name = district_name.gsub(/upon/,"on") if get_info_bookmark == "upon"
    district_name = district_name.gsub(/ [A-Za-z]*$/,"") if get_info_bookmark == "trnc"
    district_name = district_name.gsub(/ [A-Za-z]*$/,district_suffix) if get_info_bookmark.match?(/sfx[0-9]/)
    district_name = get_info_bookmark unless get_info_bookmark.match?(/aaaa|dash|upon|trnc|sfx[0-9]/)
    district_name = district_name.gsub(/ /,"%20")
    district_name
  end
end