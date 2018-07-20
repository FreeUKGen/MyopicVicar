module EmailHelper
  def email_attachment_tag(message)
    if message.attachment.present?
      @file_name = File.basename(message.attachment.path)
      attachments[@file_name] = File.read("#{Rails.root}/public#{message.attachment_url}")
      image_tag attachments[@file_name].url
    end
    if message.images.present?
      @image = File.basename(message.images.path)
      attachments[@image] = File.binread("#{Rails.root}/public#{message.images_url}")
      image_tag attachments[@image].url
    end 
  end
end
