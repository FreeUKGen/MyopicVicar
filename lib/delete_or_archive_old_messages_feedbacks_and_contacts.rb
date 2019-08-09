class DeleteOrArchiveOldMessagesFeedbacksAndContacts
  class << self
    def process
      #The purpose of this clean up utility is to eliminate search records that are unconnected with an entry. Or an entry without a batch
      Mongoid.load!("#{Rails.root}/config/mongoid.yml")
      Mongoid.raise_not_found_error = false
      file_for_warning_messages = 'log/delete_old_messages_feedbacks_and_contacts.log'
      FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
      message_file = File.new(file_for_warning_messages, 'w')
      days_until_delete = 2 * Rails.application.config.days_to_retain_messages
      days_until_archive = Rails.application.config.days_to_retain_messages
      @delete_records_less_than = DateTime.now - days_until_delete.days
      @report_delete_less_than = @delete_records_less_than + 30.days
      @archive_records_less_than = DateTime.now - days_until_archive.days
      @report_records_less_than = @archive_records_less_than + 30.days

      title = "Running actual active test of the message clean up process on test3 on #{DateTime.now.strftime('%Y_%m_%d')} with #{days_until_archive} days until archive
    and #{days_until_delete} days until deletion. Now includes syndicate and communication messages.
    Actual archiving and deletion will occur in this test"
      action_message = "To avoid cluttering the system with stale communications we have a 4 stage process.
    1) alerting that a communication is to be archived the next next time this clean up process runs.
    2) that it has been archived today by this process.
    3) that it will be deleted in the next process
    4) that it has been deleted by this process.
    You may of course archive a communication earlier if you wish.
    You may also set its KEEP status and the communication will not be deleted."
      message_file.puts title

      stage = "Feedback processing"
      message_file.puts stage
      p stage
      process_feedbacks(stage, title, action_message)

      stage = 'Contact processing'
      message_file.puts stage
      p stage
      process_contacts(stage, title, action_message)

      stage = 'Data Problem processing'
      message_file.puts stage
      p stage
      process_data_problem_contacts(stage, title, action_message)

      stage = 'Message processing'
      message_file.puts stage
      p stage
      process_general_messages(stage, title, action_message)

      stage = 'Syndicate message processing'
      message_file.puts stage
      p stage
      process_syndicate_messages(stage, title, action_message)

      stage = 'Communications processing'
      message_file.puts stage
      p stage
      process_individual_messages(stage, title, action_message)
    end

    def process_feedbacks(stage, title, action_message)
      file_for_feedback_messages = "#{Rails.root}/log/feedback.log"
      feedback_message_file = File.new(file_for_feedback_messages, 'w')
      feedback_message_file.puts title
      feedback_message_file.puts action_message
      feedback_message_file.puts stage
      send_email = false
      send_email = true
      stage = "Active feedbacks due for archiving in next process run (Usually monthly)"
      p stage
      feedback_message_file.puts stage
      Feedback.archived(false).keep(false).each do |record|
        if record.created_at <= @report_records_less_than
          send_email = true
          feedback_message_file.puts "#{record.identifier}, created on #{record.created_at}"
        end
      end
      stage = "Active feedbacks being archived now"
      p stage
      feedback_message_file.puts stage
      Feedback.archived(false).keep(false).each do |record|
        if record.created_at <= @archive_records_less_than
          send_email = true
          feedback_message_file.puts "#{record.identifier}, created on #{record.created_at}"
          record.update_attribute(:archived, true)
        end
      end
      stage = "Archived feedbacks due for deletion in next process run (Usually monthly)"
      p stage
      feedback_message_file.puts stage
      Feedback.archived(true).keep(false).each do |record|
        if record.created_at <= @report_delete_less_than
          send_email = true
          feedback_message_file.puts "#{record.identifier}, created on #{record.created_at}"
        end
      end
      stage = "Archived feedbacks deleted now"
      p stage
      feedback_message_file.puts stage
      Feedback.archived(true).keep(false).each do |record|
        if record.created_at <= @delete_records_less_than
          send_email = true
          feedback_message_file.puts "#{record.identifier}, deleted"
          record.destroy
        end
      end
      feedback_message_file.close
      send_logs(send_email, file_for_feedback_messages, feedback_message_file, 'Feedback', nil)
    end

    def process_contacts(stage, title, action_message)
      file_for_contact_messages = "#{Rails.root}/log/contact.log"
      contact_message_file = File.new(file_for_contact_messages, 'w')
      contact_message_file.puts title
      contact_message_file.puts action_message
      send_email = false
      send_email = true
      stage = "Active contacts (except Data Problems) due for archiving in next process run (Usually monthly)"
      p stage
      contact_message_file.puts stage
      Contact.archived(false).keep(false).each do |record|
        if record.contact_type != 'Data Problem' && record.created_at <= @report_records_less_than
          send_email = true
          contact_message_file.puts "#{record.identifier}, created on #{record.created_at}"
        end
      end
      stage = "Active contacts (except Data Problems) being archived now"
      p stage
      contact_message_file.puts stage
      Contact.archived(false).keep(false).each do |record|
        if record.contact_type != 'Data Problem' && record.created_at <= @archive_records_less_than
          send_email = true
          contact_message_file.puts "#{record.identifier}, created on #{record.created_at}"
          record.update_attribute(:archived, true)
        end
      end
      stage = "Archived contacts (except Data Problems) due for deletion in next process run (Usually monthly)"
      p stage
      contact_message_file.puts stage
      Contact.archived(true).keep(false).each do |record|
        if record.contact_type != 'Data Problem' && record.created_at <= @report_delete_less_than
          send_email = true
          contact_message_file.puts "#{record.identifier}, created on #{record.created_at}"
        end
      end
      stage = "Archived contacts (except Data Problems) deleted now"
      p stage
      contact_message_file.puts stage

      Contact.archived(true).keep(false).each do |record|
        if record.contact_type != 'Data Problem' && record.created_at <= @delete_records_less_than
          send_email = true
          contact_message_file.puts "#{record.identifier}, deleted"
          record.destroy
        end
      end
      contact_message_file.close
      send_logs(send_email, file_for_contact_messages, contact_message_file, 'Contact', nil)
    end

    def process_data_problem_contacts(stage, title, action_message)
      counties = Contact.distinct(:chapman_code)
      p counties
      counties.each do |chapman|
        send_email = false
        send_email = true
        file_for_dp_messages = "#{Rails.root}/log/#{chapman}_data_problem_messages.log"
        dp_message_file = File.new(file_for_dp_messages, 'w')
        dp_message_file.puts title
        dp_message_file.puts action_message
        stage = "Active Data Problem due to be archived for #{chapman} in next process run (Usually monthly)"
        p stage
        dp_message_file.puts stage
        Contact.chapman_code(chapman).archived(false).keep(false).each do |record|
          if record.created_at <= @report_records_less_than
            send_email = true
            dp_message_file.puts "#{record.identifier}, created on #{record.created_at}"
          end
        end
        stage = "Active Data Problem being archived for #{chapman} now"
        p stage
        dp_message_file.puts stage
        Contact.chapman_code(chapman).archived(false).keep(false).each do |record|
          if record.created_at <= @archive_records_less_than
            send_email = true
            dp_message_file.puts "#{record.identifier}, created on #{record.created_at}"
            record.update_attribute(:archived, true)
          end
        end
        stage = "Archived Data Problem due for deletion for #{chapman} in next process run (Usually monthly)"
        p stage
        dp_message_file.puts stage
        Contact.chapman_code(chapman).archived(true).keep(false).each do |record|
          if record.created_at <= @report_delete_less_than
            send_email = true
            dp_message_file.puts "#{record.identifier}, created on #{record.created_at}"
          end
        end
        stage = "Archived Data Problem deleted for #{chapman} now"
        p stage
        dp_message_file.puts stage
        Contact.chapman_code(chapman).archived(true).keep(false).each do |record|
          if record.created_at <= @delete_records_less_than
            send_email = true
            dp_message_file.puts "#{record.identifier}, deleted"
            record.destroy
          end
        end
        dp_message_file.close
        send_logs(send_email, file_for_dp_messages, dp_message_file, 'Data Problem', chapman)
      end
    end

    def process_general_messages(stage, title, action_message)
      file_for_message_messages = "#{Rails.root}/log/message.log"
      message_message_file = File.new(file_for_message_messages, 'w')
      message_message_file.puts title
      message_message_file.puts action_message
      send_email = false
      send_email = true
      stage = "Active general messages due to be archived in next process run (Usually monthly)"
      p stage
      message_message_file.puts stage
      Message.general.non_reply_messages.archived(false).keep(false).each do |record|
        if record.created_at <= @report_records_less_than && record.source_message_id.blank? && record.source_feedback_id.blank? && record.source_contact_id.blank?
          send_email = true
          message_message_file.puts "#{record.identifier}, created on #{record.created_at}"
        end
      end
      stage = "Active general messages being archived now"
      p stage
      message_message_file.puts stage
      Message.general.non_reply_messages.archived(false).keep(false).each do |record|
        if record.created_at <= @archive_records_less_than && record.source_message_id.blank? && record.source_feedback_id.blank? && record.source_contact_id.blank?
          send_email = true
          message_message_file.puts "#{record.identifier}, created on #{record.created_at}"
          record.update_attribute(:archived, true)
        end
      end
      stage = "Archived general messages due for deletion in next process run (Usually monthly)"
      p stage
      message_message_file.puts stage
      Message.general.non_reply_messages.archived(true).keep(false).each do |record|
        if record.created_at <= @report_delete_less_than && record.source_message_id.blank? && record.source_feedback_id.blank? && record.source_contact_id.blank?
          send_email = true
          message_message_file.puts "#{record.identifier}, created on #{record.created_at}"
        end
      end
      stage = "Archived general messages deleted in next process run (Usually monthly)"
      p stage
      message_message_file.puts stage
      Message.general.non_reply_messages.archived(true).keep(false).each do |record|
        if record.created_at <= @delete_records_less_than && record.source_message_id.blank? && record.source_feedback_id.blank? && record.source_contact_id.blank?
          send_email = true
          message_message_file.puts "#{record.identifier}, deleted"
          record.destroy
        end
      end
      message_message_file.close
      send_logs(send_email, file_for_message_messages, message_message_file, 'General Message', nil)
    end

    def process_syndicate_messages(stage, title, action_message)
      syndicates = Message.distinct(:syndicate).compact.reject {|e| e.blank?}.reject {|e| e == 'all'}
      p syndicates
      syndicates.each do |syndicate|
        p syndicate
        send_email = false
        send_email = true
        file_for_syndicate_messages = "#{Rails.root}/log/#{syndicate}_messages.log"
        syndicate_message_file = File.new(file_for_syndicate_messages, 'w')
        syndicate_message_file.puts title
        syndicate_message_file.puts action_message
        stage = "Active syndicate messages due to be archived in next process run (Usually monthly)"
        p stage
        syndicate_message_file.puts stage
        Message.syndicate(syndicate).non_reply_messages.archived(false).keep(false).each do |record|
          if record.created_at <= @report_records_less_than && record.source_message_id.blank? && record.source_feedback_id.blank? && record.source_contact_id.blank?
            send_email = true
            syndicate_message_file.puts "#{record.identifier}, created on #{record.created_at}"
          end
        end
        stage = "Active syndicate messages being archived now"
        p stage
        syndicate_message_file.puts stage
        Message.syndicate(syndicate).non_reply_messages.archived(false).keep(false).each do |record|
          if record.created_at <= @archive_records_less_than && record.source_message_id.blank? && record.source_feedback_id.blank? && record.source_contact_id.blank?
            send_email = true
            syndicate_message_file.puts "#{record.identifier}, created on #{record.created_at}"
            record.update_attribute(:archived, true)
          end
        end
        stage = "Archived syndicate messages due for deletion in next process run (Usually monthly)"
        p stage
        syndicate_message_file.puts stage
        Message.syndicate(syndicate).non_reply_messages.archived(true).keep(false).each do |record|
          if record.created_at <= @report_delete_less_than
            send_email = true
            syndicate_message_file.puts "#{record.identifier}, created on #{record.created_at}"
          end
        end
        stage = "Archived syndicate messages deleted now"
        p stage
        syndicate_message_file.puts stage
        Message.syndicate(syndicate).non_reply_messages.archived(true).keep(false).each do |record|
          if record.created_at <= @delete_records_less_than
            send_email = true
            syndicate_message_file.puts "#{record.identifier}, deleted"
            record.destroy
          end
        end
        syndicate_message_file.close
        send_logs(send_email, file_for_syndicate_messages, syndicate_message_file, 'Syndicate', syndicate)
      end
    end

    def process_individual_messages(stage, title, action_message)
      individuals = Message.distinct(:userid).compact
      p individuals

      individuals.each do |individual|
        p individual
        send_email = false
        send_email = true
        file_for_individual_messages = "#{Rails.root}/log/#{individual}_messages.log"
        individual_message_file = File.new(file_for_individual_messages, 'w')
        individual_message_file.puts title
        individual_message_file.puts action_message
        stage = "Active individual communications due to be archived in next process run (Usually monthly)"
        p stage
        individual_message_file.puts stage
        Message.userid(individual).non_reply_messages.archived(false).keep(false).each do |record|
          if record.created_at <= @report_records_less_than && record.source_message_id.blank? && record.source_feedback_id.blank? && record.source_contact_id.blank?
            send_email = true
            individual_message_file.puts "#{record.identifier}, created on #{record.created_at}"
          end
        end
        stage = "Active individual communications being archived now"
        p stage
        individual_message_file.puts stage
        Message.userid(individual).non_reply_messages.archived(false).keep(false).each do |record|
          if record.created_at <= @archive_records_less_than && record.source_message_id.blank? && record.source_feedback_id.blank? && record.source_contact_id.blank?
            send_email = true
            individual_message_file.puts "#{record.identifier}, created on #{record.created_at}"
            record.update_attribute(:archived, true)
          end
        end
        stage = "Archived individual communications due for deletion in next process run (Usually monthly)"
        p stage
        individual_message_file.puts stage
        Message.userid(individual).non_reply_messages.archived(true).keep(false).each do |record|
          if record.created_at <= @report_delete_less_than
            send_email = true
            individual_message_file.puts "#{record.identifier}, created on #{record.created_at}"
          end
        end
        stage = "Archived individual communications deleted now"
        p stage
        individual_message_file.puts stage
        Message.userid(individual).non_reply_messages.archived(true).keep(false).each do |record|
          if record.created_at <= @delete_records_less_than
            send_email = true
            individual_message_file.puts "#{record.identifier}, deleted"
            record.destroy
          end
        end
        individual_message_file.close
        send_logs(send_email, file_for_individual_messages, individual_message_file, 'Individual', individual)
      end
    end

    def send_logs(send_email, log_file_location, log_file, message_nature, specific)
      p 'send_logs//////////////////////'
      p send_email
      p log_file_location
      p log_file
      p message_nature
      p specific
      if send_email
        send_to = recipients(message_nature, specific)
        p 'No recipients' if send_to.blank?
        return if send_to.blank?

        UserMailer.send_logs(log_file, send_to, "#{message_nature} messages #{specific}", "#{message_nature} messages #{specific} archiving report").deliver_now
      else
        File.delete(log_file_location) if File.exist?(log_file_location)
      end
    end

    def recipients(type, specific)
      p 'recipientslllllllllllllllllllllllllllllll'
      p MyopicVicar::Application.config.template_set
      p type
      p specific
      case MyopicVicar::Application.config.template_set
      when 'freereg'
        case type
        when 'Feedback'
          recipients = freereg_feedbacks
        when 'Contact'
          recipients = freereg_contacts
        when 'Data Problem'
          recipients = freereg_data_problems(specific)
        when 'General Message'
          recipients = freereg_messages
        when 'Syndicate'
          recipients = freereg_syndicate(specific)
        when 'Individual'
          recipients = freereg_individuals(specific)
        end
      when 'freecen'
        case type
        when 'Feedback'
          recipients = freecen_feedbacks
        when 'Contact'
          recipients = freecen_contacts
        when 'Data Problem'
          recipients = freecen_data_problems(specific)
        when 'General Message'
          recipients = freecen_messages
        when 'Syndicate'
          recipients = freecen_syndicate(specific)
        when 'Individual'
          recipients = freecen_individuals(specific)
        end
      when 'freebmd'
        case type
        when 'Feedback'
          recipients = freebmd_feedbacks
        when 'Contact'
          recipients = freebmd_feedbacks
        when 'Data Problem'
          recipients = freebmd_data_problems(specific)
        when 'General Message'
          recipients = freebmd_nessages
        when 'Syndicate'
          recipients = freebmd_syndicate(specific)
        when 'Individual'
          recipients = freebmd_individuals(specific)
        end
      end
      p recipients
      recipients
    end

    def freereg_feedbacks
      send_to = []
      managera = UseridDetail.find_by(userid: 'REGManager')
      send_to << managera.email_address if managera.present?
      managerb = UseridDetail.find_by(userid: 'SBManager')
      send_to << managerb.email_address if managerb.present?
      send_to << UseridDetail.role('system_administrator').first.email_address if send_to.blank?
      send_to
    end

    def freereg_contacts
      send_to = []
      managera = UseridDetail.find_by(role: 'contacts_coordinator')
      send_to << managera.email_address if managera.present?
      managerb = UseridDetail.find_by(userid: 'SBManager')
      send_to << managerb.email_address if managerb.present?
      send_to << UseridDetail.role('system_administrator').first.email_address if send_to.blank?
      send_to
    end

    def freereg_data_problems(chapman)
      send_to = []
      managera = County.coordinator_email_address(chapman)
      send_to << managera if managera.present?
      managerb = UseridDetail.find_by(role: 'contacts_coordinator')
      send_to << managerb.email_address if managerb.present?
      send_to << UseridDetail.role('system_administrator').first.email_address if send_to.blank?
      send_to
    end

    def freereg_messages
      send_to = []
      managera = UseridDetail.find_by(userid: 'REGManager')
      send_to << managera.email_address if managera.present?
      managerb = UseridDetail.find_by(userid: 'SBManager')
      send_to << managerb.email_address if managerb.present?
      send_to << UseridDetail.role('system_administrator').first.email_address if send_to.blank?
      send_to
    end

    def freereg_syndicate(syndicate)
      send_to = []
      managera = Syndicate.find_by(syndicate_code: syndicate)
      managera = UseridDetail.find_by(userid: managera)
      send_to << managera.email_address if managera.present?
      managerb = UseridDetail.find_by(userid: 'SBManager')
      send_to << managerb.email_address if managerb.present?
      send_to
    end

    def freereg_individuals(individual)
      send_to = []
      managera = UseridDetail.find_by(userid: individual)
      send_to << managera.email_address if managera.present?
      managerb = UseridDetail.find_by(userid: 'SBManager')
      send_to << managerb.email_address if managerb.present? && managera.blank?
      send_to
    end

    def freecen_feedbacks
      send_to = []
      send_to << UseridDetail.role('system_administrator').first.email_address
      send_to
    end

    def freecen_contacts
      send_to = []
      managera = UseridDetail.find_by(role: 'contacts_coordinator')
      send_to << managera.email_address if managera.present?
      send_to << UseridDetail.role('system_administrator').first.email_address if send_to.blank?
      send_to
    end

    def freecen_data_problems(chapman)
      send_to = []
      managera = County.coordinator_email_address(chapman)
      send_to << managera if managera.present?
      managerb = UseridDetail.find_by(role: 'contacts_coordinator')
      send_to << managerb.email_address if managerb.present?
      send_to << UseridDetail.role('system_administrator').first.email_address if send_to.blank?
      send_to
    end

    def freecen_messages
      send_to = []
      send_to << UseridDetail.role('system_administrator').first.email_address if send_to.blank?
      send_to
    end

    def freecen_syndicate(syndicate)
      send_to = []
      managera = Syndicate.find_by(syndicate_code: syndicate)
      managera = UseridDetail.find_by(userid: managera)
      send_to << managera.email_address if managera.present?
      send_to << UseridDetail.role('system_administrator').first.email_address if send_to.blank?
      send_to
    end

    def freecen_individuals(individual)
      p 'freecen_individuals'
      p individual
      send_to = []
      managera = UseridDetail.find_by(userid: individual)
      send_to << managera.email_address if managera.present?
      send_to << UseridDetail.role('system_administrator').first.email_address if send_to.blank?
      send_to
    end

    def freebmd_feedbacks
      send_to = []
      send_to << UseridDetail.role('system_administrator').first.email_address if send_to.blank?
      send_to
    end

    def freebmd_contacts
      send_to = []
      managera = UseridDetail.find_by(role: 'contacts_coordinator')
      send_to << managera.email_address if managera.present?
      send_to << UseridDetail.role('system_administrator').first.email_address if send_to.blank?
      send_to
    end

    def freebmd_data_problems(chapman)
      send_to = []
      managera = County.coordinator_email_address(chapman)
      send_to << managera if managera.present?
      managerb = UseridDetail.find_by(role: 'contacts_coordinator')
      send_to << managerb.email_address if managerb.present?
      send_to << UseridDetail.role('system_administrator').first.email_address if send_to.blank?
      send_to
    end

    def freebmd_messages
      send_to = []
      send_to << UseridDetail.role('system_administrator').first.email_address
      send_to
    end

    def freebmd_syndicate(syndicate)
      send_to = []
      managera = Syndicate.find_by(syndicate_code: syndicate)
      managera = UseridDetail.find_by(userid: managera)
      send_to << managera.email_address if managera.present?
      send_to << UseridDetail.role('system_administrator').first.email_address if send_to.blank?
      send_to
    end

    def freebmd_individuals(individual)
      send_to = []
      managera = UseridDetail.find_by(userid: individual)
      send_to << managera.email_address if managera.present?
      send_to << UseridDetail.role('system_administrator').first.email_address if send_to.blank?
      send_to
    end
  end
end
