ActionMailer::Base.delivery_method = :sendmail
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.raise_delivery_errors = true
if Rails.env.development?
ActionMailer::Base.default_url_options[:host] = "http://test2.freereg.org.uk"
ActionMailer::Base.register_interceptor(DevelopmentMailInterceptor) 
end
if Rails.env.production?
  ActionMailer::Base.default_url_options[:host] = "http://freereg2.freereg.org.uk"
  ActionMailer::Base.register_interceptor(DevelopmentMailInterceptor) 
end