class CheckRecordDigest
  require 'chapman_code'
  require "#{Rails.root}/app/models/freereg1_csv_file"
  require "#{Rails.root}/app/models/freereg1_csv_entry"
  require "#{Rails.root}/app/models/search_record"
  include Mongoid::Document

  def self.process(limit)
    file_for_warning_messages = File.join(Rails.root, "log/check_record_digest.log")
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    message_file = File.new(file_for_warning_messages, "w")
    limit = limit.to_i
    puts "Checking #{limit} record_digest for duplicates"
    record_number = 0
    Freereg1CsvFile.no_timeout.each do |file|
      actual_duplicates = 0
      record_number = record_number + 1 
      break if record_number == limit
      name = file.file_name
      entries = file.freereg1_csv_entries
      record_digest_array = Array.new
      entries.each do |entry|
          record_digest_array << entry.record_digest unless entry.record_digest.nil?
      end
      unique_record_digest_array = Array.new
      unique_record_digest_array = record_digest_array.uniq
      len = record_digest_array.length
      if record_digest_array.length > unique_record_digest_array.length
          dups = record_digest_array.length - unique_record_digest_array.length
          message_file.puts "We have #{dups} duplicates in file #{name} of #{len} entries #{record_digest_array.length} and #{unique_record_digest_array.length}"
          unique_record_digest_array.each do |bb|
            record_digest_array.delete_at(record_digest_array.index(bb))
          end
          record_digest_array.each do |dup|
            duplicates = Freereg1CsvEntry.where(:freereg1_csv_file_id => file._id, :record_digest => dup).all
            number = 0
            duplicates.each do |record|
              number = number + 1
              if number == 1
                @one = record
              else 
                case record.record_type
                when RecordType::BAPTISM
                     string = Freereg1CsvEntry.compare_baptism_fields?(@one,record)
                when RecordType::MARRIAGE
                     string = Freereg1CsvEntry.compare_marriage_fields?(@one,record)
                when RecordType::BURIAL
                     string = Freereg1CsvEntry.compare_burial_fields?(@one,record)
                else
                    false
                end
                if !string
                  message_file.puts "We have different records"
                  message_file.puts @one.line_id 
                  message_file.puts "#{@one.inspect}"
                  message_file.puts record.line_id 
                  message_file.puts "#{record.inspect}"
                  actual_duplicates = actual_duplicates + 1 
                end
               
              end
            end
          end
          p "#{actual_duplicates}"
        end
     end
  end
end
