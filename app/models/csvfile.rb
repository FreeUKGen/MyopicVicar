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
    errors.add(:file_name, "File already exits and has been processed. You need to replace the existing file") unless  PhysicalFile.where(userid: self.userid, file_name: self.file_name,file_processed: true).first.nil?
  end
  def save_and_estimate_time
    batch = PhysicalFile.new(:userid => self.userid, :file_name => self.file_name, :base =>true, :base_uploaded_date => Time.now, :file_processed => false)
    batch.save
    processing_time = self.estimate_time
  end
  def estimate_time
    place = File.join(Rails.application.config.datafiles,self.userid,self.file_name)
    size = (File.size("#{place}"))
    unit = 0.001
    processing_time = (size.to_i*unit).to_i 
  end
  def check_for_existing_unprocessed_file
   batch = PhysicalFile.where(userid: self.userid, file_name: self.file_name,:base => true,:file_processed => false).first
   unless batch.nil?
    file_location = File.join(Rails.application.config.datafiles,self.userid,self.file_name)
    if File.file?(file_location)
      newdir = File.join(File.join(Rails.application.config.datafiles,self.userid),'.attic')
      Dir.mkdir(newdir) unless Dir.exists?(newdir)
      time = Time.now.to_i.to_s
      renamed_file = (file_location + "." + time).to_s
      File.rename(file_location,renamed_file)
      FileUtils.mv(renamed_file,newdir,:verbose => true)
      user =UseridDetail.where(:userid => self.userid).first
      unless user.nil?
        attic_file = AtticFile.new(:name => "#{file}.#{time}", :date_created => DateTime.strptime(time,'%s'), :userid_detail_id => user.id)
        attic_file.save
      end
    else
      p "file does not exist"
    end
    batch.destroy
  end
  true
  end
end
