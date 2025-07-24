require 'net/http'
require 'json'


namespace :freereg do

  desc "Bounced emails set invalid email address flag"
  task :bounced_emails_set_invalid,[:fix] => [:environment] do |t,args|
    require "syndicate"

    change_email = (args[:fix].nil?)? false : true

    log_file_name = "#{Rails.root}/log/bounced_mails_#{Date.today.strftime('%Y_%m_%d')}.log"
    MY_LOG = Logger.new(log_file_name)
    response = nil
    api_key = Rails.application.config.sendgrid_api_key
    hash_syncate_coordinator = Hash.new { |hash, key| hash[key] = [] }

    url = 'https://api.sendgrid.com/v3/suppression/bounces'
    port = URI.parse(url).port
    host = URI.parse(url).host

    Net::HTTP.start(host, port,:use_ssl => true) do |http|
      request = Net::HTTP::Get.new("#{url}")
      request.add_field("Authorization","Bearer #{api_key}")
      request.content_type = 'application/json'
      response = http.request request
    end

    ccs_system_administrator = []
    UseridDetail.role('system_administrator').where(recieve_system_emails: true).each do |userid|
      ccs_system_administrator << userid.email_address
    end
    email_of_nil_users = []
    user_with_nil_syndicate = []
    obj_syndicate = Hash.new { |hash, key| hash[key] = [] }
    MY_LOG.info("#{Time.new} =========== | Change_email value #{change_email.to_s} | ======================================\n")
    (JSON.parse response.body).each do |data|
      user =  UseridDetail.where(email_address: data['email'])[0]
      if user != nil && user.email_address_valid
        MY_LOG.info("#{user.userid} / #{user.email_address} was bounced, because --> #{data['reason']}\n")
        if user.syndicate != nil
          #syndicate = Syndicate.syndicate_code(user.syndicate)[0]
          #if syndicate != nil
           # sc = syndicate.syndicate_coordinator
            #hash_syncate_coordinator[sc].push(user.userid)
          #else
           # obj_syndicate[user.syndicate] << user.userid
          #end
        else
          user_with_nil_syndicate << user.userid
        end
        if change_email and (data['created'] > user.email_address_last_confirmned.to_i)
          user.update_attributes(email_address_valid: false,reason_for_invalidating: data['reason'],email_address_last_confirmned: user.sign_up_date)
        end
      else
        # email_of_nil_users << data['email'] These are other peoples emails
      end
    end

    if change_email
      hash_syncate_coordinator.each do |key,array_userid_bounced_mail|
        email_address_sc = UseridDetail.userid(key)[0].email_address
        UserMailer.send_logs(nil,email_address_sc,"These users have  bounced email: #{array_userid_bounced_mail.join(" \n")}", "#{MyopicVicar::Application.config.website} bounced emails logs").deliver_now
      end
    end
    # SEND  LOGS TO SYSTEM_ADMNISTRATORS
    UserMailer.send_logs("#{Rails.root}/log/bounced_mails_#{Date.today.strftime('%Y_%m_%d')}.log",ccs_system_administrator,"Logs with bounced emails!!!! and Emails not associated with users #{email_of_nil_users.join(" \n") if !email_of_nil_users.nil? }", "#{MyopicVicar::Application.config.website} logs bounced emails").deliver_now
    # SEND  USER WITH NIL SYNCATE TO SYSTEM_ADMNISTRATORS
    UserMailer.send_logs(nil,ccs_system_administrator,"These userids has empty syndicate attribute #{user_with_nil_syndicate.join(" \n")}\n", "#{MyopicVicar::Application.config.website} users with syndicate = nil").deliver_now if !user_with_nil_syndicate.empty?
    # SEND  SYNCATE WITH SPECIFIC NAME THAT HAS NO CORRESPONDENT OBJECT IN  DATABASE
    obj_syndicate.each do |key,array_userid_bounced_mail|
      UserMailer.send_logs(nil,ccs_system_administrator,"Syndicate #{key} with no correspondent object in database -  these users have latter syndicate in their object: #{array_userid_bounced_mail.join(" \n")}", "#{MyopicVicar::Application.config.website} user's syndicate that does not exit in database").deliver_now
    end

  end
end
