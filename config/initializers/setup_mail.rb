require 'development_mail_interceptor'
if Rails.env.development?
  ActionMailer::Base.register_interceptor(DevelopmentMailInterceptor)
  case Rails.application.config.website
  when 'https://test2.freereg.org.uk'
    ActionMailer::Base.delivery_method = :sendmail
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.raise_delivery_errors = true
  when 'https://test2.freecen.org.uk'
    ActionMailer::Base.delivery_method = :sendmail
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.raise_delivery_errors = true
  when 'https://test2.freebmd.org.uk'
    ActionMailer::Base.delivery_method = :sendmail
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.raise_delivery_errors = true
  when 'localhost:3000'
    if ENV['gmail_username'].present? && ENV['gmail_password'].present?
      ActionMailer::Base.perform_deliveries = true
      ActionMailer::Base.raise_delivery_errors = true
      ActionMailer::Base.smtp_settings = {
        :address              => "smtp.gmail.com",
        :port                 => 587,
        :user_name            => ENV['gmail_username'],
        :password             => ENV['gmail_password'],
        :authentication       => "plain",
        :enable_starttls_auto => true,
        :openssl_verify_mode => 'none'
      }
    else
      # No Gmail credentials configured locally (see config/application.yml) -
      # skip delivery instead of crashing rake tasks/requests that try to send mail.
      ActionMailer::Base.perform_deliveries = false
      ActionMailer::Base.raise_delivery_errors = false
    end
  end
else
  ActionMailer::Base.delivery_method = :sendmail
  ActionMailer::Base.perform_deliveries = true
  ActionMailer::Base.raise_delivery_errors = true
end
ActionMailer::Base.sendmail_settings = { location: '/usr/sbin/sendmail', arguments: '-i' }
ActionMailer::Base.default_url_options[:host] = Rails.application.config.website
