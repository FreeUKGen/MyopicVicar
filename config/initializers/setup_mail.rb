ActionMailer::Base.delivery_method = :sendmail
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.raise_delivery_errors = true
ActionMailer::Base.default_charset = "utf-8"
ActionMailer::Base.default_url_options[:host] = "http://xanthus.freereg2.zomo.co.uk"
ActionMailer::Base.register_interceptor(DevelopmentMailInterceptor) if Rails.env.development?