class UserMailer < ActionMailer::Base
  default from: "reg-web@freereg.org.uk"

  def batch_processing_success(user,batch,records,error,headers)
    @userid = UseridDetail.where(userid: user).first
    @errors = error
    @headers = headers
    @records = records
    syndicate_coordinator = Syndicate.where(syndicate_code: @userid.syndicate).first.syndicate_coordinator
    sc = UseridDetail.where(userid: syndicate_coordinator).first
    @batch = Freereg1CsvFile.where(file_name: batch, userid: user).first
    county = County.where(chapman_code: @batch.county).first unless @batch.nil?
    cc = nil
    if county.present?
      county_coordinator = county.county_coordinator
      cc = UseridDetail.where(userid: county_coordinator).first
    end
    mail(:to => "#{@userid.person_forename} <#{@userid.email_address}>", :subject => "FreeReg processed #{batch}") if @userid.active
    mail(:to => "#{sc.person_forename} <#{sc.email_address}>", :subject => "FreeReg processed #{batch}") unless sc.email_address == @userid.email_address
   # mail(:to => "#{cc.person_forename} <#{cc.email_address}>", :subject => "FreeReg processed #{batch}") unless cc.email_address == @userid.email_address || cc.email_address == sc.email_address || cc.nil?
  end

  def batch_processing_failure(message,user,batch)
    @message = message
    @userid = UseridDetail.where(userid: user).first
    syndicate_coordinator = Syndicate.where(syndicate_code: @userid.syndicate).first.syndicate_coordinator
    sc = UseridDetail.where(userid: syndicate_coordinator).first
    @batch = Freereg1CsvFile.where(file_name: batch, userid: user).first
    county = County.where(chapman_code: @batch.county).first unless @batch.nil?
    cc = nil
    if county.present?
      county_coordinator = county.county_coordinator
      cc = UseridDetail.where(userid: county_coordinator).first
    end
    mail(:to => "#{@userid.person_forename} <#{@userid.email_address}>", :subject => "FreeReg failed to process #{batch}") if @userid.active
    mail(:to => "#{sc.person_forename} <#{sc.email_address}>", :subject => "FreeReg failed to process #{batch}") unless sc.email_address == @userid.email_address 
  #  mail(:to => "#{cc.person_forename} <#{cc.email_address}>", :subject => "FreeReg failed to process #{batch}") unless cc.email_address == @userid.email_address || cc.email_address == sc.email_address || cc.nil?
  end

  def update_report_to_freereg_manager(file,user)
    attachments["report.log"] = File.read(file)
    @person_forename = user.person_forename
    @email_address = user.email_address
    mail(:to => "#{@person_forename} <#{@email_address}>", :subject => "FreeREG Update processing report")
  end

  def invitation_to_register_transcriber(user)
    @user = user
    get_coordinator_name
    get_token
    mail(:to => "#{@user.person_forename} <#{@user.email_address}>", :subject => "Invitation to complete FreeREG Registration")
  end

  def invitation_to_register_researcher(user)
    @user = user
    get_coordinator_name
    get_token
    mail(:to => "#{@user.person_forename} <#{@user.email_address}>", :subject => "Invitation to complete FreeREG Registration")
  end

  def invitation_to_register_technical(user)
    @user = user
    get_coordinator_name
    get_token
    mail(:to => "#{@user.person_forename} <#{@user.email_address}>", :subject => "Invitation to complete FreeREG Registration")
  end

  def invitation_to_reset_password(user)
    @user = user
    get_coordinator_name
    get_token
    mail(:to => "#{@user.person_forename} <#{@user.email_address}>", :subject => "Password Reset for FreeREG ")
  end

  def notification_of_transcriber_creation(user)
    @user = user
    get_coordinator_name
    mail(:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "FreeREG Userid Creation") unless @coordinator.nil?
  end

  def notification_of_transcriber_registration(user)
    @user = user
    get_coordinator_name
    mail(:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "FreeREG Transcriber Registration") unless @coordinator.nil?
  end

  def notification_of_researcher_registration(user)
    @user = user
    get_coordinator_name
    mail(:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "FreeREG Research Registration") unless @coordinator.nil?
  end

  def notification_of_technical_registration(user)
    @user = user
    get_coordinator_name
    mail(:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "FreeREG Technical Registration notification") unless @coordinator.nil?
  end

  def notification_of_registration_completion(user)
    @user = user
    reg_manager = UseridDetail.userid("REGManager").first
    get_coordinator_name
    mail(:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "FreeREG Registration Completion") unless @coordinator.nil?
    mail(:to => "#{reg_manager.person_forename} <#{reg_manager.email_address}>", :subject => "FreeREG Registration Completion") unless reg_manager.nil?
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

  def copy_to_contact_person(contact)
    @contact = contact
    mail(:to => "#{@contact.name} <#{@contact.email_address}>", :subject => "Thank you for contacting us")
  end

  def contact_to_freereg_manager(contact,person,ccs)
    @ccs = ccs
    @contact = contact
    @name = person.person_forename
    @email_address = person.email_address
    mail(:to => "#{@name} <#{@email_address}>", :subject => "Copy of a FreeREG Contact")
  end

  def contact_to_recipient(contact,person,ccs)
    @ccs = ccs
    @contact = contact
    @name = person.person_forename
    @email_address = person.email_address
    mail(:to => "#{@name} <#{@email_address}>", :subject => "Copy of a FreeREG Contact")
  end
  def contact_to_volunteer(contact,person,ccs)
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
    mail(:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "FreeREG2 Change of Syndicate") unless @coordinator.blank?
  end
end
