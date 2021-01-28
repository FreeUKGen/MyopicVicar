class DevelopmentMailInterceptor
  def self.delivering_email(message)
    message.subject = "Trapped message #{message.to} #{message.subject}"
    message.to = 'anne.vandervord@live.co.uk'
  end
end
