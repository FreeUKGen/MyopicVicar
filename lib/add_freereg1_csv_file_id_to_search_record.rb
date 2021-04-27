class AddFreereg1CsvFileIdToSearchRecord
  def self.process(limit)
    limit = limit.to_i
    file_for_warning_messages = "log/add_freereg1_csv_file_id_to_search_record.txt"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
    message_file = File.new(file_for_warning_messages, 'w')
    process_files = 0
    record_numbers = 0
    Freereg1CsvFile.no_timeout.each do |file|
      process_files += 1
      break if process_files > limit

      file_id = file.id
      entries = Freereg1CsvEntry.where(freereg1_csv_file_id: file_id).all
      entries.no_timeout.each do |entry|
        record_numbers += 1
        entry.search_record.update_attributes(freereg1_csv_file_id: file_id)
      end
      p "Finished #{file.file_name}"
      message_file.puts "#{file.file_name}"
    end
    p "Finished #{process_files} files with #{record_numbers} records"
  end
end
