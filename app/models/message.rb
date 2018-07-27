class Message
  include Mongoid::Document
  include Mongoid::Timestamps
  field :subject, type: String
  field :source_message_id, type: String
  field :source_feedback_id, type: String
  field :source_contact_id, type: String
  field :body, type: String
  field :message_time, type: DateTime
  field :message_sent_time, type: DateTime
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

  scope :fetch_replies, -> (id) { where(source_message_id: id) }
  scope :fetch_feedback_replies, -> (id) { where(source_feedback_id: id) }
  scope :non_feedback_contact_reply_messages, -> { where(source_feedback_id: nil, source_contact_id: nil) }
  scope :feedback_replies, -> { where({ :source_feedback_id.ne => nil })}
  scope :contact_replies, -> { where({ :source_contact_id.ne => nil })}
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

  def communicate(recipients,active,reasons,sender, open_data_status, syndicate=nil)
    sender_email = UseridDetail.userid(sender).first.email_address unless sender.blank?
    sender_email = "freereg-contacts@freereg.org.uk" if sender_email.blank?
    ccs = Array.new
    active_user = user_status(active)
    recipients.each do |recip|
      recipient_user = recipient_users(recip, syndicate)
      case
      when active_user
        recipient_user.new_transcription_agreement(open_data_status_value(open_data_status)).active(active_user).email_address_valid.all.each do |person|
          add_message_to_userid_messages(person)
          ccs << person.email_address
        end
      when reasons.present? && !active_user
        reasons.each do |reason|
          recipient_user.new_transcription_agreement(open_data_status_value(open_data_status)).active(active_user).reason(reason).email_address_valid.all.each do |person|
            add_message_to_userid_messages(person)
            ccs << person.email_address
          end
        end
      when reasons.blank? && !active_user
        reasons.each do |reason|
          recipient_user.new_transcription_agreement(open_data_status_value(open_data_status)).active(active_user).reason("temporary").email_address_valid.all.each do |person|
            add_message_to_userid_messages(person)
            ccs << person.email_address
          end
        end
      end
    end
    ccs = ccs.uniq
    UserMailer.send_message(self,ccs,sender_email).deliver_now
  end

  def reciever_notice params
    active_user = user_status(params[:active])
    if active_user
      return "Message sent to Recipients: #{params[:recipients]}; Open Data Status: #{open_data_status_value(params[:open_data_status])}; Active : #{active_user} "
    else
      return "Message sent to Recipients: #{params[:recipients]}; Open Data Status: #{open_data_status_value(params[:open_data_status])}; Active : #{active_user} #{reasons}"
    end
  end

  def self.can_be_destroyed?message
    message.source_message_id.present? || Message.fetch_replies(message.id).count == 0
  end

  private
  def add_message_to_userid_messages(person)
    @message_userid =  person.userid_messages
    if !@message_userid.include? self.id.to_s
        @message_userid << self.id.to_s
        person.update_attribute(:userid_messages, @message_userid)
    end
  end

  def open_data_status_value status
    status.join("") unless status.nil?
  end

  def user_status status
    status == "true"
  end

  def recipient_users(recipients, syndicate=nil)
    if recipients == "Members of Syndicate"
      users = UseridDetail.syndicate(syndicate)
    else
      users = UseridDetail.role(recipients)
    end
    users
  end

  def self.list_messages(action)
    case action
    when "list_by_name"
      @messages = Message.non_feedback_contact_reply_messages.all.order_by(userid: 1)
    when "list_by_date"
      @messages = Message.non_feedback_contact_reply_messages.all.order_by(message_time: 1)
    when "list_by_identifier"
      @messages = Message.non_feedback_contact_reply_messages.all.order_by(identifier: -1)
    when "list_unsent_messages"
      @messages = Message.non_feedback_contact_reply_messages.all.find_all do |message|
        !Message.sent?(message)
      end
    when "list_feedback_reply_message"
      @messages = Message.feedback_replies.order_by(message_time: -1)
    when "list_contact_reply_message"
      @messages = Message.contact_replies.order_by(message_time: -1)
    end
    return @messages
  end

  def self.formatted_time(message)
    unless message.message_sent_time.blank?
      message.message_sent_time.to_formatted_s(:long) unless message.message_sent_time.blank?
    else
      message.message_time.to_formatted_s(:long)
    end
  end

  def self.sent_messages(messages)
    messages.order(message_sent_time: :asc).find_all do |message|
      Message.sent?(message)
    end
  end

  def self.sent?(message)
    message.sent_messages.deliveries.count != 0
  end
end
