class BestGuess < FreebmdDbBase
  self.pluralize_table_names = false
  self.table_name = 'BestGuess'
  has_one :best_guess_maariages, class_name: '::BestGuessMarriage', foreign_key: 'RecordNumber'
  has_one :best_guess_hash, class_name: '::BestGuessHash', foreign_key: 'RecordNumber'
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
    #particles << ChapmanCode.name_from_code(chapman_code)
    # then location
    #particles << self.place.place_name if self.place.place_name
    # finally date
    #particles << search_dates.first
    # join and clean
    friendly = particles.join('-')
    friendly.gsub!(/\W/, '-')
    friendly.gsub!(/-+/, '-')
    friendly.downcase!
  end
  def hello
    puts 'hello'
  end

  def self.transcriber(record)
    record_info = BestGuess.where(RecordNumber: record).first
    accession_numbers = BestGuessLink.where(RecordNumber: record).pluck(:AccessionNumber)
    accessions = Accession.where(AccessionNumber: accession_numbers)
    accessions_all = accessions# || accessions.where(SourceType: '+Z')
    accession_files = accessions_all.pluck(:FileNumber)
    file_submitters =  BmdFile.where(FileNumber: accession_files).pluck(:SubmitterNumber)
    @transcribers = Submitter.where(SubmitterNumber: file_submitters)
    return @transcribers if record_info.Confirmed & ENTRY_SYSTEM || record_info.Confirmed & ENTRY_REFERENCE
   #sql = "SELECT b2.recordNumber,a2.Year,a2.EntryQuarter,a2.RecordTypeID,b.Confirmed
            #FROM Accessions as a1, Accessions as a2,
             #    BestGuessLink as b1, BestGuessLink as b2,
              #   BestGuess as b
           # WHERE b1.recordnumber= #{record} AND
            #      b1.accessionnumber=a1.accessionnumber AND
             #     a1.filenumber=a2.filenumber AND
              #    b2.accessionnumber=a2.accessionnumber AND
              #    a2.startline+b2.sequencenumber=a1.startline+b1.sequencenumber AND
                #  b2.recordNumber!=b1.recordnumber AND
                #  b.RecordNumber = #{record} AND
                 # (b.Confirmed & #{ENTRY_SYSTEM} OR
                 #  b.Confirmed & #{ENTRY_REFERENCE} OR
                  # a1.SourceType = '+Z')
            #GROUP BY b2.RecordNumber"
   #FreebmdDbBase.connection.select_all(sql).to_hash
  end

  def self.postems_list
  end
end