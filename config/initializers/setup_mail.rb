require 'development_mail_interceptor'
if Rails.env.development?
  ActionMailer::Base.register_interceptor(DevelopmentMailInterceptor)
  ActionMailer::Base.delivery_method = :sendmail if Rails.application.config.website == 'https://test2.freereg.org.uk'
  ActionMailer::Base.perform_deliveries = true
  ActionMailer::Base.raise_delivery_errors = true
  ActionMailer::Base.default_url_options[:host] = Rails.application.config.website
else
  ActionMailer::Base.delivery_method = :sendmail
  ActionMailer::Base.perform_deliveries = true
  ActionMailer::Base.raise_delivery_errors = true
  ActionMailer::Base.default_url_options[:host] = Rails.application.config.website
end
