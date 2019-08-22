class CheckSearchRecordsWithNullEntry
  require 'chapman_code'

  def initialize
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
  end

  def self.process(limit, do_we_fix)
    file_for_warning_messages = 'log/check_search_records_messages.log'
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    message_file = File.new(file_for_warning_messages, 'w')
    limit = limit.to_i
    fix = false
    fix = true if do_we_fix == 'fix'

    p "checking #{limit} documents for null entries in the search records collection with fix of #{fix}"
    record_number = 0
    SearchRecord.where(freereg1_csv_entry_id: nil).no_timeout.each do |my_entry|
      record_number = record_number + 1
      break if record_number == limit
      entries = Freereg1CsvEntry.where(line_id: my_entry.line_id).all
      if entries.length.zero?
        message_file.puts "#{my_entry.id},#{my_entry.line_id}, 'No matching entry'"
      else
        entries.each do |entry|
          records = SearchRecord.where(freereg1_csv_entry_id: entry.id).all
          if records.blank?
            if fix
              my_entry.update_attribute(:freereg1_csv_entry_id, entry.id)
              message_file.puts "#{my_entry.id},#{my_entry.line_id}, #{entry.id}, 'fixed'"
            else
              message_file.puts "#{my_entry.id},#{my_entry.line_id}, #{entry.id}"
            end
          else
            records.each do |record|
              if fix
                my_entry.update_attribute(:freereg1_csv_entry_id, entry.id) unless my_entry.freereg1_csv_entry_id == entry.id
                message_file.puts "#{my_entry.id},#{my_entry.id},#{my_entry.line_id}, #{entry.id}, 'fixed'" unless my_entry.freereg1_csv_entry_id == entry.id
                message_file.puts "#{my_entry.id},#{my_entry.line_id}, #{record.id}, 'deleted'"
                record.destroy
              else
                message_file.puts "#{my_entry.id},#{my_entry.line_id}, #{record.id}, 'duplicated record'"
              end
            end

          end
        end
      end
    end
    puts "checked #{record_number} entries "
  end
end
