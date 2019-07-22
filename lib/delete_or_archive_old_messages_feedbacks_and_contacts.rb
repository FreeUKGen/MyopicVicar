class DeleteOrArchiveOldMessagesFeedbacksAndContacts

  def self.process
    #The purpose of this clean up utility is to eliminate search records that are unconnected with an entry. Or an entry without a batch
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")
    Mongoid.raise_not_found_error = false
    file_for_warning_messages = 'log/delete_old_messages_feedbacks_and_contacts.log'
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
    message_file = File.new(file_for_warning_messages, 'w')
    days_until_delete = 2 * Rails.application.config.days_to_retain_messages
    days_until_archive = Rails.application.config.days_to_retain_messages
    delete_records_less_than = DateTime.now - days_until_delete.days
    report_delete_less_than = delete_records_less_than + 30.days
    archive_records_less_than = DateTime.now - days_until_archive.days
    report_records_less_than = archive_records_less_than + 30.days

    days_until_report = Rails.application.config.days_to_retain_messages - 30
    p "Running message delete with an age of #{days_until_delete} or older than #{delete_records_less_than}"
    p "Messages will be archived in #{days_until_archive} and reported in #{days_until_report}"
    message_file.puts "Running message delete with an age of #{days_until_delete} or older than #{delete_records_less_than}"
    message_file.puts "Messages will be archived in #{days_until_archive} and reported in #{days_until_report}"
    file_for_feedback_messages = 'log/feedback.log'
    feedback_message_file = File.new(file_for_feedback_messages, 'w')
    file_for_contact_messages = 'log/contact.log'
    contact_message_file = File.new(file_for_contact_messages, 'w')
    file_for_message_messages = 'log/message.log'
    message_message_file = File.new(file_for_message_messages, 'w')
    p DateTime.now
    p report_records_less_than
    p archive_records_less_than
    p delete_records_less_than

    stage = 'Feedback processing'
    message_file.puts stage
    p stage
    feedback_message_file.puts stage
    stage = 'Active feedbacks due for archiving'
    p stage
    feedback_message_file.puts stage
    Feedback.archived(false).keep(false).each do |record|
      if record.created_at <= report_records_less_than
        feedback_message_file.puts "#{record.identifier}, created on #{record.created_at}"
      end
    end
    stage = 'Active feedbacks being archived'
    p stage
    feedback_message_file.puts stage
    Feedback.archived(false).keep(false).each do |record|
      if record.created_at <= archive_records_less_than
        feedback_message_file.puts "#{record.identifier}, created on #{record.created_at}"
        #record.update_attribute(:archived, true)
      end
    end
    stage = 'Archived feedbacks due for deletion'
    p stage
    feedback_message_file.puts stage
    Feedback.archived(true).keep(false).each do |record|
      if record.created_at <= report_delete_less_than
        feedback_message_file.puts "#{record.identifier}, created on #{record.created_at}"
        #record.update_attribute(:archived, true)
      end
    end
    stage = 'Archived feedbacks deleted'
    p stage
    feedback_message_file.puts stage
    Feedback.archived(true).keep(false).each do |record|
      if record.created_at <= delete_records_less_than
        feedback_message_file.puts "#{record.identifier}, deleted"
        #record.destroy
      end
    end

    stage = 'Contact processing'
    message_file.puts stage
    p stage
    stage = 'Active contacts (except Data Problems) due for archiving'
    p stage
    contact_message_file.puts stage
    Contact.archived(false).keep(false).each do |record|
      if record.contact_type != 'Data Problem' && record.created_at <= report_records_less_than
        contact_message_file.puts "#{record.identifier}, created on #{record.created_at}"
      end
    end
    stage = 'Active contacts (except Data Problems) being archived'
    p stage
    contact_message_file.puts stage
    Contact.archived(false).keep(false).each do |record|
      if record.contact_type != 'Data Problem' && record.created_at <= archive_records_less_than
        contact_message_file.puts "#{record.identifier}, created on #{record.created_at}"
        #record.update_attribute(:archived, true)
      end
    end
    stage = 'Archived contacts (except Data Problems) due for deletion'
    p stage
    contact_message_file.puts stage
    Contact.archived(true).keep(false).each do |record|
      if record.contact_type != 'Data Problem' && record.created_at <= report_delete_less_than
        contact_message_file.puts "#{record.identifier}, created on #{record.created_at}"
        #record.update_attribute(:archived, true)
      end
    end
    stage = 'Archived contacts (except Data Problems) deleted'
    p stage
    contact_message_file.puts stage

    Contact.archived(true).keep(false).each do |record|
      if record.contact_type != 'Data Problem' && record.created_at <= delete_records_less_than
        contact_message_file.puts "#{record.identifier}, deleted"
        #record.destroy
      end
    end

    stage = 'Data Problem processing'
    message_message_file.puts stage
    p stage
    counties = Contact.distinct(:chapman_code)
    p counties
    counties.each do |chapman|
      file_for_dp_messages = "log/#{chapman}_data_problem_messages.log"
      dp_message_file = File.new(file_for_dp_messages, 'w')
      stage = "Active Data Problem due to be archived for #{chapman}"
      p stage
      dp_message_file.puts stage
      Contact.chapman_code(chapman).archived(false).keep(false).each do |record|
        if record.created_at <= report_records_less_than
          dp_message_file.puts "#{record.identifier}, created on #{record.created_at}"
          #record.update_attribute(:archived, true)
        end
      end
      stage = "Active Data Problem being archived for #{chapman}"
      p stage
      contact_message_file.puts stage
      Contact.chapman_code(chapman).archived(false).keep(false).each do |record|
        if record.created_at <= archive_records_less_than
          contact_message_file.puts "#{record.identifier}, created on #{record.created_at}"
          #record.update_attribute(:archived, true)
        end
      end
      stage = "Archived Data Problem due for deletion for #{chapman}"
      p stage
      contact_message_file.puts stage
      Contact.chapman_code(chapman).archived(true).keep(false).each do |record|
        if record.created_at <= report_delete_less_than
          contact_message_file.puts "#{record.identifier}, created on #{record.created_at}"
          #record.update_attribute(:archived, true)
        end
      end
      stage = "Archived Data Problem deleted for #{chapman}"
      p stage
      contact_message_file.puts stage

      Contact.chapman_code(chapman).archived(true).keep(false).each do |record|
        if record.created_at <= delete_records_less_than
          contact_message_file.puts "#{record.identifier}, deleted"
          #record.destroy
        end
      end
    end

    stage = 'Message processing'
    message_message_file.puts stage
    p stage
    stage = 'Active message due to be archived'
    p stage
    message_message_file.puts stage
    Message.archived(false).keep(false).each do |record|
      if record.created_at <= report_records_less_than
        message_message_file.puts "#{record.identifier}, created on #{record.created_at}" unless record.source_message_id.present? ||
          record.source_feedback_id.present? || record.source_contact_id.present?
      end
    end
    stage = 'Active messages being archived'
    p stage
    message_message_file.puts stage
    Message.archived(false).keep(false).each do |record|
      if record.created_at <= archive_records_less_than
        message_message_file.puts "#{record.identifier}, created on #{record.created_at}" unless record.source_message_id.present? ||
          record.source_feedback_id.present? || record.source_contact_id.present?
        #record.update_attribute(:archived, true)
      end
    end
    stage = 'Archived messages due for deletion'
    p stage
    message_message_file.puts stage
    Message.archived(true).keep(false).each do |record|
      if record.created_at <= report_delete_less_than
        message_message_file.puts "#{record.identifier}, created on #{record.created_at}" unless record.source_message_id.present? ||
          record.source_feedback_id.present? || record.source_contact_id.present?
      end
    end
    stage = 'Archived messages deleted'
    p stage
    message_message_file.puts stage
    Message.archived(true).keep(false).each do |record|
      if record.created_at <= delete_records_less_than
        message_message_file.puts "#{record.identifier}, deleted" unless record.source_message_id.present? ||
          record.source_feedback_id.present? || record.source_contact_id.present?
        #record.destroy
      end
    end
  end
end
