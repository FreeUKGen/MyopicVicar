class UserMailer < ActionMailer::Base
  if MyopicVicar::Application.config.template_set == 'freereg'
    default from: "freereg-contacts@freereg.org.uk"
  elsif MyopicVicar::Application.config.template_set == 'freecen'
    default from: "freecen-contacts@freecen.org.uk"
  end

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
         mail(:from => "freereg-processing@freereg.org.uk", :to => emails[0],  :subject => "#{@userid.userid}/#{batch} was processed by FreeReg at #{Time.now}")
      elsif emails.length == 2
        mail(:from => "freereg-processing@freereg.org.uk",:to => emails[0], :cc => emails[1], :subject => "#{@userid.userid}/#{batch} was processed by FreeReg at #{Time.now}")
      elsif emails.length == 3
        first_mail = emails.shift
        mail(:from => "freereg-processing@freereg.org.uk",:to => first_mail, :cc => emails, :subject =>"#{@userid.userid}/#{batch} was processed by FreeReg at #{Time.now}") 
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
         mail(:from => "freereg-processing@freereg.org.uk",:to => emails[0],  :subject => "#{@userid.userid}/#{batch} failed to be processed by FreeReg at #{Time.now}")
      elsif emails.length == 2
        mail(:from => "freereg-processing@freereg.org.uk",:to => emails[0], :cc => emails[1], :subject => "#{@userid.userid}/#{batch} failed to be processed by FreeReg at #{Time.now}")
      elsif emails.length == 3
        first_mail = emails.shift
        mail(:from => "freereg-processing@freereg.org.uk",:to => first_mail, :cc => emails, :subject => "#{@userid.userid}/#{batch} failed to be processed by FreeReg at #{Time.now}")
      end 
    end
  end

  def update_report_to_freereg_manager(file,user)
    attachments["report.log"] = File.read(file)
    @person_forename = user.person_forename
    @email_address = user.email_address
    mail(:from => "freereg-processing@freereg.org.uk",:to => "#{@person_forename} <#{@email_address}>", :subject => "FreeReg update processing report")
  end

  def invitation_to_register_transcriber(user)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @user = user
    get_coordinator_name
    get_token
    mail(:from => "#{appname.downcase}-registration@#{appname.downcase}.org.uk",:to => "#{@user.person_forename} <#{@user.email_address}>", :subject => "Invitation to complete #{appname} Registration")
  end

  def invitation_to_register_researcher(user)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @user = user
    get_coordinator_name
    get_token
    mail(:from => "#{appname.downcase}-registration@#{appname.downcase}.org.uk",:to => "#{@user.person_forename} <#{@user.email_address}>", :subject => "Invitation to complete #{appname} registration")
  end

  def invitation_to_register_technical(user)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @user = user
    get_coordinator_name
    get_token
    mail(:from => "#{appname.downcase}-registration@#{appname.downcase}.org.uk",:to => "#{@user.person_forename} <#{@user.email_address}>", :subject => "Invitation to complete #{appname} registration")
  end

  def invitation_to_reset_password(user)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @user = user
    get_coordinator_name
    get_token
    mail(:from => "#{appname.downcase}-registration@#{appname.downcase}.org.uk",:to => "#{@user.person_forename} <#{@user.email_address}>", :subject => "Password reset for #{appname} ")
  end

  def notification_of_transcriber_creation(user)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @user = user
    get_coordinator_name
    mail(:from => "#{appname.downcase}-registration@#{appname.downcase}.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "#{appname} userid creation") unless @coordinator.nil?
  end

  def notification_of_transcriber_registration(user)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @user = user
    get_coordinator_name
    mail(:from => "#{appname.downcase}-registration@#{appname.downcase}.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "#{appname} transcriber registration") unless @coordinator.nil?
  end

  def notification_of_researcher_registration(user)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @user = user
    get_coordinator_name
    mail(:from => "#{appname.downcase}-registration@#{appname.downcase}.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "#{appname} research registration") unless @coordinator.nil?
  end

  def notification_of_technical_registration(user)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @user = user
    get_coordinator_name
    mail(:from => "#{appname.downcase}-registration@#{appname.downcase}.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "#{appname} technical registration notification") unless @coordinator.nil?
  end

  def notification_of_registration_completion(user)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @user = user
    manager = nil
    if MyopicVicar::Application.config.template_set == 'freereg'
      manager = UseridDetail.userid("REGManager").first
    elsif MyopicVicar::Application.config.template_set == 'freecen'
      manager = UseridDetail.userid("CENManager").first
    end
    get_coordinator_name
    if Time.now - 5.days <= @user.c_at
      subj = "#{appname} registration completion"
      if @coordinator.nil?
        to_email = "#{manager.person_forename} <#{manager.email_address}>" unless manager.nil?
        cc_email = nil
        subj = "NO COORDINATOR!" + subj
      else
        to_email = "#{@coordinator.person_forename} <#{@coordinator.email_address}>"
        cc_email = "#{manager.person_forename} <#{manager.email_address}>" unless manager.nil?
      end
      mail(:from => "#{appname.downcase}-registration@#{appname.downcase}.org.uk",:to => to_email, :cc => cc_email, :subject => subj) unless to_email.nil?
    end
  end

  def reset_notification(user,z)
    user = UseridDetail.find(user.userid_detail_id)
    invitation_to_reset_password(user)
  end

  def enhancement(contact,ccs)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @contact = contact
    get_attachment
    mail(:from => "#{appname.downcase}-contacts@#{appname.downcase}.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>",  :cc => ccs, :subject => "Thank you for the suggested enhancement. Reference #{@contact.identifier}")
  end

  def general(contact,ccs)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @contact = contact
    get_attachment
    mail(:from => "#{appname.downcase}-contacts@#{appname.downcase}.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>",  :cc => ccs, :subject => "Thank you for the general comment. Reference #{@contact.identifier}")
  end

  def genealogy(contact,css)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @contact = contact
    get_attachment
    mail(:from => "#{appname.downcase}-contacts@#{appname.downcase}.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>",   :subject => "Thank you for a genealogical question. Reference #{@contact.identifier}")
  end

  def volunteer(contact,ccs)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @contact = contact
    get_attachment
    mail(:from => "#{appname.downcase}-contacts@#{appname.downcase}.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>", :cc => ccs, :subject => "Thank you for question about volunteering. Reference #{@contact.identifier}")
  end

  def website(contact,ccs)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @contact = contact 
    get_attachment
    mail(:from => "#{appname.downcase}-contacts@#{appname.downcase}.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>",:cc => ccs, :subject => "Thank you for reporting a website problem. Reference #{@contact.identifier}")
  end

  def feedback(contact,ccs)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @contact = contact 
    @user = UseridDetail.userid(@contact.user_id).first
    get_attachment
    mail(:from => "#{appname.downcase}-contacts@#{appname.downcase}.org.uk",:to => "#{@user.person_forename} <#{@user.email_address}>",:cc => ccs, :subject => "Thank you for your feedback. Reference #{@contact.identifier}")
  end

  def publicity(contact,ccs)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @ccs = ccs
    @contact = contact
    get_attachment
    mail(:from => "#{appname.downcase}-contacts@#{appname.downcase}.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>",:cc => ccs, :subject => "Thank you for your compliments. Reference #{@contact.identifier}")
  end
 
  def datamanager_data_question(contact,ccs)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @contact = contact
    get_attachment
    mail(:from => "#{appname.downcase}-contacts@#{appname.downcase}.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>",:cc => ccs, :subject => "Thank you for your data question. Reference #{@contact.identifier}")
  end

  def coordinator_data_problem(contact,ccs)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @contact = contact
    get_attachment
    mail(:from => "#{appname.downcase}-contacts@#{appname.downcase}.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>",:cc => ccs, :subject => "Thank you for reporting a problem with our data. Reference #{@contact.identifier}")

  end

  def send_change_of_syndicate_notification_to_sc(user)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @user = user
    get_coordinator_name
    mail(:from => "#{appname.downcase}-registration@#{appname.downcase}.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "#{appname} change of syndicate") unless @coordinator.blank?
  end

  def get_attachment
    if @contact.screenshot_url.present?
      @image = File.basename(@contact.screenshot.path)
      @file = "#{Rails.root}/public" + @contact.screenshot_url
      attachments[@image] = File.binread(@file)
    end
  end

  def get_coordinator_name
    @coordinator = nil
    coordinator = Syndicate.where(:syndicate_code => @user.syndicate).first
    unless coordinator.nil?
      coordinator = coordinator.syndicate_coordinator
      @coordinator = UseridDetail.where(:userid => coordinator).first unless coordinator.nil?
    end
  end

  def get_token
    refinery_user = Refinery::User.where(:username => @user.userid).first
    refinery_user.reset_password_token = Refinery::User.reset_password_token
    refinery_user.reset_password_sent_at = Time.now
    refinery_user.save!
    @user_token = refinery_user.reset_password_token
  end


# the following are from before pulling Kirk's latest re-write
#  def contact(contact,ccs)
#    appname = MyopicVicar::Application.config.freexxx_display_name
#    @contact = contact
#    if MyopicVicar::Application.config.template_set == 'freereg'
#      bcc = UseridDetail.where(:userid => 'REGManager').limit(1).first
#    elsif MyopicVicar::Application.config.template_set == 'freecen'
#      bcc = UseridDetail.where(:userid => 'CENManager').limit(1).first
#    end
#    ccs << bcc.email_address
#    mail(:from => "#{appname.downcase}-contacts@#{appname.downcase}.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>",  :cc => ccs, :subject => "Thank you for contacting us (#{appname})")
#  end

#  def copy_to_contact_person(contact)
#    appname = MyopicVicar::Application.config.freexxx_display_name
#    @contact = contact
#    if @contact.screenshot_url
#      atitle = File.basename(@contact.screenshot.path)
#      if File.size(@contact.screenshot.current_path) < 10000000 #only if < 10MB
#        attachments[atitle] = File.read(@contact.screenshot.current_path)
#      end
#    end
#    mail(:to => "#{@contact.name} <#{@contact.email_address}>", :subject => "Thank you for contacting us (#{appname})")
#  end

#  def volunteer(contact,ccs)
#    appname = MyopicVicar::Application.config.freexxx_display_name
#    @contact = contact
#  end

#  def website(contact,ccs)
#    appname = MyopicVicar::Application.config.freexxx_display_name
#    @contact = contact  
#    mail(:from => "#{appname.downcase}-contacts@#{appname.downcase}.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>",:cc => ccs, :subject => "Thank you for reporting a Website problem")
#  end

#  def contact_to_recipient(contact,person,ccs)
#    appname = MyopicVicar::Application.config.freexxx_display_name
#    @ccs = ccs
#    @contact = contact
#    @name = person.person_forename
#    @email_address = person.email_address
#    mail(:to => "#{@name} <#{@email_address}>", :subject => "Copy of a #{appname} Contact")
#  end
 

#  def contact_to_data_manager(contact,person,ccs)
#    appname = MyopicVicar::Application.config.freexxx_display_name
#    @ccs = ccs
#    @contact = contact
#    @name = person.person_forename
#    @email_address = person.email_address
#    mail(:to => "#{@name} <#{@email_address}>", :subject => "Copy of a #{appname} Contact")
#  end
#  def contact_to_coordinator(contact,person,ccs)
#    appname = MyopicVicar::Application.config.freexxx_display_name
#    @ccs = ccs
#    @contact = contact
#    @name = person.person_forename
#    @email_address = person.email_address
#    mail(:to => "#{@name} <#{@email_address}>", :subject => "Data Error Report from a #{appname} contact")
#  end
  
  def appname
    MyopicVicar::Application.config.freexxx_display_name
  end


  def get_token
    refinery_user = Refinery::User.where(:username => @user.userid).first
    refinery_user.reset_password_token = Refinery::User.reset_password_token
    refinery_user.reset_password_sent_at = Time.now
    refinery_user.save!
    @user_token = refinery_user.reset_password_token
  end

end
