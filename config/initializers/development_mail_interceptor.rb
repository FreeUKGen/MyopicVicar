class DevelopmentMailInterceptor

  def self.delivering_email(message)
    if Rails.env.production?
      message.subject = "Trapped email #{message.to} #{message.subject}"
      message.to = "freereg.edickens@gmail.com"
    end
    if Rails.env.development?
      message.subject = "Trapped email #{message.to} #{message.subject}"
      message.to = "kirk.dawson.bc@gmail.com"
    end
  end
end
