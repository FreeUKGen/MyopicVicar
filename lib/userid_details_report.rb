class UseridDetailsReport


 
require 'chapman_code'

include Mongoid::Document
 


 
  def initialize
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    
  end


  def self.process(limit)

  	file_for_messages = "log/userid_details_report.log"
    FileUtils.mkdir_p(File.dirname(file_for_messages) )
    message_file = File.new(file_for_messages, "w")
  	limit = limit.to_i
 
    puts "Producing report of documents in the Userid Details collection"
    message_file.puts "Userid,Syndicate,Person Surname,Person Forename,email address,Active,Last Upload,Number of Files,Number of Records,Person Role"

    record_number = 0
  	missing_records = 0
  	process_records = 0
    number = UseridDetail.count

    userids = UseridDetail.all

  	userids.each do |my_entry|
      if my_entry.last_upload.nil?
        my_entry.last_upload = DateTime.new(1970,1,1)
      end
      message_file.puts "\"#{my_entry.userid}\",\" #{my_entry.syndicate}\",\" #{my_entry.person_surname}\",\"#{my_entry.person_forename}\",\"#{my_entry.email_address}\",\" #{my_entry.active}\",\" #{my_entry.last_upload.strftime("%d %b %Y")}\",\"#{my_entry.number_of_files}\",\"#{my_entry.number_of_records}\",\" #{my_entry.person_role}\"\n" 
      end #place
  p "Finished #{number} records"
    
  end
end