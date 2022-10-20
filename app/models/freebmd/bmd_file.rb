class BmdFile < FreebmdDbBase
	self.pluralize_table_names = false
  self.table_name = 'files'
   self.primary_key = 'FileNumber'
  belongs_to :submitter, foreign_key: 'SubmitterNumber', class_name: '::Submitter'#, primary_key: 'FileNumber'
  has_many :accessions, class_name: '::Accession', foreign_key: 'FileNumber', primary_key: 'FileNumber'
end