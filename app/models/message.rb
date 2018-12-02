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
  field :recipients, type: Array.new, default: nil
  field :archived, type: Boolean, default: false
  field :keep, type: Boolean, default: false
  field :syndicate, type: String
  attr_accessor :action, :inactive_reasons,:active
  embeds_many :sent_messages
  accepts_nested_attributes_for :sent_messages,allow_destroy: true,
    reject_if: :all_blank

  scope :fetch_replies, -> (id) { where(source_message_id: id) }
  scope :fetch_feedback_replies, -> (id) { where(source_feedback_id: id) }
  scope :non_feedback_contact_reply_messages, -> { where(source_feedback_id: nil, source_contact_id: nil) }
  scope :non_reply_messages, -> { where(source_feedback_id: nil, source_contact_id: nil, source_message_id: nil) }
  scope :feedback_replies, -> { where({ :source_feedback_id.ne => nil })}
  scope :contact_replies, -> { where({ :source_contact_id.ne => nil })}
  mount_uploader :attachment, AttachmentUploader
  mount_uploader :images, ScreenshotUploader
  before_create :add_identifier


  index({_id: 1, userid: 1},{name: 'id_userid'})
  index({_id: 1, sent_time: 1},{name: 'id_sent_time'})
  index({_id: 1, identifier: 1},{name: 'id_indentifier'})
  index({_id: 1, message_time: 1},{name: 'id_message_time'})

  class << self

    def archived(archived)
      where(:archived => archived)
    end

    def can_be_destroyed?(message)
      message.source_message_id.present? || Message.fetch_replies(message.id).count == 0 || message.keep.blank?
    end

    def id(id)
      where(:id => id)
    end

    def keep(status)
      where(keep: status)
    end

    def not_message_reply(status)
      if status
        where(source_message_id: nil)
      else
        where(:source_message_id.ne => nil)
      end
    end

    def syndicate(syndicate)
      where(:syndicate => syndicate)
    end

    def message_replies(id)
      where(:source_message_id => id)
    end

    def userid(userid)
      where(:userid => userid)
    end
  end
  #....................................................................Instance Methods...............................
  def a_reply?
    result = false
    result = true if source_message_id.present? || source_feedback_id.present? || source_contact_id.present?
    result
  end

  def archive
    update_attribute(:archived, true)
    Message.message_replies(id).each do |message|
      message.update_attribute(:archived, true)
    end
  end

  def add_identifier
    self.identifier = Time.now.to_i - Time.gm(2015).to_i
  end

  def add_syndicate?
    original_message = Message.find(source_message_id)
    original_message.present? && original_message.syndicate.present? ? answer = true : answer = false
    answer
  end

  def communicate(recipients, active, reasons, sender, open_data_status, syndicate = nil)
    sending = UseridDetail.userid(sender).first
    sender_email = sending.create_friendly_from_email unless sending.blank?
    sender_email = 'FreeREG <freereg-contacts@freereg.org.uk>' if sender_email.blank?
    ccs = Array.new
    active_user = user_status(active)
    recipients.each do |recip|
      recipient_user = recipient_users(recip, syndicate)
      case
      when active_user
        get_active_users(recipient_user, open_data_status, active_user, ccs)
      when reasons.present? && !active_user
        get_inactive_users_with_reasons(recipient_user, open_data_status, active_user, reasons, ccs)
      when reasons.blank? && !active_user
        get_inactive_users_without_reasons(recipient_user, open_data_status, active_user, ccs)
      end
    end
    ccs << sender_email unless sender_email == 'FreeREG <freereg-contacts@freereg.org.uk>'
    ccs = ccs.uniq
    UserMailer.send_message(self, ccs, sender_email, sending).deliver_now
  end

  def communicate_message_reply(original_message)
    sender_userid = userid
    to_userid = original_message.userid
    copy_to = syndicate_coordinator if syndicate.present?
    UserMailer.message_reply(self, to_userid, copy_to, original_message, sender_userid).deliver_now
    add_message_to_userid_messages(UseridDetail.look_up_id(to_userid)) unless to_userid.blank?
    add_message_to_userid_messages(UseridDetail.look_up_id(copy_to)) unless copy_to.blank?
    recipients = Array.new
    recipients << to_userid
    recipients << copy_to unless copy_to.present? && copy_to == to_userid
    copies = Array.new
    reply_sent_messages(self, sender_userid, recipients, copies)
  end

  def is_archived?
    archived
  end

  def original_message_id
    original_message = Message.id(source_message_id).first if source_message_id.present?
    original_message = original_message.id if original_message.present?
    original_message
  end

  def reciever_notice(params)
    active_user = user_status(params[:active])
    if active_user
      return "Message sent to Recipients: #{params[:recipients]}; Open Data Status: #{open_data_status_value(params[:open_data_status])}; Active : #{active_user} "
    else
      return "Message sent to Recipients: #{params[:recipients]}; Open Data Status: #{open_data_status_value(params[:open_data_status])}; Active : #{active_user} #{params[:inactive_reasons]}"
    end
  end

  def restore
    update_attribute(:archived, false)
    Message.message_replies(id).each do |message|
      message.update_attribute(:archived, false)
    end
  end

  def syndicate_coordinator
    synd = Syndicate.syndicate_code(syndicate).first
    coordinator = synd.syndicate_coordinator if syndicate.present?
    coordinator
  end

  def update_keep
    p 'we are updating keep'
    p self
    self.update_attributes(:archived => true, :keep => true)
    p self
    Message.message_replies(id).each do |message|
      message.update_attributes(:archived => true, :keep => true)
    end
  end

  def update_unkeep
    update_attributes(archived: true, keep: false)
    Message.message_replies(id).each do |message|
      message.update_attributes(archived: true, keep: false)
    end
  end

  private

  class << self

    def formatted_time(message)
      if message.message_sent_time.blank?
        message.message_time.to_formatted_s(:long)
      else
        message.message_sent_time.to_formatted_s(:long) unless message.message_sent_time.blank?
      end
    end

    def list_messages(action, syndicate, archived, order)
      case action
      when 'list_unsent_messages'
        @messages = Message.non_feedback_contact_reply_messages.all.find_all do |message|
          !Message.sent?(message)
        end
      when 'list_feedback_reply_message'
        @messages = Message.feedback_replies.archived(archived).order_by(order)
      when 'list_contact_reply_message'
        @messages = Message.contact_replies.archived(archived).order_by(order)
      when 'list_syndicate_messages' || 'list_archived_syndicate_messages'
        @messages = Message.non_feedback_contact_reply_messages.syndicate(syndicate).archived(archived).not_message_reply(true).all.order_by(order)
      else
        @messages = Message.non_feedback_contact_reply_messages.archived(archived).not_message_reply(true).all.order_by(order)
      end
      @messages
    end

    def sent_messages(messages)
      messages.order(message_sent_time: :asc).find_all do |message|
        Message.sent?(message)
      end
    end

    def sent?(message)
      message.sent_messages.deliveries.count != 0
    end
  end

  #..............................................................Instance Methods

  def add_message_to_userid_messages(person)
    return if person.blank?

    @message_userid = person.userid_messages
    if !@message_userid.include? id.to_s
      @message_userid << id.to_s
      person.update_attribute(:userid_messages, @message_userid)
    end
  end

  def get_active_users(recipient_user, open_data_status, active_user, ccs)
    recipient_user.new_transcription_agreement(open_data_status_value(open_data_status)).active(active_user).email_address_valid.each do |person|
      add_message_to_userid_messages(person)
      ccs << person.create_friendly_from_email
    end
  end

  def get_inactive_users_with_reasons(recipient_user, open_data_status, active_user, reasons, ccs)
    reasons.each do |reason|
      recipient_user.new_transcription_agreement(open_data_status_value(open_data_status)).active(active_user).reason(reason).email_address_valid.each do |person|
        add_message_to_userid_messages(person)
        ccs << person.create_friendly_from_email
      end
    end
  end

  def get_inactive_users_without_reasons(recipient_user, open_data_status, active_user, ccs)
    recipient_user.new_transcription_agreement(open_data_status_value(open_data_status)).active(active_user).reason('temporary').email_address_valid.each do |person|
      add_message_to_userid_messages(person)
      ccs << person.create_friendly_from_email
    end
  end

  def open_data_status_value(status)
    status.join('') unless status.nil?
    status
  end

  def recipient_users(recipients, syndicate = nil)
    if recipients == 'Members of Syndicate'
      users = UseridDetail.syndicate(syndicate).all
    else
      users = UseridDetail.role(recipients).all
    end
    users
  end

  def reply_sent_messages(message, sender_userid, contact_recipients, other_recipients)
    @message = message
    contact_recipients = contact_recipients.reject(&:blank?)
    @sent_message = SentMessage.new(message_id: @message.id, sender: sender_userid, recipients: contact_recipients, other_recipients: other_recipients, sent_time: Time.now)
    @message.sent_messages << [@sent_message]
    @sent_message.save
  end

  def user_status(status)
    status == 'true'
  end
end
