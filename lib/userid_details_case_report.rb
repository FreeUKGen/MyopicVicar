class UseridDetailsCaseReport 
require 'chapman_code'
include Mongoid::Document
def initialize
    Mongoid.load!("#{Rails.root}/config/mongoid.yml") 
end


  def self.process(limit)

  	file_for_messages = "log/userid_details_case_report.log"
    FileUtils.mkdir_p(File.dirname(file_for_messages) )
    message_file = File.new(file_for_messages, "w")
  	limit = limit.to_i
 
    puts "Producing report of case sensitive Userid Details "
    
    dups = 0
    lim = 0
    number = UseridDetail.count

    userids = UseridDetail.all

  	userids.each do |my_entry|
      lim = lim + 1
       break if lim == limit
     if UseridDetail.where(:userid_lower_case => my_entry.userid_lower_case).count > 1
     	dups = dups + 1
        duplicates = UseridDetail.where(:userid_lower_case => my_entry.userid_lower_case).all
        duplicates.each do |dup|
        message_file.puts my_entry.userid dup.userid
      end
     
    end #userid
  end #each
  p "Finished #{number} records with #{dups} duplicates"
    
  end
end