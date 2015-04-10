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
    file_for_warning_messages = "log/check_search_records_messages.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    message_file = File.new(file_for_warning_messages, "w")
    limit = limit.to_i
    freereg1_csv_file = CheckSearchRecords.new
    #missing_search_record = Array.new

    puts "checking #{limit} documents for missing entries in the search records collection"
    record_number = 0
    missing_records = 0
    process_records = 0
    Freereg1CsvEntry.no_timeout.each do |my_entry|
      record_number = record_number + 1
      unless my_entry.search_record?
        missing_records = missing_records + 1
        #message_file.puts " #{my_entry.line_id},#{my_entry.place},#{my_entry.church_name},#{my_entry.register_type}"
        #message_file.puts my_entry
        my_entry.transform_search_record
      end

      break if record_number == limit
      process_records = process_records + 1
      if process_records == 100000 then
        puts "#{record_number}"
        process_records = 0
      end
    end
    puts "checked #{record_number} entries there were #{missing_records} missing search records"

    message_file.puts "checked #{record_number} entries there were #{missing_records} missing search records"

  end
end
