class MultipleBatches

require 'chapman_code'
require "place"
include Mongoid::Document

  def self.process(limit)
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
  	file_for_warning_messages = "log/multiple_batches.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    message_file = File.new(file_for_warning_messages, "w")
  	limit = limit.to_i
    puts "checking #{limit} documents for multiple batches in the files collection"
    missing_records = 0
    number = 0
  	Freereg1CsvFile.distinct(:file_name).each  do |file_name|
      number = number + 1
      files = Freereg1CsvFile.where(:file_name => file_name).all
        files.distinct(:userid).each do |user|
            user_files = Freereg1CsvFile.where(:file_name => file_name, :userid => user).all 
             if user_files.length >= 2
               missing_records = missing_records + 1
               break if  missing_records == limit
                 puts "\" #{file_name}\",  #{user_files.length}, batches" 
                 message_file.puts   "\" #{file_name}\", #{user_files.length}, batches" 
                 user_files.each do |file|
                    message_file.puts   "\" #{file_name}\",\" #{file.userid}\", \" #{file.place}\",\" #{file.church_name}\",\" #{file.county}\"" 
                 end
             end
        end 
    end 
    puts "There were #{missing_records} multiple batch files in #{number} processed records"  
  end
end