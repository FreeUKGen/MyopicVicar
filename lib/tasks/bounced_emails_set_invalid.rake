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
    UseridDetail.role('system_administrator').each do |userid|
      ccs_system_administrator << userid.email_address
    end

    MY_LOG.info("#{Time.new} =========== | Change_email value #{change_email.to_s} | ======================================\n")
    (JSON.parse response.body).each do |data|
        user =  UseridDetail.where(email_address: data['email'])[0]
        if user != nil
          MY_LOG.info("#{user.userid} / #{user.email_address} was bounced, because --> #{data['reason']}\n")
          if change_email
            if user.syndicate != nil
              syndicate = Syndicate.syndicate_code(user.syndicate)[0]
              if syndicate != nil
                sc = syndicate.syndicate_coordinator
                hash_syncate_coordinator[sc].push(user.userid)
              else
                UserMailer.send_logs(nil,ccs_system_administrator,"Logs with bounced emails!!!!\n This is userid with bounced email: #{user.userid}\n OBS: There is no syncate called #{user.syndicate}\n").deliver_now
              end
            else
              UserMailer.send_logs(nil,ccs_system_administrator,"Logs with bounced emails!!!!\n This is userid with bounced email: #{user.userid}\n OBS: Syndicate empty\n").deliver_now
            end
            user.update_attributes(email_address_valid: false,reason_for_invalidating: data['reason'],email_address_last_confirmned: user.sign_up_date)
          end
        end
    end

    if change_email
      hash_syncate_coordinator.each do |key,array_userid_bounced_mail|
        email_address_sc = UseridDetail.userid(key)[0].email_address
        UserMailer.send_logs(nil,email_address_sc,"Logs with bounced emails!!!!\n This is userid with  bounced email: #{array_userid_bounced_mail.join(" \n")}").deliver_now
      end
    end

    UserMailer.send_logs("#{Rails.root}/log/bounced_mails_#{Date.today.strftime('%Y_%m_%d')}.log",ccs_system_administrator,"Logs with bounced emails!!!!").deliver_now

  end
end