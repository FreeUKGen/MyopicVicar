class BestGuess < FreebmdDbBase
  self.pluralize_table_names = false
  self.table_name = 'BestGuess'
  has_one :best_guess_maariages, class_name: '::BestGuessMarriage', foreign_key: 'RecordNumber'
  has_many :best_guess_hashes, class_name: '::BestGuessHash', foreign_key: 'RecordNumber'
  belongs_to :CountyCombos, foreign_key: 'CountyComboID', primary_key: 'CountyComboID', class_name: '::CountyCombo'
  has_many :ScanLinks, primary_key: 'ChunkNumber', foreign_key: 'ChunkNumber'
  has_many :best_guess_links, class_name: '::BestGuessLink', foreign_key: 'RecordNumber' #, primary_key: ['RecordNumber', 'AccessionNumber', 'SequenceNumber']
  extend SharedSearchMethods
  ENTRY_SYSTEM = 8
  ENTRY_REFERENCE = 512

  def friendly_url
    particles = []
    # first the primary names
    particles << self.GivenName if self.GivenName
    particles << self.Surname if self.Surname

    # then the record types
    particles << RecordType::display_name(self.RecordTypeID)
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

  def transcribers
    users = []
    #record_info = BestGuess.includes(:best_guess_links).where(RecordNumber: record).first
    self.best_guess_links.includes(:accession).each do |link|
      users << link.accession.bmd_file.submitter.UserID if self.Confirmed & ENTRY_SYSTEM || self.Confirmed & ENTRY_REFERENCE
    end
    users
    #record_info = BestGuess.where(RecordNumber: record).first
    #accession_numbers = BestGuessLink.where(RecordNumber: record).pluck(:AccessionNumber)
    #accessions = Accession.where(AccessionNumber: accession_numbers)
    #accessions_all = accessions# || accessions.where(SourceType: '+Z')
    #accession_files = accessions_all.pluck(:FileNumber)
    #file_submitters =  BmdFile.where(FileNumber: accession_files).pluck(:SubmitterNumber)
    #@transcribers = Submitter.where(SubmitterNumber: file_submitters).pluck(:UserID)
    #return @transcribers if record_info.Confirmed & ENTRY_SYSTEM || record_info.Confirmed & ENTRY_REFERENCE
  end

  def postems_list
    postem_info = []
    get_hash = BestGuessHash.where(RecordNumber: self.RecordNumber).first.Hash
    Postem.where(Hash: get_hash).each do |postem|
      postem_info << postem.Information
    end
    postem_info
  end
end