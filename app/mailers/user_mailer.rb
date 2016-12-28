class UserMailer < ActionMailer::Base

  default from: "freereg-contacts@freereg.org.uk"

  def batch_processing_failure(message,user,batch)
    @message = File.read(message)
    @userid = UseridDetail.where(userid: user).first
    if @userid.present?
      emails = Array.new
      unless @userid.nil? || !@userid.active
        user_email_with_name = @userid.email_address
        emails <<  user_email_with_name
      end
      syndicate_coordinator = nil
      syndicate_coordinator = Syndicate.where(syndicate_code: @userid.syndicate).first
      if syndicate_coordinator.present?
        syndicate_coordinator = syndicate_coordinator.syndicate_coordinator
        sc = UseridDetail.where(userid: syndicate_coordinator).first
        if sc.present?
          sc_email_with_name = sc.email_address
          emails << sc_email_with_name unless user_email_with_name == sc_email_with_name
        end
      end
      @batch = Freereg1CsvFile.where(file_name: batch, userid: user).first
      county = County.where(chapman_code: @batch.county).first unless @batch.nil?
      if county.present?
        county_coordinator = county.county_coordinator
        cc = UseridDetail.where(userid: county_coordinator).first
        if cc.present?
          cc_email_with_name = cc.email_address
          emails << cc_email_with_name unless cc_email_with_name == sc_email_with_name
        end
      end

      if emails.length == 1
        mail(:from => "freereg-processing@freereg.org.uk",:to => emails[0],  :subject => "#{@userid.userid}/#{batch} failed to be processed at #{Time.now}")
      elsif emails.length == 2
        mail(:from => "freereg-processing@freereg.org.uk",:to => emails[0], :cc => emails[1], :subject => "#{@userid.userid}/#{batch} failed to be processed by FreeReg at #{Time.now}")
      elsif emails.length == 3
        first_mail = emails.shift
        mail(:from => "freereg-processing@freereg.org.uk",:to => first_mail, :cc => emails, :subject => "#{@userid.userid}/#{batch} failed to be processed by FreeReg at #{Time.now}")
      end
    end
  end

  def batch_processing_success(file,user,batch)
    @message = File.read(file)
    @userid = UseridDetail.where(userid: user).first
    if @userid.present?
      emails = Array.new
      unless @userid.nil? || !@userid.active
        user_email_with_name =  @userid.email_address
        emails <<  user_email_with_name
      end
      syndicate_coordinator = nil
      syndicate_coordinator = Syndicate.where(syndicate_code: @userid.syndicate).first
      if syndicate_coordinator.present?
        syndicate_coordinator = syndicate_coordinator.syndicate_coordinator
        sc = UseridDetail.where(userid: syndicate_coordinator).first
        if sc.present?
          sc_email_with_name =  sc.email_address
          emails << sc_email_with_name unless user_email_with_name == sc_email_with_name
        end
      end
      @batch = Freereg1CsvFile.where(file_name: batch, userid: user).first
      county = County.where(chapman_code: @batch.county).first unless @batch.nil?
      if county.present?
        county_coordinator = county.county_coordinator
        cc = UseridDetail.where(userid: county_coordinator).first
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
      p @contact.screenshot.path
      attachments[@image] = File.binread(@contact.screenshot.path)
    end
  end

  def get_coordinator_name
    coordinator = Syndicate.where(:syndicate_code => @user.syndicate).first
    if coordinator.nil?
      @coordinator = nil
    else
      coordinator = coordinator.syndicate_coordinator
      @coordinator = UseridDetail.where(:userid => coordinator).first
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
      mail(:from => "freereg-registration@freereg.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :cc => "#{reg_manager.person_forename} <#{reg_manager.email_address}>", :subject => "FreeReg registration completion")
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

  def publicity(contact,ccs)
    @ccs = ccs
    @contact = contact
    get_attachment
    mail(:from => "freereg-contacts@freereg.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>",:cc => ccs, :subject => "Thank you for your compliments. Reference #{@contact.identifier}")
  end

  def send_change_of_syndicate_notification_to_sc(user)
    @user = user
    get_coordinator_name
    mail(:from => "freereg-registration@freereg.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "FreeReg change of syndicate") unless @coordinator.blank?
  end

  def send_message(mymessage,ccs,from)
    @message = mymessage
    from = "freereg-contacts@freereg.org.uk" if from.blank?
    get_message_attachment if @message.attachment.present? ||  @message.images.present?
    mail(:from => from ,:to => "freereg-contacts@freereg.org.uk",  :bcc => ccs, :subject => "#{@message.subject}. Reference #{@message.identifier}")
  end

  def update_report_to_freereg_manager(file,user)
    attachments["report.log"] = File.read(file)
    @person_forename = user.person_forename
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
