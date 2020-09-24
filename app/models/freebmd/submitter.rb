class Submitter < FreebmdDbBase
	 self.pluralize_table_names = false
  self.table_name = 'Submitters'
  has_many :bmd_files, class_name: '::BmdFile', foreign_key: 'SubmitterNumber'
end