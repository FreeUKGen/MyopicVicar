class Accession < FreebmdDbBase
	 self.pluralize_table_names = false
  self.table_name = 'Accessions'
  has_many :best_guess_links, class_name: '::BestGuessLink', foreign_key: 'AccessionNumber'
  belongs_to :bmd_file, foreign_key: 'FileNumber', class_name: '::BmdFile'
  has_many :acc_files, foreign_key: 'FileNumber', primary_key: 'FileNumber', class_name: '::Accession'
end