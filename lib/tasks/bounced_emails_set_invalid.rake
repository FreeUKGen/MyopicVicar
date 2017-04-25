require 'net/http'
require 'json'

namespace :freereg do

  desc "Bounced emails set invalid email address flag"
  task :bounced_emails_set_invalid,[:fix] => [:environment] do |t,args|
    change_email = (args[:fix].nil?)? false : true
  
    MY_LOG = Logger.new("#{Rails.root}/log/bounced_mails_#{Date.today.strftime('%Y_%m_%d')}.log")
    url = 'https://api.sendgrid.com/v3/suppression/bounces'
    port = URI.parse(url).port
    host = URI.parse(url).host
    response = nil
    api_key = Rails.application.config.sendgrid_api_key

    Net::HTTP.start(host, port,:use_ssl => true) do |http|
      request = Net::HTTP::Get.new("#{url}")
      request.add_field("Authorization","Bearer #{api_key}")
      request.content_type = 'application/json'
      response = http.request request
    end

    (JSON.parse response.body).each do |data|
        user =  UseridDetail.where(email_address: data['email'])[0]
        if user != nil
          MY_LOG.info("#{user.userid} / #{user.email_address} was bounced, because --> #{data['reason']}")
          user.update_attribute(:email_address_valid,false) if change_email
        end
    end    

  end
end