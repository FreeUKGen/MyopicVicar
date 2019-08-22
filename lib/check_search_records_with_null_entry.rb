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

      p "checking #{limit} documents for null entries in the search records collection with fix of #{fix}"
      record_number = 0
      previous_date = 0
      previous_line_id = 0
      previous_id = 0
      SearchRecord.where(freereg1_csv_entry_id: nil).order_by(u_at: 1).no_timeout.each do |my_entry|
        p my_entry
        record_number = record_number + 1
        break if record_number == limit

        continue = CheckSearchRecordsWithNullEntry.delete_previous_entry(previous_date, previous_line_id, previous_id, my_entry, fix, message_file)
        p "Could not delete record #{previous_date}, #{previous_line_id}, #{previous_id}, #{my_entry.id}" unless continue
        break unless continue

        previous_date, previous_line_id, previous_id = CheckSearchRecordsWithNullEntry.previous(my_entry)
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
                  message_file.puts "#{my_entry.id},#{my_entry.line_id}, #{entry.id}, 'fixed'" unless my_entry.freereg1_csv_entry_id == entry.id
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

    def previous(record)
      previous_date = record.u_at
      previous_line_id = record.line_id
      previous_id = record.id
      [previous_date, previous_line_id, previous_id]
    end

    def delete_previous_entry(previous_date, previous_line_id, previous_id, my_entry, fix, message_file)
      continue = false
      date_check = false
      line_check = false
      date_check = true if my_entry.u_at >= previous_date
      line_check = true if my_entry.line_id == previous_line_id
      previous = SearchRecord.find(previous_id) if date_check && line_check
      previous.destroy if previous.present? && date_check && line_check && fix
      p "Destroying #{previous_id}" if previous.present? && date_check && line_check
      message_file.puts "#{previous_id}, destroyed as duplicate empty " if previous.present? && date_check && line_check && fix
      continue = true unless line_check
      continue
    end
  end
end
