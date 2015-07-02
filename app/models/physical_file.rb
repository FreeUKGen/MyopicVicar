class PhysicalFile
 include Mongoid::Document
 include Mongoid::Timestamps::Created::Short
 include Mongoid::Timestamps::Updated::Short
 field :file_name, type: String
 field :userid, type: String
 field :change_uploaded_date, type: DateTime
 field :change,type: Boolean, default: false
 field :base_uploaded_date, type: DateTime
 field :base,type: Boolean, default: false
 field :file_processed_date, type: DateTime
 field :file_processed, type: Boolean, default: false
 field :action, type: String

 index ({ userid: 1, file_name: 1, change: 1, change_uploaded_date: 1})
 index ({ userid: 1, file_name: 1, base: 1, base_uploaded_date: 1})
 index ({ userid: 1, file_name: 1, file_processed: 1, file_processed_date: 1})

 def self.file_name(name)
  where(:file_name => name)
 end
 def self.change_uploaded_date(date)
  where(:change_uploaded_date => date)
 end
 def self.processed
  where(:file_processed => true)
 end
 def self.not_processed
  where(:file_processed => false)
 end
 def self.not_uploaded_into_change
  where(:change => false)
 end
 def self.uploaded_into_change
  where(:change => true)
 end
 def self.not_loaded_into_base
  where(:base => false)
 end
 def self.loaded_into_base
  where(:base => true)
 end
def self.userid(id)
  where(:userid => id)
end
end