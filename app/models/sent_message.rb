class SentMessage
  include Mongoid::Document
  field :sent_time, type: DateTime
  field :recipients, type: Array
  field :active, type: Boolean
  embedded_in :message
  class << self
    def id(id)
      where(:id => id)
    end
  end
end