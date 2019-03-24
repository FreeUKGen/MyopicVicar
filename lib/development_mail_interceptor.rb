class DevelopmentMailInterceptor
  def self.delivering_email(message)
    message.subject = "Trapped FreeCen2 message #{message.to} #{message.subject}"
    message.to = 'kirk.dawson@freeukgenealogy.org.uk'
  end
end
