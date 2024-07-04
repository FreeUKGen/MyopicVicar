##############################################
# This file is in desperate need of refactoring
##############################################
class UserMailer < ActionMailer::Base
  reg_website = MyopicVicar::Application.config.website == 'https://www.freereg.org.uk' ? '' : 'Test'
  cen_website = MyopicVicar::Application.config.website == 'https://www.freecen.org.uk' ? '' : 'Test'
  if MyopicVicar::Application.config.template_set == 'freereg'
    default from: "#{reg_website} FreeREG Servant <no-reply@freereg.org.uk>"
  elsif MyopicVicar::Application.config.template_set == 'freecen'
    default from: "#{cen_website} FreeCEN Servant <no-reply@freecen.org.uk>"
  end

  def appname
    MyopicVicar::Application.config.freexxx_display_name
  end

  def freecen_processing_report(to_email, subj, report)
    @appname = appname
    @freecen_report = report
    mail(:to => to_email, :subject => subj, :body => report, :content_type => "text/plain")
  end
  add_template_helper(EmailHelper)

  def acknowledge_communication(original)
    @appname = appname
    @contact = original
    @communication = original
    get_attachment(@communication)
    mail(to: "#{@communication.email_address}", :subject => "Thank you #{@communication.name} for contacting us. Reference #{@communication.identifier}")
  end

  def acknowledge_donate_cta_feedback(original)
    @appname = appname
    @communication = original
    mail(to: "#{@communication.email_address}", subject: "Thank you #{@communication.name} for your feedback. Reference #{@communication.identifier}")
  end

  def communicate_donate_cta_feedback(original)
    @appname = appname
    @communication = original
    mail(to: "feedback@freeukgenealogy.org.uk", subject: "#{appname} Donate CTA Feedback:#{@communication.identifier}")
  end

  def acknowledge_feedback(original)
    @appname = appname
    @communication = original
    get_attachment(@communication)
    mail(to: "#{@communication.email_address}", :subject => "Thank you #{@communication.name} for your feedback. Reference #{@communication.identifier}")
  end

  def acknowledge_handbook_feedback(original)
    @appname = appname
    @communication = original
    get_attachment(@communication)
    mail(to: "#{@communication.email_address}", :subject => "Thank you #{@communication.name} for your feedback. Reference #{@communication.identifier}")
  end

  def add_emails(ccs)
    ccs_emails = []
    ccs.each do |cc|
      ccs_emails << UseridDetail.create_friendly_from_email(cc)
    end
    ccs_emails
  end

  def batch_processing_failure(message, user, batch)
    @appname = appname
    @message = File.read(message)
    @userid, @userid_email = user_email_lookup(user)
    @syndicate_coordinator, @syndicate_coordinator_email = syndicate_coordinator_email_lookup(@userid)
    @county_coordinator, @county_coordinator_email = county_coordinator_email_lookup(batch, @userid)
    subject = "#{@userid.userid}/#{batch} processing encountered serious problem at #{Time.now}"
    adjust_email_recipients(subject)
  end

  def batch_processing_success(message, user, batch)
    @appname = appname
    @message = File.read(message)
    @userid, @userid_email = user_email_lookup(user)
    @batch = Freereg1CsvFile.where(file_name: batch, userid: user).first
    @syndicate_coordinator, @syndicate_coordinator_email = syndicate_coordinator_email_lookup(@userid)
    @county_coordinator, @county_coordinator_email = county_coordinator_email_lookup(batch, @userid)
    case appname.downcase
    when 'freereg'
      subject = "#{@userid.userid}/#{batch} processed at #{Time.now} with #{@batch.error unless @batch.nil?} errors over period #{@batch.datemin unless @batch.nil?}-#{@batch.datemax unless @batch.nil?}"
    when 'freecen'
      subject = "#{@userid.userid} processed #{batch} at #{Time.now} "
    end
    adjust_email_recipients(subject)
  end

  def communicate_github_issue_creation(feedback)
    @feedback = feedback
    @user = UseridDetail.where(userid: feedback.user_id).first
    @user_email = @user.email_address
    mail(to: @user_email, :subject => 'Notification of github issue creation')
  end


  def contact_action_request(contact, send_to, copies_to)
    @appname = appname
    @contact = contact
    @communication = contact
    @send_to = UseridDetail.userid(send_to).first
    @cc_email_addresses = []
    @cc_names = []
    if copies_to.present?
      copies_to.each do |copy_userid|
        copy = UseridDetail.userid(copy_userid).first
        person_name = (copy.person_forename + ' ' + copy.person_surname + ' ' + copy.email_address) unless @cc_email_addresses.include?(copy.email_address)
        @cc_names.push(person_name) unless @cc_email_addresses.include?(copy.email_address)
        @cc_email_addresses.push(copy.email_address) unless @cc_email_addresses.include?(copy.email_address)
      end
    end
    get_attachment(@contact)
    mail(to: "#{@send_to.email_address}", cc: @cc_email_addresses, subject: "This is a contact action request for reference #{@contact.identifier}")
  end

  def coordinator_contact_reply(contact, ccs_userids, message, sender_userid)
    @appname = appname
    @contact = contact
    @message = message
    @cc_email_addresses = get_email_address_array_from_array_of_userids(ccs_userids)
    sender_email_address = get_email_address_from_userid(sender_userid)
    copies_to_userids = message.copies_to_userids
    copies_to_userids_emails = get_email_address_array_from_array_of_userids(copies_to_userids) if copies_to_userids.present?
    @reply_messages = Message.where(source_contact_id: @message.source_contact_id).all
    get_message_attachment
    mail(from: sender_email_address, cc: copies_to_userids_emails,to: "#{@contact.name} <#{@contact.email_address}>", bcc: @cc_email_addresses, subject: @message.subject)
  end

  def coordinator_feedback_reply(feedback, ccs_userids, message, sender_userid)
    @appname = appname
    @feedback = feedback
    @message = message
    @cc_email_addresses = get_email_address_array_from_array_of_userids(ccs_userids)
    sender_email_address = get_email_address_from_userid(sender_userid)
    @reply_messages = Message.where(source_feedback_id: @message.source_feedback_id).all
    get_message_attachment
    copies_to_userids = message.copies_to_userids
    copies_to_userids_emails = get_email_address_array_from_array_of_userids(copies_to_userids) if copies_to_userids.present?
    mail(from: sender_email_address, cc: copies_to_userids_emails, to: "#{@feedback.name} <#{@feedback.email_address}>", bcc: @cc_email_addresses, subject: @message.subject)
  end

  def message_reply(reply, to_userid, copy_to_userid, original_message, sender_userid)
    @appname = appname
    @reply = reply
    @original_message = original_message
    @sending = UseridDetail.userid(sender_userid).first
    sender_email = UseridDetail.create_friendly_from_email(sender_userid)
    to_email = UseridDetail.create_friendly_from_email(to_userid)
    copy_to_email = copy_to_userid.present? ? UseridDetail.create_friendly_from_email(copy_to_userid) : ''
    copies_to_userids = @reply.copies_to_userids
    copies_to_userids_emails = get_email_address_array_from_array_of_userids(copies_to_userids) if copies_to_userids.present?
    mail(to: [to_email, sender_email, copy_to_email], cc: copies_to_userids_emails, subject: "#{@sending.person_forename} #{@sending.person_surname} of #{@appname} sent a message #{@reply.subject} in response to reference #{@original_message.identifier}")
  end

  def feedback_action_request(contact, send_to, copies_to)
    @appname = appname
    @contact = contact
    @send_to = UseridDetail.userid(send_to).first
    @cc_email_addresses = []
    @cc_names = []
    if copies_to.present?
      copies_to.each do |copy_userid|
        copy = UseridDetail.userid(copy_userid).first
        person_name = (copy.person_forename + ' ' + copy.person_surname + ' ' + copy.email_address) unless @cc_email_addresses.include?(copy.email_address)
        @cc_names.push(person_name) unless @cc_email_addresses.include?(copy.email_address)
        @cc_email_addresses.push(copy.email_address) unless @cc_email_addresses.include?(copy.email_address)
      end
    end
    get_attachment(@contact)
    mail(to: "#{@send_to.email_address}", cc: @cc_email_addresses, subject: "This is a feedback action request for reference #{@contact.identifier} on #{@appname}")
  end

  def forced_district_deletion(chapman_code, name, year)
    county = County.find_by(chapman_code: chapman_code)
    county_coordinator = UseridDetail.find_by(userid: county.county_coordinator)
    friendly_email = "#{county_coordinator.person_forename} #{county_coordinator.person_surname} <#{county_coordinator.email_address}>"
    mail(to: friendly_email, subject: "Forced deletion of district #{name} for #{chapman_code} in #{year} completed")
  end

  def get_attachment(contact)
    if contact.screenshot_location.present?
      @file_name = File.basename(contact.screenshot_location)
      attachments[@file_name] = File.read(contact.screenshot.path)
    end
  end

  def get_coordinator_name
    @coordinator = nil
    coordinator = Syndicate.where(:syndicate_code => @user.syndicate).first
    if coordinator.present?
      coordinator = coordinator.syndicate_coordinator
      @coordinator = UseridDetail.where(:userid => coordinator, :email_address_valid => true).first unless coordinator.nil?
    end
  end

  def get_message_attachment
    if @message.attachment.present?
      @file_name = File.basename(@message.attachment.path)
      @file = "#{Rails.root}/public" + @message.attachment_url
      attachments[@file_name] = File.read(@file)
    end
    if @message.images.present?
      @image = File.basename(@message.images.path)
      @filei = "#{Rails.root}/public" + @message.images_url
      attachments[@image] = File.binread(@filei)
    end
  end

  def incorporation_report(userid, message, file, owner)
    coordinator = UseridDetail.userid(userid).first
    owner_details = UseridDetail.userid(owner).first
    @appname = appname
    @message = message
    subject = "We have processed the request to include #{file} of #{owner} into the database"
    if coordinator == owner_details
      mail(to: "#{coordinator.person_forename} <#{coordinator.email_address}>", subject: subject) if coordinator.present?
    else
      mail(to: "#{coordinator.person_forename} <#{coordinator.email_address}>", cc: "#{owner_details.person_forename} <#{owner_details.email_address}>", subject: subject) if coordinator.present?
    end
  end

  def incorporation_report_failure(userid, message, file, owner)
    coordinator = UseridDetail.userid(userid).first
    owner_details = UseridDetail.userid(owner).first
    @appname = appname
    @message = message
    subject =  "We were unable to process the request to include #{file} of #{owner} into the database"
    if coordinator == owner_details
      mail(to: "#{coordinator.person_forename} <#{coordinator.email_address}>", subject: subject) if coordinator.present?
    else
      mail(to: "#{coordinator.person_forename} <#{coordinator.email_address}>", cc: "#{owner_details.person_forename} <#{owner_details.email_address}>", subject: subject) if coordinator.present?
    end
  end

  def unincorporation_report(userid, message, file, owner)
    coordinator = UseridDetail.userid(userid).first
    owner_details = UseridDetail.userid(owner).first
    @appname = appname
    @message = message
    subject = "We have processed the request to remove #{file} of #{owner} from the database"
    if coordinator == owner_details
      mail(to: "#{coordinator.person_forename} <#{coordinator.email_address}>", subject: subject) if coordinator.present?
    else
      mail(to: "#{coordinator.person_forename} <#{coordinator.email_address}>", cc: "#{owner_details.person_forename} <#{owner_details.email_address}>", subject: subject) if coordinator.present?
    end
  end

  def unincorporation_report_failure(userid, message, file, owner)
    coordinator = UseridDetail.userid(userid).first
    owner_details = UseridDetail.userid(owner).first
    @appname = appname
    @message = message
    subject = "Unincorporation failure report for the removal of #{file} owned by #{owner} from the database"
    if coordinator == owner_details
      mail(to: "#{coordinator.person_forename} <#{coordinator.email_address}>", subject: subject) if coordinator.present?
    else
      mail(to: "#{coordinator.person_forename} <#{coordinator.email_address}>", cc: "#{owner_details.person_forename} <#{owner_details.email_address}>", subject: subject) if coordinator.present?
    end
  end

  def freecen_move_fc2_place_linkages_report(email_subject, email_body, report, report_name, email_to)
    email_addresses = []
    email_addresses << email_to
    attachments[report_name] = { :mime_type => 'text/csv', :content => report } unless report.empty?

    mail(:to => email_addresses, :subject => email_subject, :body => email_body)
  end

  def freecen_vld_invalid_civil_parish_report(email_subject, email_body, report, report_name, email_to)
    email_addresses = []
    email_addresses << email_to
    attachments[report_name] = { :mime_type => 'text/csv', :content => report } unless report.empty?

    mail(:to => email_addresses, :subject => email_subject, :body => email_body)
  end

  def freecen_vld_invalid_pob_report(email_subject, email_body, report, report_name, email_to, cc_to)
    email_addresses = []
    email_addresses << email_to
    cc_addresses = []
    cc_addresses << cc_to
    attachments[report_name] = { :mime_type => 'text/csv', :content => report } unless report.empty?

    mail(:to => email_addresses, :cc => cc_addresses, :subject => email_subject, :body => email_body)
  end

  def notification_of_technical_registration(user)
    @appname = appname
    @user = user
    manager = nil
    if appname.downcase == 'freereg'
      manager = UseridDetail.userid("FR Exec Lead").first
      get_coordinator_name
      mail(:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :cc => "#{manager.person_forename} <#{manager.email_address}>", :subject => "#{appname} transcriber registration") unless @coordinator.nil?
    elsif appname.downcase == 'freecen'
      get_coordinator_name
      mail(:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "#{appname} transcriber registration") unless @coordinator.nil?
    end
  end

  def notification_of_transcriber_creation(user)
    @appname = appname
    @user = user
    if appname.downcase == 'freereg'
      manager = UseridDetail.userid("FR Exec Lead").first
      get_coordinator_name
      mail(:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :cc => "#{manager.person_forename} <#{manager.email_address}>", :subject => "#{appname} transcriber creation") unless @coordinator.nil?
    elsif appname.downcase == 'freecen'
      get_coordinator_name
      mail(:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "#{appname} userid creation") unless @coordinator.nil?
    end
  end

  def notification_of_transcriber_registration(user)
    @appname = appname
    @user = user
    manager = nil
    if appname.downcase == 'freereg'
      manager = UseridDetail.userid("FR Exec Lead").first
      get_coordinator_name
      mail(:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :cc => "#{manager.person_forename} <#{manager.email_address}>", :subject => "#{appname} transcriber registration") unless @coordinator.nil?
    elsif appname.downcase == 'freecen'
      get_coordinator_name
      mail(:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "#{appname} transcriber registration") unless @coordinator.nil?
    end
  end

  def notification_of_researcher_registration(user)
    @appname = appname
    @user = user
    get_coordinator_name
    mail(:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "#{appname} research registration") unless @coordinator.nil?
  end

  def notify_cc_assignment_complete(user, group_id, chapman_code)
    @appname = appname
    image_server_group = ImageServerGroup.find(group_id)

    county_coordinator = County.where(:chapman_code=>chapman_code).first.county_coordinator
    cc = UseridDetail.where(userid: county_coordinator, email_address_valid: true).first
    return if cc.nil?

    subject = 'assignment completed'
    email_body = 'Transcription of image group ' + image_server_group.group_name + ' is completed'

    mail(:from => user.email_address, :to => cc.email_address, :subject => subject, :body => email_body)
  end

  def notify_sc_allocate_request_rejection(user, group_name, syndicate, action_type)
    @appname = appname
    syndicate = Syndicate.where(:syndicate_code=>syndicate).first
    return if syndicate.nil?

    sc = UseridDetail.where(:userid=>syndicate.syndicate_coordinator).first
    return if sc.nil?

    case action_type
    when 'allocate'
      subject = 'allocate request accepted'
      email_body = 'Your request to have image group ' + group_name + ' be allocated is approved'
    when 'reject'
      subject = 'allocate request rejected'
      email_body = 'Your request to have image group ' + group_name + ' be allocated is rejected'
    end

    mail(:from => user.email_address, :to => sc.email_address, :subject => subject, :body => email_body)
  end

  def notify_sc_assignment_complete(assignment_id)
    @appname = appname
    assignment = Assignment.id(assignment_id).first
    user = UseridDetail.id(assignment.userid_detail_id).first
    @image_server_images = ImageServerImage.where(:assignment_id=>assignment_id).pluck(:image_file_name)

    subject = "#{user.userid} completed the assignment"
    email_body = 'for following images:\r\n\r\n'

    @image_server_images.each {|x| email_body = email_body + x + '\r\n' }

    syndicate = Syndicate.where(:syndicate_code=>user.syndicate).first
    if syndicate.present?
      syndicate_coordinator = syndicate.syndicate_coordinator
      sc = UseridDetail.where(userid: syndicate_coordinator, email_address_valid: true).first

      if sc.present?
        @sc_email_with_name =  sc.email_address
        mail(:from => user.email_address, :to => @sc_email_with_name, :cc => user.email_address, :subject => subject, :body => email_body)
      else
        p "#{appname.downcase}_PROCESSING: There was no syndicate coordinator"
      end
    end
  end

  def report_processor_limit_exceeded(batches, limit)
    @appname = appname
    _rrem, reg = regmanager_email_lookup
    _nn, sb = sbmanager_email_lookup
    vino = 'Vinodhini Subbu <vinodhini.subbu@freeukgenealogy.org.uk>'
    ccs = []
    ccs << reg
    ccs << vino
    mail(to: sb, cc: ccs, subject: " There are #{batches} processor files waiting to be processed. This exceeds the limit of #{limit}")
  end


  def report_to_data_manger_of_large_file(file_name, userid)
    @appname = appname
    @file = file_name
    @user = UseridDetail.userid(userid).first
    if @user.present?
      syndicate_coordinator = nil
      syndicate = Syndicate.where(syndicate_code: @user.syndicate).first
      if syndicate.present?
        syndicate_coordinator = syndicate.syndicate_coordinator
        sc = UseridDetail.where(userid: syndicate_coordinator, email_address_valid: true).first
        if sc.present?
          @sc_email_with_name = sc.email_address
        else
          p 'FREREG_PROCESSING: There was no syndicate coordinator'
        end
      end
      data_managers = UseridDetail.role('data_manager').email_address_valid.all
      dm_emails = []
      data_managers.each do |dm|
        user_email_with_name = dm.email_address
        dm_emails << user_email_with_name unless user_email_with_name == @sc_email_with_name
      end
      if @sc_email_with_name.present?
        mail(:to => @sc_email_with_name,  :cc => dm_emails, :subject => "#{@user.userid} submitted an action for file/batch #{@file} at #{Time.now} that was too large for normal processing")
      else
        mail(:to => dm_emails, :subject => "#{@user.userid} submitted an action for file/batch #{@file} at #{Time.now} that was too large for normal processing")
      end

    else
      p '--------------------------------------------'
      p 'User does not exist'
      p file_name
      p userid
    end
  end

  def report_for_data_manager(email_subject, email_body, report, report_name, email_to)
    @appname = appname
    dm_emails = []
    if email_to == 'data_manager'
      data_managers = UseridDetail.role('data_manager').email_address_valid.all
      data_managers.each do |dm|
        user_email_with_name = dm.email_address
        dm_emails << user_email_with_name
      end
      secondary_data_managers = UseridDetail.where(secondary_role: 'data_manager')
      secondary_data_managers.each do |sdm|
        dm_emails << sdm.email_address if sdm.email_address_valid
      end
    else
      dm_emails << email_to
    end

    p "Email addresses: #{dm_emails}"

    unless report.length == 0
      attachments[report_name] = { :mime_type => 'text/csv', :content => report }
    end
    mail(:to => dm_emails, :subject => email_subject, :body => email_body)

  end

  def request_cc_image_server_group(sc, cc_email, group)
    @appname = appname
    subject = 'SC request image group'
    email_body = sc.userid + ' at ' + sc.syndicate + ' requests to have ' + group + ' allocated'
    mail(:from => sc.email_address, :to => cc_email, :subject => subject, :body => email_body)
  end

  def request_sc_image_server_group(transcriber, sc, group, location)
    @appname = appname
    @subject = 'Transcriber request image group'
    @transcriber = transcriber
    @sc = sc
    @group = group
    @location = location
    mail(:from => @transcriber.email_address, :to => @sc.email_address, :subject => @subject)
  end

  def request_to_volunteer(coordinator, group_name, applier_name, applier_email)
    @appname = appname
    subject = 'Request to transcribe image group ' + group_name
    email_body = applier_name + ' requests to transcribe ' + group_name
    mail(:from => applier_email, :to => coordinator.email_address, :subject => subject, :body => email_body)
  end

  def send_change_of_syndicate_notification_to_sc(user)
    @appname = appname
    @user = user
    get_coordinator_name
    mail(:from => "no-reply@#{appname.downcase}.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "#{appname} change of syndicate") unless @coordinator.blank?
  end

  def send_change_of_email_notification_to_sc(user)
    @appname = appname
    @user = user
    get_coordinator_name
    mail(:from => "no-reply@#{appname.downcase}.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "#{appname} change of email") unless @coordinator.blank?
  end

  def send_message(mymessage, ccs, from, host)
    @appname = appname
    @message = mymessage
    @host = host
    @sender = UseridDetail.userid(from).first
    @reply_messages = Message.where(source_message_id: @message.source_message_id).all unless @message.source_message_id.blank?
    @respond_to_message = Message.id(@message.source_message_id).first
    from_email = UseridDetail.create_friendly_from_email(from)
    from_email = 'Vinodhini Subbu <vinodhini.subbu@freeukgenealogy.org.uk>' if from_email.blank?
    ccs_emails = add_emails(ccs)
    mail(from: from_email, bcc: ccs_emails, subject: "#{@message.subject} from #{@sender.person_forename} #{@sender.person_surname} of #{@appname}. Reference #{@message.identifier}")
  end

  def send_logs(file, ccs, body_message, subjects)
    @appname = appname
    if file.present?
      attachments[File.basename(file)] = File.read(file)
    end
    mail(bcc: ccs, subject: subjects, body: body_message)
  end

  def send_upload_stats(start_date, end_date)
    @start_date = start_date
    @end_date = end_date
    @uploaders_count, @email_confirmed, @users_count, @records_added = PhysicalFile.new.upload_report_mail(@start_date, @end_date)
    @transcribers_count, @active_transcribers_count, @email_confimed = UseridDetail.get_transcriber_stats(@start_date, @end_date)
    mail(from: "no-reply@freereg.org.uk", to: 'Denise Colbert <denise.colbert@freeukgenealogy.org.uk>',cc: 'Vinodhini Subbu <vinodhini.subbu@freeukgenealogy.org.uk>', subject: "Upload report stats")
  end

  def embargo_process_completion_email(rule_id, ccs)
    @rule = EmbargoRule.find_by(id: rule_id)
    @register = @rule.register
    mail(bcc: 'Vinodhini Subbu <vinodhini.subbu@freeukgenealogy.org.uk>', subject: "Embargo processing is complete")
  end

  def update_report_to_freereg_manager(file, user)
    @appname = appname
    attachments['report.log'] = File.read(file)
    @person_forename = user.person_forename
    # userid is REGManager, so no need to check email_address_valid
    @email_address = user.email_address
    mail(:to => "#{@person_forename} <#{@email_address}>", :subject => 'FreeReg update processing report')
  end

  def update_report_to_freecen_manager(report, user, ccs)
    @appname = appname
    attachments["report.txt"] = { :mime_type => 'text/plain', :content => report }
    # attachments["report.log"] = report
    @person_forename = user.person_forename
    @email_address = user.email_address
    mail(:from => "no-reply@freecen.org.uk",:to => "#{@person_forename} <#{@email_address}>", :cc=>ccs, :subject => "FreeCEN update processing report")
  end

  private

  def adjust_email_recipients(message)
    if @userid.active && @userid.email_address_valid && @userid.registration_completed(@userid) && !@userid.no_processing_messages
      if @county_coordinator == @syndicate_coordinator
        mail(:to => @userid_email, :cc => @syndicate_coordinator_email, :subject => message)
      else
        mail(:to => @userid_email, :cc => [@syndicate_coordinator_email, @county_coordinator_email], :subject => message)
      end
    else
      if @county_coordinator == @syndicate_coordinator
        mail(:to => @syndicate_coordinator_email, :subject => message)
      else
        mail(:to => @syndicate_coordinator_email, :cc => @county_coordinator_email, :subject => message)
      end
    end
  end

  def get_email_address_array_from_array_of_userids(userids)
    array_of_email_addresses = []
    if userids.present?
      userids.each do |copy_userid|
        copy = UseridDetail.userid(copy_userid).first
        if copy.present?
          array_of_email_addresses.push(copy.email_address) unless array_of_email_addresses.include?(copy.email_address)
        end
      end
      #array_of_email_addresses = nil
    end
    array_of_email_addresses
  end


  def get_email_address_from_userid(userid)
    userid_object = UseridDetail.userid(userid).first
    if userid_object.present?
      email_address = userid_object.email_address
    else
      email_address = "#{appname} Servant <no-reply@#{appname.downcase}.org.uk>"
    end
    email_address
  end

  def user_email_lookup(user)
    userid = UseridDetail.userid(user).first
    if userid.present?
      friendly_email = "#{userid.person_forename} #{userid.person_surname} <#{userid.email_address}>"
    else
      friendly_email = "#{appname} Servant <no-reply@#{appname.downcase}.org.uk>"
    end
    [userid, friendly_email]
  end

  def syndicate_coordinator_email_lookup(userid)
    if userid.present?
      syndicate = Syndicate.where(syndicate_code: userid.syndicate).first
      if syndicate.present?
        syndicate_coordinator_id = syndicate.syndicate_coordinator
        syndicate_coordinator = UseridDetail.userid(syndicate_coordinator_id).first
        if syndicate_coordinator.present? && syndicate_coordinator.active && syndicate_coordinator.email_address_valid
          friendly_email = "#{syndicate_coordinator.person_forename} #{syndicate_coordinator.person_surname} <#{syndicate_coordinator.email_address}>"
        else
          syndicate_coordinator, friendly_email = sndmanager_email_lookup
        end
      else
        syndicate_coordinator, friendly_email = sndmanager_email_lookup
      end
    else
      syndicate_coordinator, friendly_email = sndmanager_email_lookup
    end
    [syndicate_coordinator, friendly_email]
  end

  def county_coordinator_email_lookup(file_name, userid)
    if file_name.blank? || userid.blank?
      case appname.downcase
      when 'freereg'
        county_coordinator, friendly_email = regmanager_email_lookup
      when 'freecen'
        county_coordinator, friendly_email = cenmanager_email_lookup
      end
    else
      case appname.downcase
      when 'freereg'
        batch_id = Freereg1CsvFile.where(file_name: file_name, userid: userid).first
      when 'freecen'
        batch_id = FreecenCsvFile.where(file_name: file_name, userid: userid).first
      end
      if batch_id.blank?
        county_coordinator, friendly_email = extract_chapman_code_from_file_name(file_name)
      else
        county = County.where(chapman_code: batch_id.county).first
        if county.present?
          county_coordinator_id = county.county_coordinator
          county_coordinator = UseridDetail.where(userid: county_coordinator_id).first
          if county_coordinator.present? && county_coordinator.active && county_coordinator.email_address_valid
            friendly_email = "#{county_coordinator.person_forename} #{county_coordinator.person_surname} <#{county_coordinator.email_address}>"
          else
            county_coordinator, friendly_email = sndmanager_email_lookup
          end
        else
          county_coordinator, friendly_email = extract_chapman_code_from_file_name(file_name)
        end
      end
    end
    [county_coordinator, friendly_email]
  end

  def regmanager_email_lookup
    regmanager = UseridDetail.userid('REGManager').first
    friendly_email = 'Vinodhini Subbu <vinodhini.subbu@freeukgenealogy.org.uk>' if regmanager.blank?
    friendly_email = "#{regmanager.person_forename} #{regmanager.person_surname} <#{regmanager.email_address}>" if regmanager.present?
    [regmanager, friendly_email]
  end

  def sbmanager_email_lookup
    sbmanager = UseridDetail.userid('SBManager').first
    friendly_email = 'Vinodhini Subbu <vinodhini.subbu@freeukgenealogy.org.uk>' if sbmanager.blank?
    friendly_email = "#{sbmanager.person_forename} #{sbmanager.person_surname} <#{sbmanager.email_address}>" if sbmanager.present?
    [sbmanager, friendly_email]
  end

  def cenmanager_email_lookup
    regmanager = UseridDetail.userid('CENManager').first
    friendly_email = 'Vinodhini Subbu <vinodhini.subbu@freeukgenealogy.org.uk>' if regmanager.blank?
    friendly_email = "#{regmanager.person_forename} #{regmanager.person_surname} <#{regmanager.email_address}>" if regmanager.present?
    [regmanager, friendly_email]
  end

  def sndmanager_email_lookup
    sndmanager = UseridDetail.userid('SNDManager').first
    friendly_email = 'Vinodhini Subbu <vinodhini.subbu@freeukgenealogy.org.uk>' if sndmanager.blank?
    friendly_email = "#{sndmanager.person_forename} #{sndmanager.person_surname} <#{sndmanager.email_address}>" if sndmanager.present?
    [sndmanager, friendly_email]
  end

  def extract_chapman_code_from_file_name(file_name)
    case appname.downcase
    when 'freereg'
      parts = file_name.split('.')
      chapman_code = parts[0].slice(0..2)
    when 'freecen'
      year, piece, _fields = Freecen2Piece.extract_year_and_piece(file_name, @chapman_code)
      actual_piece = Freecen2Piece.where(year: year, number: piece.upcase).first
      chapman_code = actual_piece.chapman_code if actual_piece.present?
    end
    if ChapmanCode.value?(chapman_code)
      county = County.where(chapman_code: chapman_code).first
      if county.present?
        county_coordinator_id = county.county_coordinator
        county_coordinator = UseridDetail.where(userid: county_coordinator_id).first
        if county_coordinator.present? && county_coordinator.active && county_coordinator.email_address_valid
          friendly_email = "#{county_coordinator.person_forename} #{county_coordinator.person_surname} <#{county_coordinator.email_address}>"
        else
          county_coordinator, friendly_email = sndmanager_email_lookup
        end
      else
        county_coordinator, friendly_email = sndmanager_email_lookup
      end
    end
    [county_coordinator, friendly_email]
  end

end
