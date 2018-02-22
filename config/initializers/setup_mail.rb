if Rails.env.development? && !(Rails.application.config.website == 'http://test2.freereg.org.uk')
  ActionMailer::Base.delivery_method = :smtp
    # SMTP settings for gmail
    ActionMailer::Base.smtp_settings = {
      :address              => "smtp.gmail.com",
      :port                 => 587,
      :user_name            => ENV['gmail_username'],
      :password             => ENV['gmail_password'],
      :authentication       => "plain",
      :enable_starttls_auto => true
    }
    ActionMailer::Base.register_interceptor(DevelopmentMailInterceptor)
else
  ActionMailer::Base.delivery_method = :sendmail
  ActionMailer::Base.perform_deliveries = true
  ActionMailer::Base.raise_delivery_errors = true
end
ActionMailer::Base.default_url_options[:host] = Rails.application.config.website

