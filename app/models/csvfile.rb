class Csvfile < CarrierWave::Uploader::Base
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  field :userid, type: String
  field :file_name,type: String
  field :process,type: String, default: 'Scheduled'
    belongs_to :freereg1_csv_file
  #validate :csvfile_already_exists, on: :create

mount_uploader :csvfile, CsvfileUploader

def csvfile_already_exists
    errors.add(:file_name, "File already exits") unless  Freereg1CsvFile.where(userid: self.userid, file_name: self.file_name).first.nil?
end

def save_to_attic
	#to-do unix permissions

 
	 file = self.file_name
   csvdir = File.join(Rails.application.config.datafiles,self.userid)
   csvfile = File.join(csvdir,file)
       if File.file?(csvfile)
   	    newdir = File.join(csvdir,'.attic')
    	  Dir.mkdir(newdir) unless Dir.exists?(newdir)
        renamed_file = (csvfile + "." + (Time.now.to_i).to_s).to_s
      	File.rename(csvfile,renamed_file)
	      FileUtils.mv(renamed_file,newdir, verbose:  true)
       else 
   	     p "file does not exist"
        end
 end

end
