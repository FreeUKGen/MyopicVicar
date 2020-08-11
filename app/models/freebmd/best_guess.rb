class BestGuess < FreebmdDbBase
  self.pluralize_table_names = false
  self.table_name = 'BestGuess'
  has_one :best_guess_maariages, class_name: '::BestGuessMarriage', foreign_key: 'RecordNumber'
  has_one :best_guess_hash, class_name: '::BestGuessHash', foreign_key: 'RecordNumber'
  belongs_to :CountyCombos, foreign_key: 'CountyComboID', primary_key: 'CountyComboID', class_name: '::CountyCombo'
  has_many :ScanLinks, primary_key: 'ChunkNumber', foreign_key: 'ChunkNumber'
  extend SharedSearchMethods

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
    sql = "select  b.Surname from BestGuess as b
   inner join BestGuessLink as l on l.RecordNumber = b.RecordNumber
   where b.RecordNumber = 1"
   FreebmdDbBase.connection.select_all(sql).to_hash
  end

  def self.postems_list
  end
end