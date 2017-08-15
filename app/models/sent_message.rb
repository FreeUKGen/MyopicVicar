class SentMessage
  include Mongoid::Document
  field :sent_time, type: DateTime
  field :recipients, type: Array
  field :active, type: Boolean, default: true
  field :message_id, type: String
  field :sender, type: String
  field :inactive_reason, type: Array
  field :open_data_status, type: String
  embedded_in :message

  ALL_STATUS_MESSAGES = ["All","Unknown","Accepted","Declined","Requested"]
  ACTUAL_STATUS_MESSAGES = ["Unknown","Accepted","Declined","Requested"]


  class << self
    def id(id)
      where(:id => id)
    end
  end
end
