class Message
  include Mongoid::Document
  include Mongoid::Timestamps
  field :subject, type: String
  field :body, type: String
  field :message_time, type: DateTime
  field :userid, type: String
  field :attachment, type: String 
  field :identifier, type: String
  field :path, type: String
  field :file_name, type: String
  field :images, type: String 
  attr_accessor :action

  embeds_many :sent_messages
  accepts_nested_attributes_for :sent_messages,allow_destroy: true,
    reject_if: :all_blank

  mount_uploader :attachment, AttachmentUploader
  mount_uploader :images, ScreenshotUploader
  before_create :add_identifier

  class << self
    def id(id)
      where(:id => id)
    end
  end

  def add_identifier
    self.identifier = Time.now.to_i - Time.gm(2015).to_i
  end

  def communicate(recipients,active)
    ccs = Array.new
    recipients.each do |recip|
      p recip
      UseridDetail.role(recip).active(active).all.each do |person|
      ccs << person.email_address
      end
    end
    ccs = ccs.uniq
    UserMailer.send_message(self,ccs).deliver
  end
end
