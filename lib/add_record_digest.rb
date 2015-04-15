class AddRecordDigest
  require 'chapman_code'
  require "#{Rails.root}/app/models/freereg1_csv_file"
  require "#{Rails.root}/app/models/freereg1_csv_entry"
  require "#{Rails.root}/app/models/search_record"
  include Mongoid::Document

  def initialize
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
  end

  def self.process(limit)
    file_for_warning_messages = "log/add_record_digest.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    message_file = File.new(file_for_warning_messages, "w")
    limit = limit.to_i
    freereg1_csv_file = AddRecordDigest.new
    puts "Adding #{limit} record_digest to entries"
    record_number = 0
    process_records = 0
    Freereg1CsvEntry.no_timeout.each do |my_entry|
      record_number = record_number + 1
      my_entry.save
      break if record_number == limit
      process_records = process_records + 1
      if process_records == 100000 then
        puts "#{record_number}"
        process_records = 0
      end
    end
    puts "Added #{record_number} record_digest entries "
    message_file.puts "Added #{record_number} record_digest entries "
  end
end
