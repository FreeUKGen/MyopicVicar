class Contact
  include Mongoid::Document
  include Mongoid::Timestamps
  field :body, type: String
  field :contact_time, type: DateTime
  field :name, type: String
  field :email_address, type: String
  field :county, type: String
  alias_attribute :chapman_code, :county
  field :session_id, type: String
  field :problem_page_url, type: String
  field :previous_page_url, type: String
  field :contact_type, type: String
  field :github_issue_url, type: String
  field :github_comment_url, type: String
  field :github_number, type: String
  field :session_data, type: Hash
  field :screenshot, type: String
  field :record_id, type: String
  field :entry_id, type: String
  field :line_id, type: String
  field :contact_name, type: String, default: nil  # this field is used as a span trap
  field :query, type: String
  field :selected_county, type: String # user-selected county to contact in FC2
  field :fc_individual_id, type: String
  field :identifier, type: String
  field :screenshot_location, type: String
  field :census_year, type: String
  field :data_county, type: String
  field :place, type: String
  field :civil_parish, type: String
  field :piece, type: String
  field :enumeration_district, type: String
  field :folio, type: String
  field :page, type: String
  field :house_number, type: String
  field :house_or_street_name, type: String

  field :contact_action_sent_to_userid, type: String, default: nil
  field :copies_of_contact_action_sent_to_userids, type: Array, default: []
  field :archived, type: Boolean, default: false
  field :keep, type: Boolean, default: false

  attr_accessor :action

  validates_presence_of :name, :email_address, :body
  validates :email_address, format: { :with => /\A[^@][\w\+.-]+@[\w.-]+[.][a-z]{2,4}\z/i }

  mount_uploader :screenshot, ScreenshotUploader

  before_create :url_check, :add_identifier, :add_screenshot_location

  before_destroy :delete_replies

  class << self
    def id(id)
      where(id: id)
    end

    def archived(value)
      where(archived: value)
    end

    def chapman_code(value)
      where(chapman_code: value)
    end


    def github_enabled
      Rails.application.config.github_issues_password.present?
    end

    def keep(status)
      where(keep: status)
    end

    def message_replies(id)
      where(source_contact_id: id)
    end

    def results(archived, order, user)
      counties = user.county_groups
      contacts = Contact.where(archived: archived)
      if user.secondary_role.include?'volunteer_coordinator'
        contacts = contacts.where(contact_type: "Volunteering Question").order_by(order)
      elsif %w[county_coordinator country_coordinator].include?(user.person_role)
        contacts = contacts.where(county: { '$in' => counties }).order_by(order)
      else
        contacts = Contact.where(archived: archived).order_by(order)
      end
      contacts
    end

    def type(status)
      where(contact_type: status)
    end
  end

  ##########################################################################################

  def a_reply?
    source_message_id.present? || source_feedback_id.present? || source_contact_id.present? ? answer = true : answer = false
    answer
  end

  def acknowledge_communication
    UserMailer.acknowledge_communication(self).deliver_now
  end

  def action_recipient_userid
    coordinator = nil
    if contact_type == 'Data Problem'
      coordinator = obtain_coordinator if record_id.present?
    else
      coordinator = UseridDetail.role(self.role_from_contact).active(true).first
      coordinator = UseridDetail.secondary(self.role_from_contact).active(true).first if coordinator.blank?
      coordinator = coordinator.userid unless coordinator.blank?
    end
    coordinator = obtain_manager if coordinator.blank?
    update_attribute(:contact_action_sent_to_userid, coordinator)
    coordinator
  end

  def action_recipient_copies_userids(action_person)
    action_recipient_copies_userids = []
    role = role_from_contact
    UseridDetail.role(role).active(true).all.each do |person|
      action_recipient_copies_userids.push(person.userid) unless person.userid == action_person
    end
    UseridDetail.secondary(role).active(true).all.each do |person|
      action_recipient_copies_userids.push(person.userid) unless person.userid == action_person
    end
    action_recipient_copies_userids = action_recipient_copies_userids.uniq
    update_attribute(:copies_of_contact_action_sent_to_userids, action_recipient_copies_userids)
    action_recipient_copies_userids
  end

  def add_contact_coordinator_to_copies_of_contact_action_sent_to_userids
    action_person = UseridDetail.role('contacts_coordinator').active(true).first
    action_person = UseridDetail.secondary('contacts_coordinator').active(true).first if action_person.blank?
    if action_person.present? && (action_person.userid != contact_action_sent_to_userid)
      if copies_of_contact_action_sent_to_userids.blank?
        copies_of_contact_action_sent_to_userids.push(action_person.userid)
      else
        copies_of_contact_action_sent_to_userids.push(action_person.userid) unless copies_of_contact_action_sent_to_userids.include?(action_person.userid)
      end
      update_attribute(:copies_of_contact_action_sent_to_userids, copies_of_contact_action_sent_to_userids)
    end
    copies_of_contact_action_sent_to_userids
  end

  def add_identifier
    self.identifier = Time.now.to_i - Time.gm(2015).to_i
  end

  def add_link_to_attachment
    return if self.screenshot_location.blank?

    website = Rails.application.config.website
    website = website.sub('www','www13') if website == 'https://www.freereg.org.uk'
    go_to = "#{website}/#{self.screenshot_location}"
    body = self.body + "\n" + go_to
    self.update_attribute(:body, body)
  end

  def add_screenshot_location
    self.screenshot_location = "uploads/contact/screenshot/#{self.screenshot.model._id.to_s}/#{self.screenshot.filename}" if self.screenshot.filename.present?
  end

  def add_message_to_userid_messages_for_contact(message)
    copies_of_contact_action_sent_to_userids.each do |userid|
      message.add_message_to_userid_messages(UseridDetail.look_up_id(userid))
    end
  end


  def add_sender_to_copies_of_contact_action_sent_to_userids(sender_userid)
    copies_of_contact_action_sent_to_userids = self.copies_of_contact_action_sent_to_userids
    copies_of_contact_action_sent_to_userids.push(sender_userid) unless copies_of_contact_action_sent_to_userids.include?(sender_userid)
    self.update_attribute(:copies_of_contact_action_sent_to_userids, copies_of_contact_action_sent_to_userids)
    copies_of_contact_action_sent_to_userids
  end

  def archive
    update_attribute(:archived, true)
    Contact.message_replies(id).each do |message_rl1|
      message_rl1.update_attribute(:archived, true)
      Contact.message_replies(message_rl1.id).each do |message_rl2|
        message_rl2.update_attribute(:archived, true)
        Contact.message_replies(message_rl2.id).each do |message_rl3|
          message_rl3.update_attribute(:archived, true)
          Contact.message_replies(message_rl3.id).each do |message_rl4|
            message_rl4.update_attribute(:archived, true)
            Contact.message_replies(message_rl4.id).each do |message_rl5|
              message_rl5.update_attribute(:archived, true)
              Contact.message_replies(message_rl5.id).each do |message_rl6|
                message_rl6.update_attribute(:archived, true)
                Contact.message_replies(message_rl6.id).each do |message_rl7|
                  message_rl7.update_attribute(:archived, true)
                  Contact.message_replies(message_rl7.id).each do |message_rl8|
                    message_rl8.update_attribute(:archived, true)
                    Contact.message_replies(message_rl8.id).each do |message_rl9|
                      message_rl9.update_attribute(:archived, true)
                      Contact.message_replies(message_rl9.id).each do |message_rl10|
                        message_rl10.update_attribute(:archived, true)
                        Contact.message_replies(message_rl10.id).each do |message_rl11|
                          message_rl11.update_attribute(:archived, true)
                          Contact.message_replies(message_rl11.id).each do |message_rl12|
                            message_rl12.update_attribute(:archived, true)
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  def archived?
    archived.present?
  end

  def being_kept?
    self.keep.present? ? answer = true : answer = false
    answer
  end
  def communicate_contact_reply(message, sender_userid)
    copies = self.copies_of_contact_action_sent_to_userids
    recipients = []
    recipients.push(self.email_address)
    UserMailer.coordinator_contact_reply(self, copies, message, sender_userid).deliver_now
    copies = self.add_sender_to_copies_of_contact_action_sent_to_userids(sender_userid)
    reply_sent_messages(message, sender_userid, recipients, copies)
  end

  def communicate_initial_contact
    self.acknowledge_communication
    self.contact_action_communication
  end

  def contact_action_communication
    send_to_userid = action_recipient_userid
    copies_of_contact_action_sent_to_userids = action_recipient_copies_userids(send_to_userid)
    copies_of_contact_action_sent_to_userids = add_contact_coordinator_to_copies_of_contact_action_sent_to_userids
    UserMailer.contact_action_request(self, send_to_userid, copies_of_contact_action_sent_to_userids).deliver_now
    #copies = self.add_sender_to_copies_of_contact_action_sent_to_userids(send_to_userid)
  end

  def delete_replies
    replies = Message.where(source_contact_id: id).all
    return if replies.blank?

    replies.each do |reply|
      reply.destroy
    end

  end

  def github_issue
    appname = MyopicVicar::Application.config.freexxx_display_name.upcase
    if Contact.github_enabled
      self.add_link_to_attachment
      Octokit.configure do |c|
        c.access_token = Rails.application.config.github_issues_access_token
      end
      self.screenshot = nil
      response = Octokit.create_issue(Rails.application.config.github_issues_repo, issue_title, issue_body, :labels => [])
      logger.info("#{appname}:GITHUB response: #{response}")
      logger.info(response.inspect)
      self.update_attributes(:github_issue_url => response[:html_url],:github_comment_url => response[:comments_url], :github_number => response[:number])
    else
      logger.error("#{appname}:Tried to create an issue, but Github integration is not enabled!")
    end
  end

  def has_replies?(contact_id)
    Message.where(source_contact_id: contact_id).exists?
  end

  def is_archived?
    archived.present?
  end

  def issue_title
    "#{identifier} #{contact_type} (#{name})"
  end

  def issue_body
    issue_body = ApplicationController.new.render_to_string(:partial => 'contacts/github_issue_body.txt', :locals => {:feedback => self})
    issue_body
  end

  def not_a_reply?
    source_contact_id.present?  ? answer = false : answer = true
    answer
  end

  def not_being_kept?
    self.keep.blank? ? answer = true : answer = false
    answer
  end

  def restore
    update_attribute(:archived, false)
    Contact.message_replies(id).each do |message_rl1|
      message_rl1.update_attribute(:archived, false)
      Contact.message_replies(message_rl1.id).each do |message_rl2|
        message_rl2.update_attribute(:archived, false)
        Contact.message_replies(message_rl2.id).each do |message_rl3|
          message_rl3.update_attribute(:archived, false)
          Contact.message_replies(message_rl3.id).each do |message_rl4|
            message_rl4.update_attribute(:archived, false)
            Contact.message_replies(message_rl4.id).each do |message_rl5|
              message_rl5.update_attribute(:archived, false)
              Contact.message_replies(message_rl5.id).each do |message_rl6|
                message_rl6.update_attribute(:archived, false)
                Contact.message_replies(message_rl6.id).each do |message_rl7|
                  message_rl7.update_attribute(:archived, false)
                  Contact.message_replies(message_rl7.id).each do |message_rl8|
                    message_rl8.update_attribute(:archived, false)
                    Contact.message_replies(message_rl8.id).each do |message_rl9|
                      message_rl9.update_attribute(:archived, false)
                      Contact.message_replies(message_rl9.id).each do |message_rl10|
                        message_rl10.update_attribute(:archived, false)
                        Contact.message_replies(message_rl10.id).each do |message_rl11|
                          message_rl11.update_attribute(:archived, false)
                          Contact.message_replies(message_rl11.id).each do |message_rl12|
                            message_rl12.update_attribute(:archived, false)
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  def sent?
    sent_messages.deliveries.count != 0
  end

  def obtain_coordinator
    coordinator = nil
    if MyopicVicar::Application.config.template_set.downcase == 'freebmd'
      coordinator = UseridDetail.role('data_manager').active(true).first
      coordinator = UseridDetail.secondary('data_manager').active(true).first if coordinator.blank?
      coordinator = UseridDetail.role('system_administrator').active(true).first if coordinator.blank?
      coordinator = coordinator.userid
    else
      search_record = SearchRecord.record_id(self.record_id).first
      if search_record.present?
        county = County.where(chapman_code: search_record.chapman_code).first
        coordinator = county.county_coordinator if county.present?
      end
    end
    coordinator
  end

  # used by freecen if user selects to contact coordinator for a specific county
  #cannot see its call
  def obtain_coordinator_for_selected_county
    return nil if MyopicVicar::Application.config.template_set != 'freecen'

    return nil if self.selected_county.blank?

    c = County.where(chapman_code: self.selected_county).first

    return nil if c.nil

    cc_userid = c.county_coordinator
    coord = UseridDetail.where(userid: cc_userid).first unless cc_userid.nil?
    coord
  end

  def obtain_manager
    manager = nil
    action_person = UseridDetail.role('contacts_coordinator').active(true).first
    action_person = UseridDetail.secondary('contacts_coordinator').active(true).first if action_person.blank?
    action_person = UseridDetail.userid('REGManager').active(true).first if action_person.blank?
    action_person = UseridDetail.role('system_administrator').active(true).first if action_person.blank?
    manager = action_person.userid if action_person.present?
    manager
  end

  def role_from_contact
    case contact_type
    when 'Website Problem'
      role = 'website_coordinator'
    when 'Data Question'
      role = 'contacts_coordinator'
    when 'Volunteering Question'
      role = 'volunteer_coordinator'
    when 'General Comment'
      role = 'general_communication_coordinator'
    when 'Thank you'
      role = 'publicity_coordinator'
    when 'Genealogical Question'
      role = 'genealogy_coordinator'
    when 'Enhancement Suggestion'
      role = 'project_manager'
    else
      role = 'general_communication_coordinator'
    end
    role
  end

  def update_keep
    update_attributes(archived: true, keep: true)
    Contact.message_replies(id).each do |message_rl1|
      message_rl1.update_attributes(archived: true, keep: true)
      Contact.message_replies(message_rl1.id).each do |message_rl2|
        message_rl2.update_attributes(archived: true, keep: true)
        Contact.message_replies(message_rl2.id).each do |message_rl3|
          message_rl3.update_attributes(archived: true, keep: true)
          Contact.message_replies(message_rl3.id).each do |message_rl4|
            message_rl4.update_attributes(archived: true, keep: true)
            Contact.message_replies(message_rl4.id).each do |message_rl5|
              message_rl5.update_attributes(archived: true, keep: true)
              Contact.message_replies(message_rl5.id).each do |message_rl6|
                message_rl6.update_attributes(archived: true, keep: true)
                Contact.message_replies(message_rl6.id).each do |message_rl7|
                  message_rl7.update_attributes(archived: true, keep: true)
                  Contact.message_replies(message_rl7.id).each do |message_rl8|
                    message_rl8.update_attributes(archived: true, keep: true)
                    Contact.message_replies(message_rl8.id).each do |message_rl9|
                      message_rl9.update_attributes(archived: true, keep: true)
                      Contact.message_replies(message_rl9.id).each do |message_rl10|
                        message_rl10.update_attributes(archived: true, keep: true)
                        Contact.message_replies(message_rl10.id).each do |message_rl11|
                          message_rl11.update_attributes(archived: true, keep: true)
                          Contact.message_replies(message_rl11.id).each do |message_rl12|
                            message_rl12.update_attributes(archived: true, keep: true)
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  def update_unkeep
    update_attributes(archived: true, keep: false)
    Contact.message_replies(id).each do |message_rl1|
      message_rl1.update_attributes(archived: true, keep: false)
      Contact.message_replies(message_rl1.id).each do |message_rl2|
        message_rl2.update_attributes(archived: true, keep: false)
        Contact.message_replies(message_rl2.id).each do |message_rl3|
          message_rl3.update_attributes(archived: true, keep: false)
          Contact.message_replies(message_rl3.id).each do |message_rl4|
            message_rl4.update_attributes(archived: true, keep: false)
            Contact.message_replies(message_rl4.id).each do |message_rl5|
              message_rl5.update_attributes(archived: true, keep: false)
              Contact.message_replies(message_rl5.id).each do |message_rl6|
                message_rl6.update_attributes(archived: true, keep: false)
                Contact.message_replies(message_rl6.id).each do |message_rl7|
                  message_rl7.update_attributes(archived: true, keep: false)
                  Contact.message_replies(message_rl7.id).each do |message_rl8|
                    message_rl8.update_attributes(archived: true, keep: false)
                    Contact.message_replies(message_rl8.id).each do |message_rl9|
                      message_rl9.update_attributes(archived: true, keep: false)
                      Contact.message_replies(message_rl9.id).each do |message_rl10|
                        message_rl10.update_attributes(archived: true, keep: false)
                        Contact.message_replies(message_rl10.id).each do |message_rl11|
                          message_rl11.update_attributes(archived: true, keep: false)
                          Contact.message_replies(message_rl11.id).each do |message_rl12|
                            message_rl12.update_attributes(archived: true, keep: false)
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  def url_check
    self.problem_page_url = 'unknown' if self.problem_page_url.nil?
    self.previous_page_url = 'unknown' if self.previous_page_url.nil?
  end

  private

  def reply_sent_messages(message, sender_userid, contact_recipients, other_recipients)
    @message = message
    @sent_message = SentMessage.new(message_id: @message.id, sender: sender_userid, recipients: contact_recipients, other_recipients: other_recipients, sent_time: Time.now)
    @message.sent_messages << [@sent_message]
    @sent_message.save
  end
end
