class Contact
  include Mongoid::Document
  include Mongoid::Timestamps
  field :body, type: String
  field :contact_time, type: DateTime
  field :name, type: String
  field :email_address, type: String
  field :county, type: String
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
  field :identifier, type: String
  field :screenshot_location, type: String
  field :contact_action_sent_to, type: String, default: nil
  field :copies_of_contact_action_sent_to, type: Array, default: nil
  field :archived, type: Boolean, default: false

  attr_accessor :action

  validates_presence_of :name, :email_address
  validates :email_address,:format => {:with => /\A[^@][\w\+.-]+@[\w.-]+[.][a-z]{2,4}\z/i}

  mount_uploader :screenshot, ScreenshotUploader

  before_create :url_check, :add_identifier, :add_screenshot_location

  class << self
    def id(id)
      where(:id => id)
    end

    def archived
      where(:archived => true)
    end
    def github_enabled
      !Rails.application.config.github_issues_password.blank?
    end
  end

  ##########################################################################################

  def acknowledge_communication(message=nil,sender=nil)
    UserMailer.acknowledge_communication(self).deliver_now
  end

  def action_recipients
    copies = Array.new
    if self.contact_type == 'Data Problem'
      coordinator = self.get_coordinator if self.record_id.present?
      coordinator.present? ? action_person = coordinator : action_person = self.get_manager
    else
      role = self.get_role_from_contact
      person = UseridDetail.role(role).email_address_valid.first
      person.present? ? action_person = person : action_person = self.get_manager
    end
    UseridDetail.role("contacts_coordinator").email_address_valid.all.each do |user|
      copies.push(user) unless action_person.userid == user.userid
    end
    UseridDetail.secondary("contacts_coordinator").email_address_valid.each do |user|
      copies.push(user) unless action_person.userid == user.userid
    end
    p " to whom"
    p action_person
    p copies
    return action_person,copies
  end


  def add_identifier
    self.identifier = Time.now.to_i - Time.gm(2015).to_i
  end

  def add_link_to_attachment
    return if self.screenshot_location.blank?
    website = Rails.application.config.website
    website  = website.sub("www","www13") if website == "http://www.freereg.org.uk"
    go_to = "#{website}/#{self.screenshot_location}"
    body = self.body + "\n" + go_to
    self.update_attribute(:body,body)
  end

  def add_screenshot_location
    self.screenshot_location = "uploads/contact/screenshot/#{self.screenshot.model._id.to_s}/#{self.screenshot.filename}" if self.screenshot.filename.present?
  end

  def communicate(message=nil,sender=nil)
    p "communicating #{message} #{sender}"
    self.acknowledge_communication(message,sender) unless message.present?
    self.contact_action_communication(message,sender)
  end

  def contact_action_communication(message,sender)
    unless message.blank?
      self.add_sender_to_copies_of_contact_action_sent_to(sender)
      self.add_contact_coordinator_to_copies_of_contact_action_sent_to
      copies = self.get_copies
      reply_sent_messages(message,sender,self.name,self.copies_of_contact_action_sent_to)
      UserMailer.coordinator_contact_reply(self,copies,message,sender).deliver_now
    else
      send_to,copies_to = self.action_recipients
      UserMailer.contact_action_request(self,send_to,copies_to).deliver_now
    end
  end

  def get_coordinator
    search_record = SearchRecord.record_id(self.record_id).first
    if search_record.present?
      entry_id = search_record.freereg1_csv_entry
      entry = Freereg1CsvEntry.id(entry_id).first
      if entry.present?
        file_id = entry.freereg1_csv_file
        file = Freereg1CsvFile.id(file_id).first
        if file.present?
          chapman_code = file.county #this is chapman code
          county = County.where(:chapman_code => chapman_code).first
          if county.present?
            county_coordinator = county.county_coordinator
            coordinator = UseridDetail.where(:userid => county_coordinator).first
          else
            coordinator = nil
          end
        else
          coordinator = nil
        end
      else
        coordinator = nil
      end
    else
      coordinator = nil
    end
    return coordinator
  end

  def get_manager
    action_person = UseridDetail.role("contacts_coordinator").email_address_valid.first
    action_person = UseridDetail.secondary("contacts_coordinator").email_address_valid.first if action_person.blank?
    action_person = UseridDetail.userid("REGManager").email_address_valid.first if action_person.blank?
    action_person = UseridDetail.role("system_administrator").first if action_person.blank?
    action_person
  end

  def get_role_from_contact
    case self.contact_type
    when 'Website Problem'
      role = "website_coordinator"
    when 'Data Question'
      role = "contacts_coordinator"
    when 'Volunteering Question'
      role = "volunteer_coordinator"
    when 'General Comment'
      role = "general_communication_coordinator"
    when "Thank you"
      role = "publicity_coordinator"
    when 'Genealogical Question'
      role = "genealogy_coordinator"
    when 'Enhancement Suggestion'
      role =  "project_manager"
    else
      role = "general_communication_coordinator"
    end
    role
  end

  def github_issue
    if Contact.github_enabled
      self.add_link_to_attachment
      Octokit.configure do |c|
        c.login = Rails.application.config.github_issues_login
        c.password = Rails.application.config.github_issues_password
      end
      self.screenshot = nil
      response = Octokit.create_issue(Rails.application.config.github_issues_repo, issue_title, issue_body, :labels => [])
      logger.info("FREEREG:GITHUB response: #{response}")
      logger.info(response.inspect)
      self.update_attributes(:github_issue_url => response[:html_url],:github_comment_url => response[:comments_url], :github_number => response[:number])
    else
      logger.error("FREEREG:Tried to create an issue, but Github integration is not enabled!")
    end
  end

  def has_replies?(contact_id)
    Message.where(source_contact_id: contact_id).exists?
  end

  def issue_title
    "#{identifier} #{contact_type} (#{name})"
  end

  def issue_body
    issue_body = ApplicationController.new.render_to_string(:partial => 'contacts/github_issue_body.txt', :locals => {:feedback => self})
    issue_body
  end

  def url_check
    self.problem_page_url = "unknown" if self.problem_page_url.nil?
    self.previous_page_url = "unknown" if self.previous_page_url.nil?
  end


  private

  def add_sender_to_copies_of_contact_action_sent_to(sender)
    p "add_sender_to_copies_of_contact_action_sent_to"
    p self.copies_of_contact_action_sent_to
    if !(sender.userid == self.contact_action_sent_to || self.copies_of_contact_action_sent_to.include?(sender.userid))
      self.copies_of_contact_action_sent_to.push(sender.userid)
      self.update_attribute(:copies_of_contact_action_sent_to, self.copies_of_contact_action_sent_to)
    end
    p self.copies_of_contact_action_sent_to
  end

  def add_contact_coordinator_to_copies_of_contact_action_sent_to
    p "add_contact cordinator_to_copies_of_contact_action_sent_to"
    p self.copies_of_contact_action_sent_to
    action_person = UseridDetail.role("contacts_coordinator").email_address_valid.first
    action_person = UseridDetail.secondary("contacts_coordinator").email_address_valid.first if action_person.blank?
    if action_person.present? && !(action_person.userid == self.contact_action_sent_to || self.copies_of_contact_action_sent_to.include?(action_person.userid))
      self.copies_of_contact_action_sent_to.push(action_person.userid)
      self.update_attribute(:copies_of_contact_action_sent_to, self.copies_of_contact_action_sent_to)
    end
    p self.copies_of_contact_action_sent_to
  end

  def get_copies
    ccs = Array.new
    action_person = UseridDetail.userid(self.contact_action_sent_to).first
    ccs.push(action_person.email_address) if action_person.present?
    self.copies_of_contact_action_sent_to.each do |copy|
      copy_person = UseridDetail.userid(copy).first
      ccs.push(copy_person.email_address) if copy_person.present?
    end
    p 'copies'
    p ccs
    ccs
  end

  def reply_sent_messages(message, sender,contact_recipients,other_recipients)
    @message = message
    @sent_message = SentMessage.new(message_id: @message.id, sender: sender.userid, recipients: contact_recipients, other_recipients: other_recipients, sent_time: Time.now)
    @message.sent_messages <<  [ @sent_message ]
    @sent_message.save
    p "sent message stored"
    p @message
    p @message.sent_message
  end
end
