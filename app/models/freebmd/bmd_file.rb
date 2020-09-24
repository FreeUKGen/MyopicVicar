class BmdFile < FreebmdDbBase
	 self.pluralize_table_names = false
  self.table_name = 'Files'
  belongs_to :submitter, foreign_key: 'SubmitterNumber', class_name: '::Submitter'
  has_many :accessions, class_name: '::Accession', foreign_key: 'FileNumber'
end