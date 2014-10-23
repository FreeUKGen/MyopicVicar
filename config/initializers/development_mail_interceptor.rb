class DevelopmentMailInterceptor
  def self.delivering_email(message)
    message.subject = "Trapped email #{message.to} #{message.subject}"
    message.to = "kirk.dawson.bc@gmail.com"
   end
end

