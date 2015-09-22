class PhysicalFile
 include Mongoid::Document
 include Mongoid::Timestamps::Created::Short
 include Mongoid::Timestamps::Updated::Short
 field :file_name, type: String
 field :userid, type: String
 field :base_uploaded_date, type: DateTime
 field :base,type: Boolean, default: false
 field :change_uploaded_date, type: DateTime
 field :change,type: Boolean, default: false
 field :file_processed_date, type: DateTime
 field :file_processed, type: Boolean, default: false
 field :action, type: String
 field :waiting_to_be_processed, type: Boolean, default: false
 field :waiting_date, type: DateTime
 attr_accessor :type

 
 index ({ userid: 1, file_name: 1, change: 1, change_uploaded_date: 1})
 index ({ userid: 1, file_name: 1, base: 1, base_uploaded_date: 1})
 index ({ userid: 1, file_name: 1, file_processed: 1, file_processed_date: 1})
 index ({ base: 1})
 index ({file_processed: 1})
 index ({ change: 1})
 index ({ waiting_to_be_processed: 1})
  

  class << self
     def file_name(name)
      where(:file_name => name)
     end
     def processed
      where(:file_processed => true)
     end
     def not_processed
      where(:file_processed => false)
     end
     def not_uploaded_into_base
      where(:base => false)
     end
     def uploaded_into_base
      where(:base => true)
     end
     def change_uploaded_date(date)
      where(:change_uploaded_date => date)
     end
     def not_uploaded_into_change
      where(:change => false)
     end
     def uploaded_into_change
      where(:change => true)
     end
     def waiting
      where(:waiting_to_be_processed => true)
     end

     def userid(id)
      where(:userid => id)
     end
  end
  
  def add_file(batch)
    case 
    when  batch == "base" || batch == "reprocessing"
      self.update_attributes(:file_processed => false, :file_processed_date => nil,:waiting_to_be_processed => true, :waiting_date => Time.now) 
    when batch == "change"
      base_directory = Rails.application.config.datafiles
      change_directory = Rails.application.config.datafiles_changeset
      self.update_attributes(:change => true,:change_uploaded_date =>Time.now, :file_processed => false, :file_processed_date => nil,:waiting_to_be_processed => true, :waiting_date => Time.now) 
      filename = File.join(change_directory, self.userid,self.file_name)
      file_location = File.join(base_directory, self.userid)
      Dir.mkdir(file_location) unless Dir.exists?(file_location)
      FileUtils.cp(filename,File.join(file_location,self.file_name ),:verbose => true) 
      self.update_attributes(:base => true, :base_uploaded_date => Time.now,:file_processed => false)
    else 
      p "why here"
    end
    processing_file = Rails.application.config.processing_delta
    File.open(processing_file, 'a') do |f|
     f.write("#{self.userid}/#{self.file_name}\n")
    end
  end
  def file_delete
    file =   Freereg1CsvFile.where(:file_name => self.file_name, :userid => self.userid).first 
    file.save_to_attic unless file.blank?
    Freereg1CsvFile.where(:file_name => self.file_name, :userid => self.userid).destroy_all unless file.blank?
    unless self.file_name.nil?
      base_file_location = File.join(Rails.application.config.datafiles,self.userid,self.file_name)
      change_file_location = File.join(Rails.application.config.datafiles_changeset,self.userid,self.file_name)  
      File.delete(base_file_location) if File.file?(base_file_location)
      File.delete(change_file_location) if File.file?(change_file_location)
    end
  end
  def update_userid(new_userid)
    self.update_attribute(:userid, new_userid)  
  end
end