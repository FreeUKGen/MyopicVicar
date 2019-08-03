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

    title = "Running message clean up on #{DateTime.now.strftime('%Y_%m_%d')} with #{days_until_archive} days until archive and #{days_until_delete} days until deletion"
    action_message = "To avoid cluttering the system with stale communications we have a 4 stage process. 1) alerting that a communication is to be archived the next next time this clean up process runs. 2) that it has been archived by this process. 3) that it will be deleted in the next process 4) that it has been deleted.
You may of course archive a communication earlier if you wish. You may also set its KEEP status and the communication will not be deleted."
    message_file.puts title
    file_for_feedback_messages = "#{Rails.root}/log/feedback.log"
    feedback_message_file = File.new(file_for_feedback_messages, 'w')
    feedback_message_file.puts title
    feedback_message_file.puts action_message
    file_for_contact_messages = "#{Rails.root}/log/contact.log"
    contact_message_file = File.new(file_for_contact_messages, 'w')
    contact_message_file.puts title
    contact_message_file.puts action_message
    file_for_message_messages = "#{Rails.root}/log/message.log"
    message_message_file = File.new(file_for_message_messages, 'w')
    message_message_file.puts title
    message_message_file.puts action_message

    stage = "Feedback processing"
    message_file.puts stage
    p stage
    send_email = false
    feedback_message_file.puts stage
    stage = "Active feedbacks due for archiving #{report_records_less_than.strftime('%Y_%m_%d')}"
    p stage
    feedback_message_file.puts stage
    Feedback.archived(false).keep(false).each do |record|
      if record.created_at <= report_records_less_than
        send_email = true
        feedback_message_file.puts "#{record.identifier}, created on #{record.created_at}"
      end
    end
    stage = "Active feedbacks being archived #{archive_records_less_than.strftime('%Y_%m_%d')}"
    p stage
    feedback_message_file.puts stage
    Feedback.archived(false).keep(false).each do |record|
      if record.created_at <= archive_records_less_than
        send_email = true
        feedback_message_file.puts "#{record.identifier}, created on #{record.created_at}"
        #record.update_attribute(:archived, true)
      end
    end
    stage = "Archived feedbacks due for deletion #{delete_records_less_than.strftime('%Y_%m_%d')}"
    p stage
    feedback_message_file.puts stage
    Feedback.archived(true).keep(false).each do |record|
      if record.created_at <= report_delete_less_than
        send_email = true
        feedback_message_file.puts "#{record.identifier}, created on #{record.created_at}"
        #record.update_attribute(:archived, true)
      end
    end
    stage = "Archived feedbacks deleted"
    p stage
    feedback_message_file.puts stage
    Feedback.archived(true).keep(false).each do |record|
      if record.created_at <= delete_records_less_than
        send_email = true
        feedback_message_file.puts "#{record.identifier}, deleted"
        #record.destroy
      end
    end
    feedback_message_file.close
    if send_email

      p "mailing"
      send_to = []
      managera = UseridDetail.find_by(userid: 'REGManager')
      send_to << managera.email_address if managera.present?
      managerb = UseridDetail.find_by(userid: 'SBManager')
      send_to << managerb.email_address if managerb.present?
      send_to << UseridDetail.role('system_administrator').first.email_address if send_to.blank?
      p send_to
      UserMailer.send_logs(feedback_message_file, send_to, 'feedback messages', 'feedback messages archiving report').deliver_now
    else
      File.delete(file_for_feedback_messages) if File.exist?(file_for_feedback_messages)
    end

    stage = 'Contact processing'
    message_file.puts stage
    p stage
    send_email = false
    stage = "Active contacts (except Data Problems) due for archiving #{report_records_less_than.strftime('%Y_%m_%d')}"
    p stage
    contact_message_file.puts stage
    Contact.archived(false).keep(false).each do |record|
      if record.contact_type != 'Data Problem' && record.created_at <= report_records_less_than
        send_email = true
        contact_message_file.puts "#{record.identifier}, created on #{record.created_at}"
      end
    end
    stage = "Active contacts (except Data Problems) being archived #{archive_records_less_than.strftime('%Y_%m_%d')}"
    p stage
    contact_message_file.puts stage
    Contact.archived(false).keep(false).each do |record|
      if record.contact_type != 'Data Problem' && record.created_at <= archive_records_less_than
        send_email = true
        contact_message_file.puts "#{record.identifier}, created on #{record.created_at}"
        #record.update_attribute(:archived, true)
      end
    end
    stage = "Archived contacts (except Data Problems) due for deletion #{delete_records_less_than.strftime('%Y_%m_%d')}"
    p stage
    contact_message_file.puts stage
    Contact.archived(true).keep(false).each do |record|
      if record.contact_type != 'Data Problem' && record.created_at <= report_delete_less_than
        send_email = true
        contact_message_file.puts "#{record.identifier}, created on #{record.created_at}"
        #record.update_attribute(:archived, true)
      end
    end
    stage = "Archived contacts (except Data Problems) deleted"
    p stage
    contact_message_file.puts stage

    Contact.archived(true).keep(false).each do |record|
      if record.contact_type != 'Data Problem' && record.created_at <= delete_records_less_than
        send_email = true
        contact_message_file.puts "#{record.identifier}, deleted"
        #record.destroy
      end
    end
    contact_message_file.close
    if send_email

      p 'mailing'
      managera = UseridDetail.find_by(role: 'contacts_coordinator')
      send_to << managera.email_address if managera.present?
      managerb = UseridDetail.find_by(userid: 'SBManager')
      send_to << managerb.email_address if managerb.present?
      send_to << UseridDetail.role('system_administrator').first.email_address if send_to.blank?
      p send_to
      UserMailer.send_logs(contact_message_file, send_to, 'contact messages', 'contact messages archiving report').deliver_now
    else
      File.delete(file_for_contact_messages) if File.exist?(file_for_contact_messages)
    end

    stage = 'Data Problem processing'
    message_file.puts stage
    p stage
    counties = Contact.distinct(:chapman_code)
    p counties
    counties.each do |chapman|
      send_email = false
      file_for_dp_messages = "#{Rails.root}/log/#{chapman}_data_problem_messages.log"
      dp_message_file = File.new(file_for_dp_messages, 'w')
      dp_message_file.puts title
      dp_message_file.puts action_message
      stage = "Active Data Problem due to be archived for #{chapman} #{report_records_less_than.strftime('%Y_%m_%d')}"
      p stage
      dp_message_file.puts stage
      Contact.chapman_code(chapman).archived(false).keep(false).each do |record|
        if record.created_at <= report_records_less_than
          send_email = true
          dp_message_file.puts "#{record.identifier}, created on #{record.created_at}"
          #record.update_attribute(:archived, true)
        end
      end
      stage = "Active Data Problem being archived for #{chapman} #{archive_records_less_than.strftime('%Y_%m_%d')}"
      p stage
      dp_message_file.puts stage
      Contact.chapman_code(chapman).archived(false).keep(false).each do |record|
        if record.created_at <= archive_records_less_than
          send_email = true
          dp_message_file.puts "#{record.identifier}, created on #{record.created_at}"
          #record.update_attribute(:archived, true)
        end
      end
      stage = "Archived Data Problem due for deletion for #{chapman} #{delete_records_less_than.strftime('%Y_%m_%d')}"
      p stage
      dp_message_file.puts stage
      Contact.chapman_code(chapman).archived(true).keep(false).each do |record|
        if record.created_at <= report_delete_less_than
          send_email = true
          dp_message_file.puts "#{record.identifier}, created on #{record.created_at}"
          #record.update_attribute(:archived, true)
        end
      end
      stage = "Archived Data Problem deleted for #{chapman}"
      p stage
      dp_message_file.puts stage
      Contact.chapman_code(chapman).archived(true).keep(false).each do |record|
        if record.created_at <= delete_records_less_than
          send_email = true
          dp_message_file.puts "#{record.identifier}, deleted"
          #record.destroy
        end
      end
      dp_message_file.close
      if send_email

        p 'mailing'
        send_to = []
        managera = County.coordinator_email_address(chapman)
        send_to << managera if managera.present?
        managerb = UseridDetail.find_by(role: 'contacts_coordinator')
        send_to << managerb.email_address if managerb.present?
        send_to << UseridDetail.role('system_administrator').first.email_address if send_to.blank?
        p send_to
        UserMailer.send_logs(dp_message_file, send_to, "#{chapman} Data Problem contacts", "#{chapman } Data Problem contact archiving report").deliver_now
      else
        File.delete(file_for_dp_messages) if File.exist?(file_for_dp_messages)
      end

    end

    stage = 'Message processing'
    message_file.puts stage
    p stage
    send_email = false
    stage = "Active message due to be archived #{report_records_less_than.strftime('%Y_%m_%d')}"
    p stage
    message_message_file.puts stage
    Message.general.non_reply_messages.archived(false).keep(false).each do |record|
      if record.created_at <= report_records_less_than && record.source_message_id.blank? && record.source_feedback_id.blank? && record.source_contact_id.blank?
        send_email = true
        message_message_file.puts "#{record.identifier}, created on #{record.created_at}"
      end
    end
    stage = "Active messages being archived #{archive_records_less_than.strftime('%Y_%m_%d')}"
    p stage
    message_message_file.puts stage
    Message.general.non_reply_messages.archived(false).keep(false).each do |record|
      if record.created_at <= archive_records_less_than && record.source_message_id.blank? && record.source_feedback_id.blank? && record.source_contact_id.blank?
        send_email = true
        message_message_file.puts "#{record.identifier}, created on #{record.created_at}"
        #record.update_attribute(:archived, true)
      end
    end
    stage = "Archived messages due for deletion #{delete_records_less_than.strftime('%Y_%m_%d')}"
    p stage
    message_message_file.puts stage
    Message.general.non_reply_messages.archived(true).keep(false).each do |record|
      if record.created_at <= report_delete_less_than && record.source_message_id.blank? && record.source_feedback_id.blank? && record.source_contact_id.blank?
        send_email = true
        message_message_file.puts "#{record.identifier}, created on #{record.created_at}"
      end
    end
    stage = "Archived messages deleted"
    p stage
    message_message_file.puts stage
    Message.general.non_reply_messages.archived(true).keep(false).each do |record|
      if record.created_at <= delete_records_less_than && record.source_message_id.blank? && record.source_feedback_id.blank? && record.source_contact_id.blank?
        send_email = true
        message_message_file.puts "#{record.identifier}, deleted"
        #record.destroy
      end
    end
    message_message_file.close
    if send_email

      p 'mailing'
      send_to = []
      managera = UseridDetail.find_by(userid: 'REGManager')
      send_to << managera.email_address if managera.present?
      p send_to
      managerb = UseridDetail.find_by(userid: 'SBManager')
      send_to << managerb.email_address if managerb.present?
      p send_to
      send_to << UseridDetail.role('system_administrator').first.email_address if send_to.blank?
      p send_to
      UserMailer.send_logs(message_message_file, send_to, 'General messages', 'General messages archiving report').deliver_now
    else
      File.delete(file_for_message_messages) if File.exist?(file_for_message_messages)
    end

    stage = 'Syndicate message processing'
    message_file.puts stage
    syndicates = Message.distinct(:syndicate).compact.reject {|e| e.blank?}.reject {|e| e == 'all'}
    p syndicates
    p stage
    syndicates.each do |syndicate|
      p syndicate
      send_email = false
      file_for_syndicate_messages = "#{Rails.root}/log/#{syndicate}_messages.log"
      syndicate_message_file = File.new(file_for_syndicate_messages, 'w')
      syndicate_message_file.puts title
      syndicate_message_file.puts action_message
      stage = "Active message due to be archived #{report_records_less_than.strftime('%Y_%m_%d')}"
      p stage
      syndicate_message_file.puts stage
      Message.syndicate(syndicate).non_reply_messages.archived(false).keep(false).each do |record|
        if record.created_at <= report_records_less_than && record.source_message_id.blank? && record.source_feedback_id.blank? && record.source_contact_id.blank?
          send_email = true
          syndicate_message_file.puts "#{record.identifier}, created on #{record.created_at}"
        end
      end
      stage = "Active messages being archived #{archive_records_less_than.strftime('%Y_%m_%d')}"
      p stage
      syndicate_message_file.puts stage
      Message.syndicate(syndicate).non_reply_messages.archived(false).keep(false).each do |record|
        if record.created_at <= archive_records_less_than && record.source_message_id.blank? && record.source_feedback_id.blank? && record.source_contact_id.blank?
          send_email = true
          syndicate_message_file.puts "#{record.identifier}, created on #{record.created_at}"
          #record.update_attribute(:archived, true)
        end
      end
      stage = "Archived messages due for deletion #{delete_records_less_than.strftime('%Y_%m_%d')}"
      p stage
      syndicate_message_file.puts stage
      Message.syndicate(syndicate).non_reply_messages.archived(true).keep(false).each do |record|
        if record.created_at <= report_delete_less_than
          send_email = true
          syndicate_message_file.puts "#{record.identifier}, created on #{record.created_at}"
        end
      end
      stage = "Archived messages deleted"
      p stage
      syndicate_message_file.puts stage
      Message.syndicate(syndicate).non_reply_messages.archived(true).keep(false).each do |record|
        if record.created_at <= delete_records_less_than
          send_email = true
          syndicate_message_file.puts "#{record.identifier}, deleted"
          #record.destroy
        end
      end
      syndicate_message_file.close
      if send_email

        p 'mailing'
        send_to = []
        managera = Syndicate.find_by(syndicate_code: syndicate)
        send_to << managera.email_address if managera.present?
        p send_to
        managerb = UseridDetail.find_by(userid: 'SBManager')
        send_to << managerb.email_address if managerb.present?
        p send_to
        UserMailer.send_logs(syndicate_message_file, send_to, 'Syndicate messages', 'Syndicate messages archiving report').deliver_now
      else
        File.delete(file_for_syndicate_messages) if File.exist?(file_for_syndicate_messages)
      end
    end
    stage = 'Communications processing'
    message_file.puts stage
    individuals = Message.distinct(:userid).compact
    p individuals
    p stage
    individuals.each do |individual|
      p individual
      send_email = false
      file_for_individual_messages = "#{Rails.root}/log/#{individual}_messages.log"
      individual_message_file = File.new(file_for_individual_messages, 'w')
      individual_message_file.puts title
      individual_message_file.puts action_message
      stage = "Active message due to be archived #{report_records_less_than.strftime('%Y_%m_%d')}"
      p stage
      individual_message_file.puts stage
      Message.userid(individual).non_reply_messages.archived(false).keep(false).each do |record|
        if record.created_at <= report_records_less_than && record.source_message_id.blank? && record.source_feedback_id.blank? && record.source_contact_id.blank?
          send_email = true
          individual_message_file.puts "#{record.identifier}, created on #{record.created_at}"
        end
      end
      stage = "Active messages being archived #{archive_records_less_than.strftime('%Y_%m_%d')}"
      p stage
      individual_message_file.puts stage
      Message.userid(individual).non_reply_messages.archived(false).keep(false).each do |record|
        if record.created_at <= archive_records_less_than && record.source_message_id.blank? && record.source_feedback_id.blank? && record.source_contact_id.blank?
          send_email = true
          individual_message_file.puts "#{record.identifier}, created on #{record.created_at}"
          #record.update_attribute(:archived, true)
        end
      end
      stage = "Archived messages due for deletion #{delete_records_less_than.strftime('%Y_%m_%d')}"
      p stage
      individual_message_file.puts stage
      Message.userid(individual).non_reply_messages.archived(true).keep(false).each do |record|
        if record.created_at <= report_delete_less_than
          send_email = true
          individual_message_file.puts "#{record.identifier}, created on #{record.created_at}"
        end
      end
      stage = "Archived messages deleted"
      p stage
      individual_message_file.puts stage
      Message.userid(individual).non_reply_messages.archived(true).keep(false).each do |record|
        if record.created_at <= delete_records_less_than
          send_email = true
          individual_message_file.puts "#{record.identifier}, deleted"
          #record.destroy
        end
      end
      individual_message_file.close
      if send_email

        p 'mailing'
        send_to = []
        managera = UseridDetail.userid(individual).first
        p managera
        send_to << managera.email_address if managera.present?
        p send_to
        managerb = UseridDetail.userid('SBManager').first
        p managerb
        send_to << managerb.email_address if managerb.present? && managera.blank?
        p send_to
        UserMailer.send_logs(individual_message_file, send_to, 'Individual messages', 'Individual messages archiving report').deliver_now
      else
        File.delete(file_for_individual_messages) if File.exist?(file_for_individual_messages)
      end
    end
  end
end
