class BestGuessLink < FreebmdDbBase
	 self.pluralize_table_names = false
  self.table_name = 'BestGuessLink'
  belongs_to :best_guess, foreign_key: 'RecordNumber', class_name: '::BestGuess'
  belongs_to :accession, foreign_key: 'AccessionNumber', class_name: '::Accession'
  has_many :bg_links, foreign_key: 'RecordNumber', primary_key: 'RecordNumber', class_name: '::BestGuessLink'
end