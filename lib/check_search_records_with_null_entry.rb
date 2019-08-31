class CheckSearchRecordsWithNullEntry
  require 'chapman_code'

  def initialize
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
  end

  class << self
    def process(limit, do_we_fix)
      file_for_warning_messages = 'log/check_search_records_messages.log'
      FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
      message_file = File.new(file_for_warning_messages, 'w')
      limit = limit.to_i
      fix = false
      fix = true if do_we_fix == 'fix'

      p "checking documents for null entries in the search records collection with fix of #{fix}"
      null_search_records = SearchRecord.where(freereg1_csv_entry_id: nil).order_by(u_at: 1).all
      null_search_records.uniq!
      message_file.puts 'Number'
      message_file.puts null_search_records.length
      null_search_records.each do |record|
        message_file.puts record.line_id
        entries = Freereg1CsvEntry.where(line_id: record.line_id).order_by(u_at: 1).all
        if entries.present? && entries.length > 1
          message_file.puts 'greater than 1'
          message_file.puts record.inspect
          entries.each do |entry|
            message_file.puts entry.inspect
          end
          message_file.puts 'fine tune'
          if record.record_type == 'ba'
            entry = Freereg1CsvEntry.where(freereg1_csv_file_id: entries.first.freereg1_csv_file_id,  line_id: record.line_id, person_forename: record.transcript_names[0]["first_name"], father_surname: record.transcript_names[0]["last_name"]).order_by(u_at: 1).all
          elsif record.record_type == 'ma'
            entry = Freereg1CsvEntry.where(freereg1_csv_file_id: entries.first.freereg1_csv_file_id,  line_id: record.line_id, bride_forename: record.transcript_names[0]["first_name"], bride_surname: record.transcript_names[0]["last_name"]).order_by(u_at: 1).all
          end
          if entry.present? && entry.length > 1
            message_file.puts 'too many entries'
            entry.each do |ent|
              message_file.puts ent.inspect
            end
          elsif entry.present? && entry.length == 1
            message_file.puts 'single entry'
            message_file.puts entry.inspect
            record.update_attribute(:freereg1_csv_entry_id, entry.first.id)
            message_file.puts 'record updated'
            message_file.puts record.inspect
          elsif entry.blank?
            message_file.puts 'no entry'
          end

        elsif entries.present? && entries.length == 1
          message_file.puts 'equal 1'
          message_file.puts record.inspect
          message_file.puts entries.first.inspect
          search_records = SearchRecord.where(search_date: record.search_date, chapman_code: record.chapman_code, place_id: record.place_id, line_id: record.line_id).order_by(u_at: 1).all
          if search_records.length > 1
            message_file.puts 'multiple records'
            search_records.each do |search_record|
              message_file.puts search_record.inspect
            end
            message_file.puts 'first multiple destroyed'
            search_records.first.destroy
          else
            message_file.puts 'single record'
            record.update_attribute(:freereg1_csv_entry_id, entries.first.id)
            message_file.puts 'record updated'
            message_file.puts record.inspect
          end
        elsif entries.blank?
          message_file.puts "No entry for #{record.line_id}"
          message_file.puts record.inspect
          record.destroy
          message_file.puts 'record destroyed'
        end
      end
    end
  end
end
