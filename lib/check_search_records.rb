class CheckSearchRecords


 
require 'chapman_code'

require "#{Rails.root}/app/models/freereg1_csv_file"
require "#{Rails.root}/app/models/freereg1_csv_entry"
require "#{Rails.root}/app/models/search_record"
include Mongoid::Document
 


 
  def initialize
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    
  end

  def self.process(limit)
  	file_for_warning_messages = "logs/check_search_records_messages.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    message_file = File.new(file_for_warning_messages, "a")
  	limit = limit.to_i
    freereg1_csv_file = CheckSearchRecords.new
  	missing_search_record = Array.new
  	
  	puts "checking #{limit} documents for missing entries in the search records collection"
  	record_number = 0
  	missing_records = 0
  	process_records = 0
  	Freereg1CsvEntry.each do |my_entry|
  	  record_number = record_number + 1
  	  my_id = my_entry._id      
      my_search_record = SearchRecord.where(:freereg1_csv_entry_id => my_id).exists?
      unless my_search_record then
      	missing_records = missing_records + 1
      	missing_search_record[missing_records] = record_number
      	puts "search record is missing for entry numer #{record_number} id #{my_id}"
      end
      break if record_number == limit
      process_records = process_records + 1
      if process_records == 100000 then
      puts "#{record_number}"
      process_records = 0
      end  
    end
    puts "checked #{record_number} entries there were #{missing_records} missing search records"
    message_file.puts missing_search_records
  end
end