class BestGuessHash < FreebmdDbBase
	self.pluralize_table_names = false
  self.table_name = 'BestGuessHash'
  has_many :postems, class_name: '::Postem', foreign_key: 'Hash', primary_key: 'Hash'
  belongs_to :best_guess, foreign_key: 'RecordNumber', class_name: '::BestGuess'
  has_many :scan_lists, class_name: '::ScanList', foreign_key: 'Hash', primary_key: 'Hash'
end