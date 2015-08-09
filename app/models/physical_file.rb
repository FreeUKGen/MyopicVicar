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
  class << self
     def file_name(name)
      where(:file_name => name)
     end
     def change_uploaded_date(date)
      where(:change_uploaded_date => date)
     end
     def change_uploaded_date(date)
      where(:change_uploaded_date => date)
     end
     def processed
      where(:file_processed => true)
     end
     def not_processed
      where(:file_processed => false)
     end
     def not_uploaded_into_change
      where(:change => false)
     end
     def uploaded_into_change
      where(:change => true)
     end
     def not_uploaded_into_base
      where(:base => false)
     end
     def uploaded_into_base
      where(:base => true)
     end
     def userid(id)
      where(:userid => id)
     end
  end
def add_file(batch)
  change_directory = Rails.application.config.datafiles_changeset
  base_directory = Rails.application.config.datafiles
  case 
  when  batch == "base" || batch == "reprocessing"
    #move file to change
    file_location = File.join(change_directory,self.userid)
    Dir.mkdir(file_location) unless Dir.exists?(file_location)
    old_file = File.join(base_directory,self.userid,self.file_name)
    new_file = File.join(file_location,self.file_name)
    FileUtils.cp(old_file,new_file,:verbose => true)
    self.update_attributes(:change => true,:change_uploaded_date =>Time.now, :base =>false, :base_uploaded_date => nil) 
  when batch == "change"
    self.update_attributes(:change => true,:change_uploaded_date =>Time.now) 
  else 
    p "why here"
  end 
  processing_file = Rails.application.config.processing_delta
  File.open(processing_file, 'a') do |f|
   f.write("#{self.userid}/#{self.file_name}\n")
  end
end
end