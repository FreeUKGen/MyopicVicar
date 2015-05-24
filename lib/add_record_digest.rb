class AddRecordDigest
  require 'chapman_code'
  require "#{Rails.root}/app/models/freereg1_csv_file"
  require "#{Rails.root}/app/models/freereg1_csv_entry"
  require "#{Rails.root}/app/models/search_record"
  include Mongoid::Document

  def initialize
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
  end

  def self.process(limit,range)
    file_for_warning_messages = "log/add_record_digest.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    message_file = File.new(file_for_warning_messages, "w")
    limit = limit.to_i
    initiate = AddRecordDigest.new
    puts "Adding #{limit} record_digest to entries for #{range}"
    base_directory = Rails.application.config.datafiles
    filenames = GetFiles.get_all_of_the_filenames(base_directory,range)
    message_file.puts "#{filenames.length}\t files selected for processing\n"
    process_records = 0
    filenames.each do |file|
      record_number = 0
     file_parts = file.split("/")
     file_name = file_parts[-1]
     file_handle = file_name.split(".")
      Freereg1CsvFile.where(:file_name => file_parts[-1], :userid => file_parts[-2]).each do |file|
        num = Freereg1CsvEntry.where(:freereg1_csv_file_id => file._id).count
        p "processing #{file_parts[-2]} #{file_parts[-1]} with #{num} entries"
        Freereg1CsvEntry.where(:freereg1_csv_file_id => file._id).no_timeout.each do |my_entry| 
          record_number = record_number + 1
          my_entry.save 
          break if process_records == limit
          process_records = process_records + 1
          if process_records == 100000 then
            puts "#{record_number}" 
            process_records = 0
          end
        end
      end
      puts "Added #{record_number} record_digest entries for #{file_parts[-1]} "
      message_file.puts "Added #{record_number} record_digest entries for #{file_parts[-1]}"
    end
  end
end
