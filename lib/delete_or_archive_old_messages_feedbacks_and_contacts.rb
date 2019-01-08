class DeleteOrArchiveOldMessagesFeedbacksAndContacts

  def self.process
    #The purpose of this clean up utility is to eliminate search records that are unconnected with an entry. Or an entry without a batch
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    Mongoid.raise_not_found_error = false
    file_for_warning_messages = "log/delete_old_messages_feedbacks_and_contacts.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    message_file = File.new(file_for_warning_messages, "w")
    days_until_delete = Rails.application.config.days_to_retain_search_queries
    delete_records_less_than = DateTime.now - Rails.application.config.days_to_retain_search_queries.days
    report_records_less_than = DateTime.now - (Rails.application.config.days_to_retain_search_queries + 10).days
    p days_until_delete
    p delete_records_less_than
    p report_records_less_than
    p
    p "Running message delete with an age of #{days_until_delete}"
    message_file.puts "Running message delete with an age of #{days_until_delete}"
    Feedback.no_timeout.each do |record|
      if record.keep.blank? && record.created_at <= report_records_less_than
        message_file.puts "Feedback #{record.identifier} due for deletion in 10 days"
      end
    end

    Contact.no_timeout.each do |record|
      if record.keep.blank? && record.created_at <= report_records_less_than
        message_file.puts " Contact #{record.identifier} due for deletion in 10 days"
      end
    end

    Message.no_timeout.each do |record|
      if record.keep.blank? && record.source_message_id.blank? && record.created_at <= report_records_less_than
        message_file.puts "Message #{record.identifier} due for deletion in 10 days"
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
        message_file.puts "Message #{record.identifier} deleted"
        #record.destroy
      end
    end
  end
end
