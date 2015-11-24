class Csvfile < CarrierWave::Uploader::Base
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  field :userid, type: String
  field :file_name,type: String
  field :process,type: String, default: "Process tonight"
  # files are stored in Rails.application.config.datafiles_changeset
  validate :csvfile_already_exists, on: :create
  mount_uploader :csvfile, CsvfileUploader

  def csvfile_already_exists
    errors.add(:file_name, "A processed file of that name already exists. You cannot upload a file with the same name. You must replace the existing file") if  PhysicalFile.userid(self.userid).file_name(self.file_name).processed.first.present?
    errors.add(:file_name,  "The file you are replacing is locked.") if Freereg1CsvFile.userid(self.userid).file_name(self.file_name).transcriber_lock.exists? ||
    Freereg1CsvFile.userid(self.userid).file_name(self.file_name).coordinator_lock.exists?
  end
  def check_name(name)
    decision = false
    decision = true if self.file_name == name
    decision
  end
  def setup_batch
    ok = true
    batch_entries = PhysicalFile.where(userid: self.userid, file_name: self.file_name).count
    if batch_entries == 0
      batch = PhysicalFile.new(:base => true,:base_uploaded_date => Time.now,:file_processed => false, :userid =>self.userid , :file_name => self.file_name)
      batch.save     
    elsif batch_entries == 1
     batch = PhysicalFile.where(userid: self.userid, file_name: self.file_name).first
     batch.update_attributes(:base => true,:base_uploaded_date => Time.now,:file_processed => false)
    else
     batch = "Too many batch entries. Have your coordinator contact system administration with this message, date and time"
     ok = false
    end
    return[ok,batch]
  end
  
  def create_batch_unless_exists
    batch = PhysicalFile.where(userid: self.userid, file_name: self.file_name).exists?
    unless batch
      batch = PhysicalFile.new(:userid => self.userid, :file_name => self.file_name, :base =>true, :base_uploaded_date => Time.now, :file_processed => false)
      batch.save
    end
  end
  def estimate_time
    place = File.join(Rails.application.config.datafiles,self.userid,self.file_name)
    size = (File.size("#{place}"))
    unit = 0.001
    processing_time = (size.to_i*unit).to_i
  end
  def check_for_existing_file
    process = true
    batch = PhysicalFile.where(userid: self.userid, file_name: self.file_name,:base => true).first
    if batch.present?  
      file_location = File.join(Rails.application.config.datafiles,self.userid,self.file_name)
      if File.file?(file_location)
        newdir = File.join(File.join(Rails.application.config.datafiles,self.userid),'.attic')
        Dir.mkdir(newdir) unless Dir.exists?(newdir)
        time = Time.now.to_i.to_s
        renamed_file = (file_location + "." + time).to_s
        File.rename(file_location,renamed_file)
        FileUtils.mv(renamed_file,newdir,:verbose => true)
        FileUtils.rm(file_location) if File.file?(file_location)
        user =UseridDetail.where(:userid => self.userid).first
        unless user.nil?
          attic_file = AtticFile.new(:name => "#{self.file_name}.#{time}", :date_created => DateTime.strptime(time,'%s'), :userid_detail_id => user.id)
          attic_file.save
        end
      else
        p "There is no file to put into the attic"
      end     
    end
    process
  end
end
