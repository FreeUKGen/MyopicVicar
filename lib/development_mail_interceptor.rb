class DevelopmentMailInterceptor
  def self.delivering_email(message)
    message.subject = "#{message.to} #{message.subject}"
    message.to = "vinodhini.subbu@freeukgenealogy.org.uk"
  end
end

