ActionMailer::Base.delivery_method = :sendmail
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.raise_delivery_errors = true

ActionMailer::Base.default_url_options[:host] = "http://test2.freereg.org.uk"
ActionMailer::Base.register_interceptor(DevelopmentMailInterceptor) if Rails.env.development?