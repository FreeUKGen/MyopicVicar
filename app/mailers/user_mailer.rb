class UserMailer < ActionMailer::Base
  add_template_helper(EmailHelper)

  default from: "freereg-contacts@freereg.org.uk"

  def batch_processing_failure(message,user,batch)
    @message = File.read(message)
    @userid = UseridDetail.where(userid: user).first
    if @userid.present?
      emails = Array.new
      if @userid.present? &&  @userid.active && @userid.email_address_valid && @userid.registration_completed(@userid) && !@userid.no_processing_messages
        user_email_with_name = @userid.email_address
        emails <<  user_email_with_name
      end
      syndicate_coordinator = nil
      syndicate_coordinator = Syndicate.where(syndicate_code: @userid.syndicate).first
      if syndicate_coordinator.present?
        syndicate_coordinator = syndicate_coordinator.syndicate_coordinator
        sc = UseridDetail.where(userid: syndicate_coordinator, email_address_valid: true).first
        if sc.present?
          sc_email_with_name = sc.email_address
          emails << sc_email_with_name unless user_email_with_name == sc_email_with_name
        end
      end
      @batch = Freereg1CsvFile.where(file_name: batch, userid: user).first
      county = County.where(chapman_code: @batch.county).first unless @batch.nil?
      if county.present?
        county_coordinator = county.county_coordinator
        cc = UseridDetail.where(userid: county_coordinator, email_address_valid: true).first
        if cc.present?
          cc_email_with_name = cc.email_address
          emails << cc_email_with_name unless cc_email_with_name == sc_email_with_name
        end
      end

      if emails.length == 1
        mail(:from => "freereg-processing@freereg.org.uk",:to => emails[0],  :subject => "#{@userid.userid}/#{batch} processing encountered serious problem at #{Time.now}")
      elsif emails.length == 2
        mail(:from => "freereg-processing@freereg.org.uk",:to => emails[0], :cc => emails[1], :subject => "#{@userid.userid}/#{batch} processing encountered serious problem at at #{Time.now}")
      elsif emails.length == 3
        first_mail = emails.shift
        mail(:from => "freereg-processing@freereg.org.uk",:to => first_mail, :cc => emails, :subject => "#{@userid.userid}/#{batch} processing encountered serious problem a #{Time.now}")
      end
    end
  end

  def batch_processing_success(file,user,batch)
    @message = File.read(file)
    @userid = UseridDetail.where(userid: user).first
    if @userid.present?
      emails = Array.new
        if @userid.present? &&  @userid.active && @userid.email_address_valid && @userid.registration_completed(@userid) && !@userid.no_processing_messages
          user_email_with_name =  @userid.email_address
          emails <<  user_email_with_name
        end
      syndicate_coordinator = nil
      syndicate_coordinator = Syndicate.where(syndicate_code: @userid.syndicate).first
      if syndicate_coordinator.present?
        syndicate_coordinator = syndicate_coordinator.syndicate_coordinator
        sc = UseridDetail.where(userid: syndicate_coordinator, email_address_valid: true).first
        if sc.present?
          sc_email_with_name =  sc.email_address
          emails << sc_email_with_name unless user_email_with_name == sc_email_with_name
        end
      end
      @batch = Freereg1CsvFile.where(file_name: batch, userid: user).first
      county = County.where(chapman_code: @batch.county).first unless @batch.nil?
      if county.present?
        county_coordinator = county.county_coordinator
        cc = UseridDetail.where(userid: county_coordinator, email_address_valid: true).first
        if cc.present?
          cc_email_with_name =  cc.email_address
          emails << cc_email_with_name unless cc_email_with_name == sc_email_with_name
        end
      end
      if emails.length == 1
        mail(:from => "freereg-processing@freereg.org.uk", :to => emails[0],  :subject => "#{@userid.userid}/#{batch} processed at #{Time.now} with #{@batch.error unless @batch.nil?} errors over period #{@batch.datemin unless @batch.nil?}-#{@batch.datemax unless @batch.nil?}")
      elsif emails.length == 2
        mail(:from => "freereg-processing@freereg.org.uk",:to => emails[0], :cc => emails[1], :subject => "#{@userid.userid}/#{batch} processed at #{Time.now} with #{@batch.error unless @batch.nil?} errors over period #{@batch.datemin unless @batch.nil?}-#{@batch.datemax unless @batch.nil?}")
      elsif emails.length == 3
        first_mail = emails.shift
        mail(:from => "freereg-processing@freereg.org.uk",:to => first_mail, :cc => emails, :subject =>"#{@userid.userid}/#{batch} processed at #{Time.now} with #{@batch.error unless @batch.nil?} errors over period #{@batch.datemin unless @batch.nil?}-#{@batch.datemax unless @batch.nil?}")
      end
    end
  end

  def coordinator_data_problem(contact,ccs)
    @contact = contact
    get_attachment
    mail(:from => "freereg-contacts@freereg.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>",:cc => ccs, :subject => "Thank you for reporting a problem with our data. Reference #{@contact.identifier}")
    #mail(:from => "vinodhini.subbu@freeukgenealogy.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>", :subject => "Thank you for reporting a problem with our data. Reference #{@contact.identifier}")
  end

  def datamanager_data_question(contact,ccs)
    @contact = contact
    get_attachment
    mail(:from => "freereg-contacts@freereg.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>",:cc => ccs, :subject => "Thank you for your data question. Reference #{@contact.identifier}")
  end

  def enhancement(contact,ccs)
    @contact = contact
    get_attachment
    mail(:from => "freereg-contacts@freereg.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>",  :cc => ccs, :subject => "Thank you for the suggested enhancement. Reference #{@contact.identifier}")
  end

  def feedback(contact,ccs)
    @contact = contact
    @user = UseridDetail.userid(@contact.user_id).first
    get_attachment
    mail(:from => "freereg-feedback@freereg.org.uk",:to => "#{@user.person_forename} <#{@user.email_address}>",:cc => ccs, :subject => "Thank you for your feedback. Reference #{@contact.identifier}")
    #mail(:from => "vinodhini.subbu@freeukgenealogy.org.uk",:to => "#{@user.person_forename} <#{@user.email_address}>", :subject => "Thank you for your feedback. Reference #{@contact.identifier}")
  end

  def genealogy(contact,ccs)
    @contact = contact
    get_attachment
    mail(:from => "freereg-contacts@freereg.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>",  :cc => ccs, :subject => "Thank you for a genealogical question. Reference #{@contact.identifier}")
  end

  def general(contact,ccs)
    @contact = contact
    get_attachment
    mail(:from => "freereg-contacts@freereg.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>",  :cc => ccs, :subject => "Thank you for the general comment. Reference #{@contact.identifier}")
  end

  def get_attachment
    if @contact.screenshot_url.present?
      @image = File.basename(@contact.screenshot.path)
      attachments[@image] = File.binread(@contact.screenshot.path)
    end
  end

  def get_coordinator_name
    coordinator = Syndicate.where(:syndicate_code => @user.syndicate).first
    if coordinator.nil?
      @coordinator = nil
    else
      coordinator = coordinator.syndicate_coordinator
      @coordinator = UseridDetail.where(:userid => coordinator, :email_address_valid => true).first
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
  def notification_of_registration_completion(user)
    @user = user
    reg_manager = UseridDetail.userid("REGManager").first
    get_coordinator_name
    if Time.now - 5.days <= @user.c_at
      mail(:from => "freereg-registration@freereg.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :cc => "#{reg_manager.person_forename} <#{reg_manager.email_address}>", :subject => "FreeReg registration completion") unless @coordinator.nil?
    end
  end
  def notification_of_technical_registration(user)
    @user = user
    reg_manager = UseridDetail.userid("REGManager").first
    get_coordinator_name
    mail(:from => "freereg-registration@freereg.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :cc => "#{reg_manager.person_forename} <#{reg_manager.email_address}>", :subject => "FreeReg technical registration notification") unless @coordinator.nil?
  end

  def notification_of_transcriber_creation(user)
    @user = user
    get_coordinator_name
    mail(:from => "freereg-registration@freereg.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "FreeReg userid creation") unless @coordinator.nil?
  end

  def notification_of_transcriber_registration(user)
    @user = user
    reg_manager = UseridDetail.userid("REGManager").first
    get_coordinator_name
    mail(:from => "freereg-registration@freereg.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :cc => "#{reg_manager.person_forename} <#{reg_manager.email_address}>", :subject => "FreeReg transcriber registration") unless @coordinator.nil?
  end

  def notification_of_researcher_registration(user)
    @user = user
    get_coordinator_name
    mail(:from => "freereg-registration@freereg.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "FreeReg research registration") unless @coordinator.nil?
  end

  def notify_cc_assignment_complete(user,group_id,chapman_code)
    image_server_group = ImageServerGroup.find(group_id)

    county_coordinator = County.where(:chapman_code=>chapman_code).first.county_coordinator
    cc = UseridDetail.where(userid: county_coordinator, email_address_valid: true).first
    return if cc.nil?

    subject = "assignment completed"
    email_body = "Transcription of image group " + image_server_group.group_name + " is completed"

    mail(:from => user.email_address, :to => cc.email_address, :subject => subject, :body => email_body)
  end

  def notify_sc_allocate_request_rejection(user,group_name,syndicate,action_type)
    syndicate = Syndicate.where(:syndicate_code=>syndicate).first
    return if syndicate.nil?

    sc = UseridDetail.where(:userid=>syndicate.syndicate_coordinator).first
    return if sc.nil?

    case action_type
      when 'allocate'
        subject = "allocate request accepted"
        email_body = "Your request to have image group " + group_name + " be allocated is approved"
      when 'reject'
        subject = "allocate request rejected"
        email_body = "Your request to have image group " + group_name + " be allocated is rejected"
    end

    mail(:from => user.email_address, :to => sc.email_address, :subject => subject, :body => email_body)
  end

  def notify_sc_assignment_complete(assignment_id)
    assignment = Assignment.id(assignment_id).first
    user = UseridDetail.id(assignment.userid_detail_id).first
    @image_server_images = ImageServerImage.where(:assignment_id=>assignment_id).pluck(:image_file_name)

    subject = "#{user.userid} completed the assignment"
    email_body = "for following images:\r\n\r\n"

    @image_server_images.each {|x| email_body = email_body + x + "\r\n" }

    syndicate = Syndicate.where(:syndicate_code=>user.syndicate).first
    if syndicate.present?
      syndicate_coordinator = syndicate.syndicate_coordinator
      sc = UseridDetail.where(userid: syndicate_coordinator, email_address_valid: true).first

      if sc.present?
        @sc_email_with_name =  sc.email_address
        mail(:from => user.email_address, :to => @sc_email_with_name, :cc => user.email_address, :subject => subject, :body => email_body)
      else
        p "FREREG_PROCESSING: There was no syndicate coordinator"
      end
    end
  end

  def publicity(contact,ccs)
    @ccs = ccs
    @contact = contact
    get_attachment
    mail(:from => "freereg-contacts@freereg.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>",:cc => ccs, :subject => "Thank you for your compliments. Reference #{@contact.identifier}")
  end

  def report_to_data_manger_of_large_file(file_name,userid)
    @file = file_name
    @user = UseridDetail.userid(userid).first
    if @user.present?
      syndicate_coordinator = nil
      syndicate = Syndicate.where(syndicate_code: @user.syndicate).first
      if syndicate.present?
        syndicate_coordinator = syndicate.syndicate_coordinator
        sc = UseridDetail.where(userid: syndicate_coordinator, email_address_valid: true).first
        if sc.present?
          @sc_email_with_name =  sc.email_address
        else
          p "FREREG_PROCESSING: There was no syndicate coordinator"
        end
      end
      data_managers = UseridDetail.role("data_manager").email_address_valid.all
      dm_emails = Array.new
      data_managers.each do |dm|
        user_email_with_name =  dm.email_address
        dm_emails <<  user_email_with_name unless user_email_with_name == @sc_email_with_name
      end
      if @sc_email_with_name.present?
        mail(:from => "freereg-processing@freereg.org.uk", :to => @sc_email_with_name,  :cc => dm_emails, :subject => "#{@user.userid} submitted an action for file/batch #{@file} at #{Time.now} that was too large for normal processing")
      else
        mail(:from => "freereg-processing@freereg.org.uk",:to => dm_emails, :subject => "#{@user.userid} submitted an action for file/batch #{@file} at #{Time.now} that was too large for normal processing")
      end

    else
      p "--------------------------------------------"
      p "User does not exist"
      p file_name
      p userid
    end
  end

  def request_cc_image_server_group(sc,cc_email,group)
    subject = "SC request image group"
    email_body = sc.userid+' at '+sc.syndicate+' requests to have '+group+' allocated'
    mail(:from => sc.email_address, :to => cc_email, :subject => subject, :body => email_body)
  end

  def request_sc_image_server_group(transcriber,sc_email,group)
    subject = "Transcriber request image group"
    email_body = 'member '+transcriber.userid+' of your syndicate '+transcriber.syndicate+' requests to obtain images in '+group
    mail(:from => transcriber.email_address, :to => sc_email, :subject => subject, :body => email_body)
  end

  def request_to_volunteer(coordinator,group_name,applier_name,applier_email)
    subject = "Request to transcribe image group "+group_name
    email_body = applier_name+' requests to transcribe '+group_name
    mail(:from => applier_email, :to => coordinator.email_address, :subject => subject, :body => email_body)
  end

  def send_change_of_syndicate_notification_to_sc(user)
    @user = user
    get_coordinator_name
    mail(:from => "freereg-registration@freereg.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "FreeReg change of syndicate") unless @coordinator.blank?
  end

  def send_change_of_email_notification_to_sc(user)
    @user = user
    get_coordinator_name
    mail(:from => "freereg-registration@freereg.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "FreeReg change of email") unless @coordinator.blank?
  end

  def send_message(mymessage,ccs,from)
    @message = mymessage
    @reply_messages = Message.where(source_message_id: @message.source_message_id).all unless @message.source_message_id.blank?
    @respond_to_message = Message.id(@message.source_message_id).first
    from = "vinodhini.subbu@freeukgenealogy.org.uk" if from.blank?
    #get_message_attachment if @message.attachment.present? ||  @message.images.present?
    mail(:from => from ,:to => "freereg-contacts@freereg.org.uk",  :bcc => ccs, :subject => "#{@message.subject}. Reference #{@message.identifier}")
    #mail(:from => from ,:to => "vinodhini.subbu@freeukgenealogy.org.uk", :subject => "#{@message.subject}. Reference #{@message.identifier}")
  end

  def feedback_reply(message,recipient,sender,ccs)
    @message = message
    @reply_messages = Message.where(source_feedback_id: @message.source_feedback_id).all
    @contact = Feedback.id(@message.source_feedback_id).first
    get_attachment
    @reply_to_person = UseridDetail.where(email_address: recipient).first
    mail(:from => "#{sender}",:to => "#{@reply_to_person.person_forename} <#{recipient}>", :bcc => ccs, subject:"#{@message.subject}. Reference Message Identifier: #{@message.identifier}")
  end

  def coordinator_contact_reply(contact,ccs,message,sender)
    @contact = contact
    @message = message
    @reply_messages = Message.where(source_contact_id: @message.source_contact_id).all
    get_attachment
    mail(from: sender.email_address, to:  "#{@contact.name} <#{@contact.email_address}>", bcc: ccs, subject: @message.subject)
  end

  def send_logs(file,ccs,body_message,subjects)
    from = "freereg-contacts@freereg.org.uk" if from.blank?
    unless file.nil?
      attachments["log_#{Date.today.strftime('%Y_%m_%d')}.txt"] = File.read(file)
    end
    mail(:from => from ,:to => "freereg-contacts@freereg.org.uk",  :bcc => ccs, :subject => subjects,:body => body_message)
  end

  def update_report_to_freereg_manager(file,user)
    attachments["report.log"] = File.read(file)
    @person_forename = user.person_forename
    # userid is REGManager, so no need to check email_address_valid
    @email_address = user.email_address
    mail(:from => "freereg-processing@freereg.org.uk",:to => "#{@person_forename} <#{@email_address}>", :subject => "FreeReg update processing report")
  end

  def volunteer(contact,ccs)
    @contact = contact
    get_attachment
    mail(:from => "freereg-contacts@freereg.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>", :cc => ccs, :subject => "Thank you for question about volunteering. Reference #{@contact.identifier}")
  end

  def website(contact,ccs)
    @contact = contact
    get_attachment
    mail(:from => "freereg-contacts@freereg.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>",:cc => ccs, :subject => "Thank you for reporting a website problem. Reference #{@contact.identifier}")
  end

end
