##############################################
# This file is in desperate need of refactoring
##############################################
class UserMailer < ActionMailer::Base
  if MyopicVicar::Application.config.template_set == 'freereg'
    default from: "freereg-contacts@freereg.org.uk"
  elsif MyopicVicar::Application.config.template_set == 'freecen'
    default from: "freecen-contacts@freecen.org.uk"
  end

  def appname
    MyopicVicar::Application.config.freexxx_display_name
  end

  def freecen_processing_report(to_email,subj,report)
    @freecen_report = report
    mail(:from => "freecen-processing@freecen.org.uk", :to => to_email, :subject => subj, :body => report, :content_type => "text/plain")
  end

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
    appname = MyopicVicar::Application.config.freexxx_display_name
    @contact = contact
    get_attachment
    mail(:from => "#{appname.downcase}-contacts@#{appname.downcase}.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>",:cc => ccs, :subject => "Thank you for reporting a problem with our data. Reference #{@contact.identifier}")
  end

  def datamanager_data_question(contact,ccs)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @contact = contact
    get_attachment
    mail(:from => "#{appname.downcase}-contacts@#{appname.downcase}.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>",:cc => ccs, :subject => "Thank you for your data question. Reference #{@contact.identifier}")
  end

  def enhancement(contact,ccs)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @contact = contact
    get_attachment
    mail(:from => "#{appname.downcase}-contacts@#{appname.downcase}.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>",  :cc => ccs, :subject => "Thank you for the suggested enhancement. Reference #{@contact.identifier}")
  end

  def feedback(contact,ccs)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @contact = contact 
    @user = UseridDetail.userid(@contact.user_id).first
    get_attachment
    mail(:from => "#{appname.downcase}-feedback@#{appname.downcase}.org.uk",:to => "#{@user.person_forename} <#{@user.email_address}>",:cc => ccs, :subject => "Thank you for your feedback. Reference #{@contact.identifier}")
  end

  def genealogy(contact,ccs)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @contact = contact
    get_attachment
    mail(:from => "#{appname.downcase}-contacts@#{appname.downcase}.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>",  :cc => ccs, :subject => "Thank you for a genealogical question. Reference #{@contact.identifier}")
  end

  def general(contact,ccs)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @contact = contact
    get_attachment
    mail(:from => "#{appname.downcase}-contacts@#{appname.downcase}.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>",  :cc => ccs, :subject => "Thank you for the general comment. Reference #{@contact.identifier}")
  end

  def get_attachment
    if @contact.screenshot_url.present?
      @image = File.basename(@contact.screenshot.path)
      attachments[@image] = File.binread(@contact.screenshot.path)
    end
  end

  def get_coordinator_name
    @coordinator = nil
    coordinator = Syndicate.where(:syndicate_code => @user.syndicate).first
    unless coordinator.nil?
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

  def notification_of_technical_registration(user)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @user = user
    manager = nil
    if MyopicVicar::Application.config.template_set == 'freereg'
      manager = UseridDetail.userid("REGManager").first
    elsif MyopicVicar::Application.config.template_set == 'freecen'
      manager = UseridDetail.userid("CENManager").first
    end
    get_coordinator_name
    mail(:from => "#{appname.downcase}-registration@#{appname.downcase}.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :cc => "#{manager.person_forename} <#{manager.email_address}>", :subject => "#{appname} technical registration notification") unless @coordinator.nil?
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
    manager = nil
    if MyopicVicar::Application.config.template_set == 'freereg'
      manager = UseridDetail.userid("REGManager").first
    elsif MyopicVicar::Application.config.template_set == 'freecen'
      manager = UseridDetail.userid("CENManager").first
    end
    get_coordinator_name
    mail(:from => "#{appname.downcase}-registration@#{appname.downcase}.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :cc => "#{manager.person_forename} <#{manager.email_address}>", :subject => "#{appname} transcriber registration") unless @coordinator.nil?
  end

  def notification_of_researcher_registration(user)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @user = user
    get_coordinator_name
    mail(:from => "#{appname.downcase}-registration@#{appname.downcase}.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "#{appname} research registration") unless @coordinator.nil?
  end

  def publicity(contact,ccs)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @ccs = ccs
    @contact = contact
    get_attachment
    mail(:from => "#{appname.downcase}-contacts@#{appname.downcase}.org.uk",:to => "#{@contact.name} <#{@contact.email_address}>",:cc => ccs, :subject => "Thank you for your compliments. Reference #{@contact.identifier}")
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

  def send_change_of_syndicate_notification_to_sc(user)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @user = user
    get_coordinator_name
    mail(:from => "#{appname.downcase}-registration@#{appname.downcase}.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "#{appname} change of syndicate") unless @coordinator.blank?
  end

  def send_change_of_email_notification_to_sc(user)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @user = user
    get_coordinator_name
    mail(:from => "#{appname.downcase}-registration@#{appname.downcase}.org.uk",:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "#{appname} change of email") unless @coordinator.blank?
  end


  def send_message(mymessage,ccs,from)
    appname = MyopicVicar::Application.config.freexxx_display_name
    @message = mymessage
    from = "#{appname.downcase}-contacts@#{appname.downcase}.org.uk" if from.blank?
    get_message_attachment if @message.attachment.present? ||  @message.images.present?
    mail(:from => from,:to => "#{appname.downcase}-contacts@#{appname.downcase}.org.uk",  :bcc => ccs, :subject => "#{@message.subject}. Reference #{@message.identifier}")
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

  def update_report_to_freecen_manager(report,user,ccs)
    attachments["report.txt"] = {:mime_type => 'text/plain', :content => report}
    #attachments["report.log"] = report
    @person_forename = user.person_forename
    @email_address = user.email_address
    mail(:from => "freecen-processing@freecen.org.uk",:to => "#{@person_forename} <#{@email_address}>", :cc=>ccs, :subject => "FreeCEN update processing report")
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

end
