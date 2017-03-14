class SentMessage
  include Mongoid::Document
  field :sent_time, type: DateTime
  field :recipients, type: Array
  field :active, type: Boolean, default: true
  field :message_id, type: String
  field :sender, type: String
  field :inactive_reason, type: Array
  embedded_in :message
  class << self
    def id(id)
      where(:id => id)
    end
  end
end
