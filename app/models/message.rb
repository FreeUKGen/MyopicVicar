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
  attr_accessor :action, :inactive_reasons,:active
  embeds_many :sent_messages
  accepts_nested_attributes_for :sent_messages,allow_destroy: true,
    reject_if: :all_blank

  mount_uploader :attachment, AttachmentUploader
  mount_uploader :images, ScreenshotUploader
  before_create :add_identifier
  
  index({_id: 1, userid: 1},{name: "id_userid"})
  index({_id: 1, sent_time: 1},{name: "id_sent_time"})
  index({_id: 1, identifier: 1},{name: "id_indentifier"})
  index({_id: 1, message_time: 1},{name: "id_message_time"})
  
  class << self
    def id(id)
      where(:id => id)
    end
  end

  def add_identifier
    self.identifier = Time.now.to_i - Time.gm(2015).to_i
  end

  def communicate(recipients,active,reasons,sender)
    appname = MyopicVicar::Application.config.freexxx_display_name
    sender_email = UseridDetail.userid(sender).first.email_address unless sender.blank?
    sender_email = "#{appname.downcase}-contacts@#{appname.downcase}.org.uk" if sender_email.blank?
    ccs = Array.new
    recipients.each do |recip|
      case
      when active
        UseridDetail.role(recip).active(active).email_address_valid.all.each do |person|
          add_message_to_userid_messages(person)
          ccs << person.email_address
        end
      when reasons.present? && !active
        reasons.each do |reason|
          UseridDetail.role(recip).active(active).reason(reason).email_address_valid.all.each do |person|
            add_message_to_userid_messages(person)
            ccs << person.email_address
          end
        end
      when reasons.blank? && !active
        reasons.each do |reason|
          UseridDetail.role(recip).active(active).reason("temporary").email_address_valid.all.each do |person|
            add_message_to_userid_messages(person)
            ccs << person.email_address
          end
        end
      end
    end
    ccs = ccs.uniq
    UserMailer.send_message(self,ccs,sender_email).deliver_now
  end

  private
  def add_message_to_userid_messages(person)
    @message_userid =  person.userid_messages
    if !@message_userid.include? self.id.to_s
        @message_userid << self.id.to_s
        person.update_attribute(:userid_messages, @message_userid)
    end
  end

end
