if Rails.env.development? 
  #use this if you wish to use gmail to send your mail in development
  # and set your password and username in the application.yml see the example
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
else
  ActionMailer::Base.delivery_method = :sendmail
  ActionMailer::Base.perform_deliveries = true
  ActionMailer::Base.raise_delivery_errors = true
end
ActionMailer::Base.default_url_options[:host] = Rails.application.config.website
if Rails.env.development?
  ActionMailer::Base.register_interceptor(DevelopmentMailInterceptor)
end
