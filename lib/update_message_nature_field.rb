class UpdateMessageNatureField
  def self.process
    number = 0
    Message.each do |message|
      number = number + 1
      if message.nature.blank?
        if message.source_feedback_id.present?
          message.update_attribute(:nature, 'feedback')
        elsif message.source_contact_id.present?
          message.update_attribute(:nature, 'contact')
        elsif message.syndicate.present?
          message.update_attribute(:nature, 'syndicate')
        else
          message.update_attribute(:nature, 'general')
        end
      else
        message.update_attribute(:nature, 'communication') if message.nature == 'Communication'
      end
    end
    p " #{number} processed"
  end
end
