class UserMailer < ActionMailer::Base
  default from: "reg-web@freereg.org.uk"

  def batch_processing_success(user,batch,records,error,headers)
    @userid = UseridDetail.where(userid: user).first
    if @userid.present?
      @errors = error
      @headers = headers
      @records = records
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
         mail(:from => "freereg_processing@freereg.org.uk", :to => emails[0],  :subject => "#{@userid.userid}/#{batch} was processed by FreeREG at #{Time.now}")
      elsif emails.length == 2
        mail(:from => "freereg_processing@freereg.org.uk",:to => emails[0], :cc => emails[1], :subject => "#{@userid.userid}/#{batch} was processed by FreeREG at #{Time.now}")
      elsif emails.length == 3
        first_mail = emails.shift
        mail(:from => "freereg_processing@freereg.org.uk",:to => first_mail, :cc => emails, :subject =>"#{@userid.userid}/#{batch} was processed by FreeREG at #{Time.now}") 
      end 
    end
  end

  def batch_processing_failure(message,user,batch)
    @message = message
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
         mail(:from => "freereg_processing@freereg.org.uk",:to => emails[0],  :subject => "#{@userid.userid}/#{batch} failed to be processed by FreeREG at #{Time.now}")
      elsif emails.length == 2
        mail(:from => "freereg_processing@freereg.org.uk",:to => emails[0], :cc => emails[1], :subject => "#{@userid.userid}/#{batch} failed to be processed by FreeREG at #{Time.now}")
      elsif emails.length == 3
        first_mail = emails.shift
        mail(:from => "freereg_processing@freereg.org.uk",:to => first_mail, :cc => emails, :subject => "#{@userid.userid}/#{batch} failed to be processed by FreeREG at #{Time.now}")
      end 
    end
  end

  def update_report_to_freereg_manager(file,user)
    attachments["report.log"] = File.read(file)
    @person_forename = user.person_forename
    @email_address = user.email_address
    mail(:from => "freereg_processing@freereg.org.uk",:to => "#{@person_forename} <#{@email_address}>", :subject => "FreeREG Update processing report")
  end

  def invitation_to_register_transcriber(user)
    @user = user
    get_coordinator_name
    get_token
    mail(:from => "freereg_registration@freereg.org.uk",:to => "#{@user.person_forename} <#{@user.email_address}>", :subject => "Invitation to complete FreeREG Registration")
  end

  def invitation_to_register_researcher(user)
    @user = user
    get_coordinator_name
    get_token
    mail(:from => "freereg_registration@freereg.org.uk",:to => "#{@user.person_forename} <#{@user.email_address}>", :subject => "Invitation to complete FreeREG Registration")
  end

  def invitation_to_register_technical(user)
    @user = user
    get_coordinator_name
    get_token
    mail(:from => "freereg_registration@freereg.org.uk",:to => "#{@user.person_forename} <#{@user.email_address}>", :subject => "Invitation to complete FreeREG Registration")
  end

  def invitation_to_reset_password(user)
    @user = user
    get_coordinator_name
    get_token
    mail(:from => "freereg_registration@freereg.org.uk",:to => "#{@user.person_forename} <#{@user.email_address}>", :subject => "Password Reset for FreeREG ")
  end

  def notification_of_transcriber_creation(user)
    @user = user
    get_coordinator_name
    mail(:from => "freereg_registration@freereg.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "FreeREG Userid Creation") unless @coordinator.nil?
  end

  def notification_of_transcriber_registration(user)
    @user = user
    get_coordinator_name
    mail(:from => "freereg_registration@freereg.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "FreeREG Transcriber Registration") unless @coordinator.nil?
  end

  def notification_of_researcher_registration(user)
    @user = user
    get_coordinator_name
    mail(:from => "freereg_registration@freereg.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "FreeREG Research Registration") unless @coordinator.nil?
  end

  def notification_of_technical_registration(user)
    @user = user
    get_coordinator_name
    mail(:from => "freereg_registration@freereg.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "FreeREG Technical Registration notification") unless @coordinator.nil?
  end

  def notification_of_registration_completion(user)
    @user = user
    reg_manager = UseridDetail.userid("REGManager").first
    get_coordinator_name 
    if Time.now - 5.days <= @user.c_at
      mail(:from => "freereg_registration@freereg.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :cc => "#{reg_manager.person_forename} <#{reg_manager.email_address}>", :subject => "FreeREG Registration Completion") 
    end
  end

  def reset_notification(user,z)
    user = UseridDetail.find(user.userid_detail_id)
    invitation_to_reset_password(user)
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

  def get_token
    refinery_user = Refinery::User.where(:username => @user.userid).first
    refinery_user.reset_password_token = Refinery::User.reset_password_token
    refinery_user.reset_password_sent_at = Time.now
    refinery_user.save!
    @user_token = refinery_user.reset_password_token
  end

  def contact(contact,ccs)
    @contact = contact
    bcc = UseridDetail.where(:userid => 'REGManager').limit(1).first
    ccs << bcc.email_address
    mail(:from => "freereg_contact@freereg.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>",  :bcc => ccs, :subject => "Thank you for contacting us")
  end
  def volunteer(contact,ccs)
    @contact = contact
    mail(:from => "freereg_contact@freereg.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>", :bcc => ccs, :subject => "Thank you for volunteering")
  end

  def website(contact,ccs)
    @contact = contact  
    mail(:from => "freereg_contact@freereg.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>",:bcc => ccs, :subject => "Thank you for reporting a Website problem")
  end

  def contact_to_recipient(contact,person,ccs)
    @ccs = ccs
    @contact = contact
    @name = person.person_forename
    @email_address = person.email_address
    mail(:to => "#{@name} <#{@email_address}>", :subject => "Copy of a FreeREG Contact")
  end
 

  def contact_to_data_manager(contact,person,ccs)
    @ccs = ccs
    @contact = contact
    @name = person.person_forename
    @email_address = person.email_address
    mail(:to => "#{@name} <#{@email_address}>", :subject => "Copy of a FreeREG Contact")
  end
  def contact_to_coordinator(contact,person,ccs)
    @ccs = ccs
    @contact = contact
    @name = person.person_forename
    @email_address = person.email_address
    mail(:to => "#{@name} <#{@email_address}>", :subject => "Data Error Report from a Contact")
  end
  def send_change_of_syndicate_notification_to_sc(user)
    @user = user
    get_coordinator_name
    mail(:from => "freereg_registration@freereg.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "FreeREG2 Change of Syndicate") unless @coordinator.blank?
  end
end
