class AddEmbargoRecord
  def self.process(limit)
    file_for_warning_messages = Rails.root.join('log', 'add_embargo_records.log')
    message_file = File.new(file_for_warning_messages, 'w')
    input_file = Rails.application.config.register_embargo_list
    lines = []
    int = 0
    message_file.puts "Starting adding embargo at #{Time.now}"
    if File.exist?(input_file)
      File.foreach(input_file) do |line|
        lines << line
        int = int + 1
      end
    else

    end
    message_file.puts "Processing #{int} registers"
    #File.truncate(input_file, 0)
    lines = lines.uniq
    message_file.puts lines
    total_records = 0
    total_files = 0
    sleep_time_twenty = 20*(Rails.application.config.sleep.to_f).to_f
    files_processed = 0
    lines.each do |line|
      parts = line.split(",")
      register = Register.find(parts[0])
      next if register.blank?

      message_file.puts 'processing register'
      message_file.puts register.inspect
      rules = register.embargo_rules
      next if rules.blank?

      rules.each do |rule|
        message_file.puts 'processing rule'
        record_type = rule.record_type
        message_file.puts rule.inspect
        all_files = register.freereg1_csv_files
        next if all_files.blank?

        files_for_record_type = []
        all_files.each do |file|
          files_for_record_type << file if file.record_type == record_type
        end
        files_for_record_type.each do |file|
          message_file.puts 'processing file'
          message_file.puts file.inspect
          files_processed = files_processed + 1
          total_files = total_files + 1
          break if total_files == limit.to_i

          file.freereg1_csv_entries.no_timeout.each do |entry|
            end_year = EmbargoRecord.process_embargo_year(rule, entry.year) if entry.year.present?
            next if DateTime.now.year.to_i >= end_year

            total_records = total_records + 1
            message_file.puts entry.inspect
            message_file.puts entry.embargo_records.inspect
            entry.process_embargo
            entry.search_record.update(embargoed: entry.embargo_records.last.embargoed, release_year: end_year)
            message_file.puts 'final entry and search record'
            message_file.puts entry.inspect
            message_file.puts entry.search_record.inspect
          end
          sleep sleep_time_twenty
        end
      end
    end
    message_file.puts " #{total_files} files processed and #{total_records} records were embargoed"
    message_file.close
  end
end
