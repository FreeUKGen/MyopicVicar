module MessagesHelper
  def attachment(message)
    if message.attachment.present? || message.images.present?
      attachment = "Yes"
    else
      attachment = "No"
    end
    attachment
  end
  def sent(message)
    if message.sent_messages.deliveries.count != 0 #present? && message.message_sent_time.present?
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
  def recipients_list
    if @syndicate
      options_for_select(["Members of Syndicate"])
    else
      options_for_select(@options,@sent_message.recipients)
    end
  end

  def message_subject
    case
    when !@respond_to_message.nil?
      text_field_tag 'message[subject]', "Re: #{@respond_to_message.subject}", :class => "text-input", readonly: true
    when @message.subject.nil? && @respond_to_message.nil?
      text_field_tag 'message[subject]', nil, :class => "text-input", placeholder: "Mandatory", required: true
    when @message.subject.present? && @respond_to_message.nil?
      text_field_tag 'message[subject]', "#{@message.subject}", :class => "text-input"
    end
  end

  def reply_messages_count(source_message)
    Message.where(source_message_id: source_message.id).all.count
  end

  def message_attachment_tag(message)
    if message.attachment.present?
      content_tag :td, :class => "weight--semibold" do
        File.open("#{Rails.root}/public#{message.attachment_url}")
      end
    else
      content_tag(:td, "No text document attached.", :class => "weight--semibold")
    end
  end

  def message_image_tag(message)
    if message.images.present?
      content_tag :td, :class => "weight--semibold" do
        image_tag message.images_url
      end
    else
      content_tag :td, 'No images attached', :class => "weight--semibold"
    end
  end
end
