class UseridsFiles


 
require 'chapman_code'
require "freereg1_csv_file"
require "person_detail"
require "place"
include Mongoid::Document
 


 
  def initialize
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    
  end

  def self.process(syndicate)
    database = UseridsFiles.new
  	file_for_report = "log/check_userids_report"
    FileUtils.mkdir_p(File.dirname(file_for_report) ) 
    message_file = File.new(file_for_report, "w")
  	limit = limit.to_i
    p "Report for userids who have been disabled"
     message_file.puts "Report for userids who have been disabled"
  	record_number = 0
  	missing_records = 0
  	process_records = 0
    userids = PersonDetail.where(:active => false).all
    userids.each do |userid|
      userfiles = Freereg1CsvFile.where(:userid => userid.userid).all
      if userfiles.nil?
  	    message_file.puts "#{userid.userid} has no files" 
      else
        message_file.puts "#{userid.userid} has #{userfiles.length} files" 
      end
     end
    
  end
end