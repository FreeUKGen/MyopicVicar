if ENV['gmail_username'].present? && Rails.env.development? && Rails.application.config.mongodb_bin_location == 'd:/mongodb/bin/'
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
if Rails.env.development?
    ActionMailer::Base.default_url_options[:host] = "http://test2.freereg.org.uk"
    ActionMailer::Base.register_interceptor(DevelopmentMailInterceptor)
end
if Rails.env.production?
    ActionMailer::Base.default_url_options[:host] = "http://freereg2.freereg.org.uk"
end