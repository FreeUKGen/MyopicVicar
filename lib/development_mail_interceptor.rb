class DevelopmentMailInterceptor
  def self.delivering_email(message)
    message.subject = "Trapped message #{message.to} #{message.subject}"
    message.to = ENV['dev_mail_recipient'].presence || 'dev-mail-trap@example.invalid'
  end
end
