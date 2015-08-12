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
    errors.add(:file_name, "File already exits and has been processed. You need to replace the existing file") unless  Freereg1CsvFile.where(userid: self.userid, file_name: self.file_name).first.nil?
  end
  def save_and_estimate_time
    batch = PhysicalFile.new(:userid => self.userid, :file_name => self.file_name, :change => true,:change_uploaded_date =>Time.now, :base =>false, :base_uploaded_date => nil)
    batch.save
    processing_time = self.estimate_time
  end
  def estimate_time
    place = File.join(Rails.application.config.datafiles_changeset,self.userid,self.file_name)
    size = (File.size("#{place}"))
    unit = 0.001
    processing_time = (size.to_i*unit).to_i 
  end
  def check_for_existing_unprocessed_file
    batch = PhysicalFile.where(userid: self.userid, file_name: self.file_name,:change => true,:file_processed => false).first
    unless batch.nil?
      place = File.join(Rails.application.config.datafiles_changeset,self.userid,self.file_name)
      File.delete(place) if File.exist?(place)
      batch.destroy
    end
      proceed = true
  end
end
