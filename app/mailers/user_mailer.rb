class UserMailer < ActionMailer::Base
  if MyopicVicar::Application.config.template_set == 'freereg'
    default from: "reg-web@freereg.org.uk"
  elsif MyopicVicar::Application.config.template_set == 'freecen'
    default from: "cen-web@freecen.org.uk"
  end

  def batch_processing_success(user,batch)
    @userid = UseridDetail.where(userid: user).first
    #syndicate_coordinator = Syndicate.where(syndicate_code: userid.syndicate).first.syndicate_coordinator
    #sc = UseridDetail.where(userid: syndicate_coordinator).first
    #@batch = Freereg1CsvFile.where(file_name: batch, userid: user).first
    #county_coordinator = County.where(chapman_code: @batch.county).first.county_coordinator
    #cc = UseridDetail.where(userid: county_coordinator).first
    mail(:to => "#{@userid.person_forename} <#{@userid.email_address}>", :subject => "FreeReg2 processed #{batch}") unless @userid.nil?
    #mail(:to => "#{sc.person_forename} <#{sc.email_address}>", :subject => "Batch Processing")
    #mail(:to => "#{cc.person_forename} <#{cc.email_address}>", :subject => "Batch Processing") unless county_coordinator == syndicate_coordinator
  end

  def batch_processing_failure(file,user,batch)
    attachments["report.txt"] = File.read(file)
    @userid = UseridDetail.where(userid: user).first
   # syndicate_coordinator = Syndicate.where(syndicate_code: @userid.syndicate).first.syndicate_coordinator
    #sc = UseridDetail.where(userid: syndicate_coordinator).first
    @batch = Freereg1CsvFile.where(file_name: batch, userid: user).first
    #county_coordinator = County.where(chapman_code: @batch.county).first.county_coordinator
    #cc = UseridDetail.where(userid: county_coordinator).first
    mail(:to => "#{@userid.person_forename} <#{@userid.email_address}>", :subject => "FreeReg2 processed #{batch}")
   # mail(:to => "#{sc.person_forename} <#{sc.email_address}>", :subject => "FreeReg2 processed #{batch}")
    #mail(:to => "#{cc.person_forename} <#{cc.email_address}>", :subject => "Batch Processing") unless county_coordinator == syndicate_coordinator
  end

  def update_report_to_freereg_manager(file,user)
    appname = MyopicVicar::Application.config.freexxx_display_name
    attachments["report.log"] = File.read(file)
    @person_forename = user.person_forename
    @email_address = user.email_address
    mail(:to => "#{@person_forename} <#{@email_address}>", :subject => "#{appname} Update")
  end

  def invitation_to_register_transcriber(user)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @user = user
    get_coordinator_name
    get_token
    mail(:to => "#{@user.person_forename} <#{@user.email_address}>", :subject => "#{appname} Registration")
  end

  def invitation_to_register_researcher(user)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @user = user
    get_coordinator_name
    get_token
    mail(:to => "#{@user.person_forename} <#{@user.email_address}>", :subject => "#{appname} Registration")
  end

  def invitation_to_register_technical(user)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @user = user
    get_coordinator_name
    get_token
    mail(:to => "#{@user.person_forename} <#{@user.email_address}>", :subject => "#{appname} Registration")
  end

  def invitation_to_reset_password(user)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @user = user
    get_coordinator_name
    get_token
    mail(:to => "#{@user.person_forename} <#{@user.email_address}>", :subject => "#{appname} Password Reset")
  end

  def notification_of_transcriber_creation(user)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @user = user
    get_coordinator_name
    mail(:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "#{appname} Registration") unless @coordinator.nil?
  end

  def notification_of_transcriber_registration(user)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @user = user
    get_coordinator_name
    mail(:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "#{appname} Registration") unless @coordinator.nil?
  end

  def notification_of_researcher_registration(user)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @user = user
    get_coordinator_name
    mail(:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "#{appname} Registration") unless @coordinator.nil?
  end

  def notification_of_technical_registration(user)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @user = user
    get_coordinator_name
    mail(:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "#{appname} Registration") unless @coordinator.nil?
  end

  def notification_of_registration_completion(user)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @user = user
    if MyopicVicar::Application.config.template_set == 'freereg'
      manager = UseridDetail.userid("REGManager").first
    elsif MyopicVicar::Application.config.template_set == 'freecen'
      manager = UseridDetail.userid("CENManager").first
    else
      manager = nil
    end
    get_coordinator_name
    mail(:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "#{appname} Registration Completion") unless @coordinator.nil?
    mail(:to => "#{manager.person_forename} <#{manager.email_address}>", :subject => "#{appname} Registration Completion") unless manager.nil?
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
    appname = MyopicVicar::Application.config.freexxx_display_name
    @contact = contact
    mail(:to => "#{@contact.name} <#{@contact.email_address}>", :subject => "Thank you for contacting us (#{appname})")
  end

  def contact_to_freexxx_manager(contact,person,ccs)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @ccs = ccs
    @contact = contact
    @name = person.person_forename
    @email_address = person.email_address
    mail(:to => "#{@name} <#{@email_address}>", :subject => "Copy of a #{appname} Contact")
  end

  def contact_to_recipient(contact,person,ccs)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @ccs = ccs
    @contact = contact
    @name = person.person_forename
    @email_address = person.email_address
    mail(:to => "#{@name} <#{@email_address}>", :subject => "Copy of a #{appname} Contact")
  end
  def contact_to_volunteer(contact,person,ccs)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @ccs = ccs
    @contact = contact
    @name = person.person_forename
    @email_address = person.email_address
    mail(:to => "#{@name} <#{@email_address}>", :subject => "Copy of a #{appname} Contact")
  end

  def contact_to_data_manager(contact,person,ccs)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @ccs = ccs
    @contact = contact
    @name = person.person_forename
    @email_address = person.email_address
    mail(:to => "#{@name} <#{@email_address}>", :subject => "Copy of a #{appname} Contact")
  end
  def contact_to_coordinator(contact,person,ccs)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @ccs = ccs
    @contact = contact
    @name = person.person_forename
    @email_address = person.email_address
    mail(:to => "#{@name} <#{@email_address}>", :subject => "Data Error Report from a #{appname} contact")
  end
end
