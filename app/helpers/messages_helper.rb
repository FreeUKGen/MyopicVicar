module MessagesHelper
  def attachment(message)
    if message.attachment.present?
      attachment = "Yes"
    else
      attachment = "No"
    end
    attachment
  end
  def sent(message)
    if message.sent_messages.present?
      sent_messages = "Yes"
    else
      sent_messages = "No"
    end
    sent_messages
  end
  def active_field(message)
    if message.active
      response = "Active"
    else
      response = "Inactive"
    end
    response
  end
  def formatted_date(message)
    if message.sent_time.blank?
      response = ""
    else
      response = message.sent_time.strftime("Sent at %H:%M on %e %b %Y")
    end
    response
  end
  def reason(list)
    if list.blank?
      response = ""
    else
      response = Array.new
      list.each do |l|
        response << l
      end
    end
    response
  end
end
