class Csvfile < CarrierWave::Uploader::Base
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  field :userid, type: String
  field :file_name,type: String
  field :process,type: String, default: "Process tonight"
  # files are stored in Rails.application.config.datafiles_changeset
  mount_uploader :csvfile, CsvfileUploader



  def check_for_existing_file_and_save
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

  def check_name(name)
    decision = false
    decision = true if self.file_name == name
    decision
  end
  def create_batch_unless_exists
    batch = PhysicalFile.where(userid: self.userid, file_name: self.file_name).first
    if !batch.present?
      batch = PhysicalFile.new(:userid => self.userid, :file_name => self.file_name, :base =>true, :base_uploaded_date => Time.now, :file_processed => false)
      batch.save
    else
      batch.update_attributes( :base =>true, :base_uploaded_date => Time.now, :file_processed => false)
    end
    batch
  end

  def csvfile_already_exists
    ok = true
    case
    when  PhysicalFile.userid(self.userid).file_name(self.file_name).processed.first.present?
      ok = false
      message = "You already have a processed file of that name. You cannot upload a file with the same name. You must replace the existing file or use a different file name."
    when Freereg1CsvFile.userid(self.userid).file_name(self.file_name).transcriber_lock.exists?
      message =   "The file you are replacing is locked."
      ok = false
    end
    return ok, message
  end

  def estimate_time
    place = File.join(Rails.application.config.datafiles,self.userid,self.file_name)
    File.exists?(place) ? size = File.size(place) : size = 1
    unit = 0.001
    processing_time = (size.to_i*unit).to_i
  end

  def setup_batch_on_replace
    ok = true
    place = File.join(Rails.application.config.datafiles,self.userid,self.file_name)
    processing_time = self.estimate_time
    batch_entries = PhysicalFile.where(userid: self.userid, file_name: self.file_name).count
    case
    when !File.exists?(place)
      ok = false
      batch = "You are attempting to replace a file you do not have. Likely you are a coordinator replacing a file belonging to someone else. You must replace into their uaerid."
    when processing_time >= 600 && batch_entries == 0
      batch = PhysicalFile.new(:base => true,:base_uploaded_date => Time.now,:file_processed => false, :userid =>self.userid , :file_name => self.file_name)
      batch.save
      batch = "Too large a file to be replaced. A message has been sent to your coordinator and data managers so please discuss with them how to proceed."
      self.check_for_existing_file_and_save
      self.save
      ok = false
      UserMailer.report_to_data_manger_of_large_file(self.file_name,self.userid).deliver_now
    when processing_time >= 600 && batch_entries == 1
      batch = PhysicalFile.where(userid: self.userid, file_name: self.file_name).first
      batch.update_attributes(:base => true,:base_uploaded_date => Time.now,:file_processed => false)
      batch = "Too large a file to be replaced. A message has been sent to your coordinator and data managers so please discuss with them how to proceed."
      self.check_for_existing_file_and_save
      self.save
      ok = false
      UserMailer.report_to_data_manger_of_large_file(self.file_name,self.userid).deliver_now
    when Freereg1CsvFile.userid(self.userid).file_name(self.file_name).transcriber_lock.exists?
      message =   "You have done on-line edits to the file, so it is locked against replacement until you have downloaded and edited the file."
      ok = false
    when Freereg1CsvFile.userid(self.userid).file_name(self.file_name).coordinator_lock.exists?
      message =   "The file you are trying to replace has been locked by your coordinator."
      ok = false
    when batch_entries == 0
      batch = PhysicalFile.new(:base => true,:base_uploaded_date => Time.now,:file_processed => false, :userid =>self.userid , :file_name => self.file_name)
      batch.save
    when batch_entries == 1
      batch = PhysicalFile.where(userid: self.userid, file_name: self.file_name).first
      batch.update_attributes(:base => true,:base_uploaded_date => Time.now,:file_processed => false)
    else
      message =   "A situation has occurred that should not have. Please have your coordinator contact system administration."
      ok = false
    end
    return[ok,batch]
  end

end
