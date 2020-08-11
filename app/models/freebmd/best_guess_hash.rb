class BestGuessHash < FreebmdDbBase
	 self.pluralize_table_names = false
  self.table_name = 'BestGuessHash'
  has_many :postems, class_name: '::Postem', foreign_key: 'Hash', primary_key: 'Hash'
end