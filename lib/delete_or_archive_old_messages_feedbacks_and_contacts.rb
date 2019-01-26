class DeleteOrArchiveOldMessagesFeedbacksAndContacts

  def self.process
    #The purpose of this clean up utility is to eliminate search records that are unconnected with an entry. Or an entry without a batch
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    Mongoid.raise_not_found_error = false
    file_for_warning_messages = "log/delete_old_messages_feedbacks_and_contacts.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    message_file = File.new(file_for_warning_messages, "w")
    days_until_delete = 2 * Rails.application.config.days_to_retain_messages
    days_until_archive = Rails.application.config.days_to_retain_messages
    remaining_days = days_until_archive + 10
    delete_records_less_than = DateTime.now - days_until_delete.days
    archive_records_less_than = DateTime.now - days_until_archive.days
    report_records_less_than = DateTime.now - (days_until_archive + 10).days
    days_until_report = Rails.application.config.days_to_retain_messages - 10
    p "Running message delete with an age of #{days_until_delete} or older than #{delete_records_less_than}"
    p "Messages will be archived in #{days_until_archive} and reported in #{days_until_report}"
    message_file.puts "Running message delete with an age of #{days_until_delete} or older than #{delete_records_less_than}"
    message_file.puts "Messages will be archived in #{days_until_archive} and reported in #{days_until_report}"

    p DateTime.now
    p report_records_less_than
    p archive_records_less_than
    p delete_records_less_than

    Feedback.no_timeout.each do |record|
      if record.keep.blank? && record.created_at <= report_records_less_than
        message_file.puts " Feedback #{record.identifier} created on #{record.created_at} is due for archiving in 10 days and deletion in #{remaining_days} days"
      end
    end

    Contact.no_timeout.each do |record|
      if record.keep.blank? && record.created_at <= report_records_less_than
        message_file.puts " Contact #{record.identifier} created on #{record.created_at} is due for archiving in 10 days and deletion in #{remaining_days} days"
      end
    end

    Message.no_timeout.each do |record|
      if record.keep.blank? && record.source_message_id.blank? && record.created_at <= report_records_less_than
        message_file.puts "Message #{record.identifier} created on #{record.created_at} is due for archiving in 10 days and deletion in #{remaining_days} days" unless record.source_message_id.present? ||
          record.source_feedback_id.present? || record.source_contact_id.present?
      end
    end

    Feedback.no_timeout.each do |record|
      if record.keep.blank? && record.created_at <= delete_records_less_than
        message_file.puts "Feedback #{record.identifier} deleted"
        #record.destroy
      end
    end

    Contact.no_timeout.each do |record|
      if record.keep.blank? && record.created_at <= delete_records_less_than
        message_file.puts "Contact #{record.identifier} deleted"
        #record.destroy
      end
    end

    Message.no_timeout.each do |record|
      if record.keep.blank? && record.created_at <= delete_records_less_than
        message_file.puts "Message #{record.identifier} deleted" unless record.source_message_id.present? ||
          record.source_feedback_id.present? || record.source_contact_id.present?
        #record.destroy
      end
    end
  end
end
