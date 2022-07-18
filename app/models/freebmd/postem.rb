class Postem < FreebmdDbBase
	self.pluralize_table_names = false
  self.table_name = 'Postems'
  belongs_to :best_guess_hash, foreign_key: 'Hash', primary_key: 'Hash', class_name: '::BestGuessHash'
end