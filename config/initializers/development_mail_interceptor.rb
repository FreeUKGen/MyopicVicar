class DevelopmentMailInterceptor

  def self.delivering_email(message)
      message.subject = "Trapped email #{message.to} #{message.subject}"
      message.to = "vinodhini.subbu@freeukgenealogy.org.uk"
  end
end
