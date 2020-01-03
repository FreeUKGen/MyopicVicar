class AddEmbargoRecord
  def self.process(limit)
    time = Time.new.strftime("%s")
    file_for_warning_messages = Rails.root.join('log', "add_embargo_records_#{time}.log")
    message_file = File.new(file_for_warning_messages, 'w')
    input_file = Rails.root.join(Rails.application.config.register_embargo_list)
    lines = []
    int = 0
    message_file.puts "Starting adding embargo at #{Time.now}"
    if File.exist?(input_file)
      File.foreach(input_file) do |line|
        line_parts = line.split(',')
        lines << line_parts[0] unless lines.include?(line_parts[0])
        int = int + 1
      end
    end
    File.truncate(input_file, 0)
    message_file.puts "Processing #{lines.length} registers with a limit of #{limit}"
    message_file.puts lines
    total_records = 0
    total_files = 0
    total_registers = 0
    sleep_time_twenty = 20 * (Rails.application.config.sleep.to_f).to_f
    files_processed = 0
    lines.each do |line|
      total_registers = total_registers + 1
      break if total_registers.to_i > limit.to_i && limit.to_i != 0

      parts = line.split(',')
      register = Register.find(parts[0])
      next if register.blank?

      message_file.puts 'processing register'
      message_file.puts register.inspect
      rules = register.embargo_rules.order_by(created_at: 1)
      next if rules.blank?

      userids = []
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
        message_file.puts files_for_record_type.inspect

        next if files_for_record_type.blank?

        files_for_record_type.each do |file|
          message_file.puts 'processing file'
          message_file.puts file.inspect
          files_processed = files_processed + 1
          total_files = total_files + 1
          entries_processed = 0

          file.freereg1_csv_entries.no_timeout.each do |entry|
            entries_processed = entries_processed + 1
            end_year = 0
            end_year = EmbargoRecord.process_embargo_year(rule, entry.year) if entry.year.present?
            message_file.puts entry.inspect
            message_file.puts entry.embargo_records.inspect
            message_file.puts entry.already_has_this_embargo?(rule)
            change, embargo_record = entry.process_embargo(rule)
            next unless change

            total_records = total_records + 1
            entry.embargo_records << embargo_record
            saved = entry.save
            message_file.puts "save failed #{entry.embargo_records.last.errors.full_messages}" unless saved
            entry.search_record.update(embargoed: entry.embargo_records.last.embargoed, release_year: end_year)
            entry.save
            message_file.puts 'final entry and search record'
            message_file.puts entry.inspect
            message_file.puts entry.search_record.inspect
          end
          message_file.puts "#{entries_processed} were processed for file"
          sleep sleep_time_twenty
        end
        userids << rule.member_who_created unless userids.include?(rule.member_who_created)
      end
    end

    message_file.puts " #{total_files} files processed and #{total_records} records were embargoed"
    message_file.close
    emails = []
    userids.each do |user|
      person = UseridDetail.find_by(_id: user)
      emails << person.email_address if person.present?
    end
    UserMailer.send_logs(file_for_warning_messages, emails, 'Details of the processing of your embargo rule', 'Embargo completion report').deliver_now
  end
end
