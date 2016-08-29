class SentMessage
  include Mongoid::Document
  field :sent_time, type: DateTime
  field :recipients, type: Array
  field :active, type: Boolean
  field :message_id, type: String
  embedded_in :message
  class << self
    def id(id)
      where(:id => id)
    end
  end
end
