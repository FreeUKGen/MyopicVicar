class UserMailer < ActionMailer::Base
  default from: "reg-web@freereg.org.uk"

  def batch_processing_success(user,batch)
     userid = UseridDetail.where(userid: user).first 
     @user = userid
     syndicate_coordinator = Syndicate.where(syndicate_code: userid.syndicate).first.syndicate_coordinator
  	 sc = UseridDetail.where(userid: syndicate_coordinator).first 
     @batch = Freereg1CsvFile.where(file_name: batch, userid: user).first
  	 county_coordinator = County.where(chapman_code: @batch.county).first.county_coordinator
     cc = UseridDetail.where(userid: county_coordinator).first 
     mail(:to => "#{userid.person_forename} <#{userid.email_address}>", :subject => "Batch Processing")
     mail(:to => "#{sc.person_forename} <#{sc.email_address}>", :subject => "Batch Processing")
     mail(:to => "#{cc.person_forename} <#{cc.email_address}>", :subject => "Batch Processing") unless county_coordinator == syndicate_coordinator
  end
  def batch_processing_failure(user,batch)
     userid = UseridDetail.where(userid: user).first 
     @user = userid
     syndicate_coordinator = Syndicate.where(syndicate_code: userid.syndicate).first.syndicate_coordinator
     sc = UseridDetail.where(userid: syndicate_coordinator).first 
     @batch = Freereg1CsvFile.where(file_name: batch, userid: user).first
     county_coordinator = County.where(chapman_code: @batch.county).first.county_coordinator
     cc = UseridDetail.where(userid: county_coordinator).first 
     mail(:to => "#{userid.person_forename} <#{userid.email_address}>", :subject => "Batch Processing")
     mail(:to => "#{sc.person_forename} <#{sc.email_address}>", :subject => "Batch Processing")
     mail(:to => "#{cc.person_forename} <#{cc.email_address}>", :subject => "Batch Processing") unless county_coordinator == syndicate_coordinator
  end

  def invitation_to_register_transcriber(user)
    @user = user
    get_coordinator_name
    get_token
    mail(:to => "#{@user.person_forename} <#{@user.email_address}>", :subject => "FreeREG Registration")
  end
 def invitation_to_register_researcher(user)
    @user = user
    get_coordinator_name
    get_token
    mail(:to => "#{@user.person_forename} <#{@user.email_address}>", :subject => "FreeREG Registration")
  end

  def invitation_to_register_technical(user)
    @user = user
    get_coordinator_name
    get_token
    mail(:to => "#{@user.person_forename} <#{@user.email_address}>", :subject => "FreeREG Registration")
  end
  def invitation_to_reset_password(user)
    @user = user
    get_coordinator_name
    get_token
    mail(:to => "#{@user.person_forename} <#{@user.email_address}>", :subject => "FreeREG Password Reset")
  end
  def notification_of_transcriber_creation(user)
    @user = user
    get_coordinator_name
    mail(:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "FreeREG Registration") unless @coordinator.nil?
  end

  def notification_of_transcriber_registration(user)
    @user = user
    get_coordinator_name
    mail(:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "FreeREG Registration") unless @coordinator.nil?
  end
   def notification_of_researcher_registration(user)
    @user = user
    get_coordinator_name
    mail(:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "FreeREG Registration") unless @coordinator.nil?
  end
def notification_of_technical_registration(user)
   @user = user
   get_coordinator_name
   mail(:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "FreeREG Registration") unless @coordinator.nil?
end
def notification_of_registration_completion(user)
   @user = user
   get_coordinator_name
   mail(:to => "#{@coordinator.person_forename} <#{@coordinator.email_address}>", :subject => "FreeREG Registration") unless @coordinator.nil?
  
end
def reset_notification(user)
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

end
