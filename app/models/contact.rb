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
  attr_accessor :action

  validates_presence_of :name, :email_address
  validates :email_address,:format => {:with => /\A[^@][\w\+.-]+@[\w.-]+[.][a-z]{2,4}\z/i}

  mount_uploader :screenshot, ScreenshotUploader

  before_create :url_check, :add_identifier, :add_screenshot_location

  class << self
    def id(id)
      where(:id => id)
    end
  end
  ##########################################################################################

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
    case
    when  self.contact_type == 'Website Problem'
      self.communicate_website_problem(message,sender)
    when self.contact_type == 'Data Question'
      self.communicate_data_question(message,sender)
    when self.contact_type == 'Data Problem'
      self.communicate_data_problem(message,sender)
    when self.contact_type == 'Volunteering Question'
      self.communicate_volunteering(message,sender)
    when self.contact_type == 'General Comment'
      self.communicate_general(message,sender)
    when self.contact_type == "Thank-you"
      self.communicate_publicity(message,sender)
    when self.contact_type == 'Genealogical Question'
      self.communicate_genealogical_question(message,sender)
    when self.contact_type == 'Enhancement Suggestion'
      self.communicate_enhancement_suggestion(message,sender)
    else
      self.communicate_general(message,sender)
    end
  end


  def communicate_website_problem(message=nil,sender=nil)
    ccs = Array.new
    UseridDetail.any_of({ person_role: "website_coordinator", email_address_valid: true}, secondary_role: { '$in': ["website_coordinator"] }).all.each do |person|
      ccs << person.email_address
    end
    #UseridDetail.where(:person_role => 'contacts_coordinator', :email_address_valid => true).all.each do |person|
     # ccs << person.email_address
    #end
    if ccs.blank?
      UseridDetail.where(:person_role => 'system_administrator', :email_address_valid => true).all.each do |person|
        ccs << person.email_address
      end
    end
    @message = message
    unless @message.blank?
      reply_sent_messages(@message,sender)
      UserMailer.coordinator_contact_reply(self,ccs,@message,sender).deliver_now
    else
      UserMailer.website(self,ccs).deliver_now
    end
  end

  def communicate_data_question(message=nil,sender=nil)
    ccs = Array.new
    UseridDetail.where(:person_role => 'contacts_coordinator', :email_address_valid => true).all.each do |person|
      ccs << person.email_address
    end
    if ccs.blank?
      UseridDetail.where(:person_role => 'system_administrator', :email_address_valid => true).all.each do |person|
        ccs << person.email_address
      end
    end
    @message = message
    unless @message.blank?
      reply_sent_messages(@message,sender)
      UserMailer.coordinator_contact_reply(self,ccs,@message,sender).deliver_now
    else
      UserMailer.datamanager_data_question(self,ccs).deliver_now
    end
  end

  def communicate_data_problem(message=nil,sender=nil)
    ccs = Array.new
    coordinator = self.get_coordinator if self.record_id.present?
    ccs << coordinator.email_address if self.record_id.present?
    UseridDetail.where(person_role: 'contacts_coordinator', email_address_valid: true).all.each do |person|
      ccs << person.email_address
    end
    if ccs.blank?
      UseridDetail.where(person_role: 'system_administrator', email_address_valid: true).all.each do |person|
        ccs << person.email_address
      end
    end
    @message = message
    unless @message.blank?
      reply_sent_messages(@message,sender)
      UserMailer.coordinator_contact_reply(self,ccs,@message,sender.email_address).deliver_now
    else
      UserMailer.coordinator_data_problem(self,ccs).deliver_now
    end
  end

  def communicate_publicity(message=nil,sender=nil)
    ccs = Array.new
    UseridDetail.any_of({ person_role: "publicity_coordinator", email_address_valid: true}, secondary_role: { '$in': ["publicity_coordinator"] }).all.each do |person|
      ccs << person.email_address
    end
    #UseridDetail.where(:person_role => 'contacts_coordinator', :email_address_valid => true).all.each do |person|
     # ccs << person.email_address
    #end
    if ccs.blank?
      UseridDetail.where(:person_role => 'system_administrator', :email_address_valid => true).all.each do |person|
        ccs << person.email_address
      end
    end
    @message = message
    unless @message.blank?
      reply_sent_messages(@message,sender)
      UserMailer.coordinator_contact_reply(self,ccs,@message,sender).deliver_now
    else
      UserMailer.publicity(self,ccs).deliver_now
    end
  end

  def communicate_genealogical_question(message=nil,sender=nil)
    ccs = Array.new
    UseridDetail.any_of({ person_role: "genealogy_coordinator", email_address_valid: true}, secondary_role: { '$in': ["genealogy_coordinator"] }).all.each do |person|
      ccs << person.email_address
    end
    #UseridDetail.where(:person_role => 'contacts_coordinator', :email_address_valid => true).all.each do |person|
    #  ccs << person.email_address
    #end
    if ccs.blank?
      UseridDetail.where(:person_role => 'system_administrator', :email_address_valid => true).all.each do |person|
        ccs << person.email_address
      end
    end
    @message = message
    unless @message.blank?
      reply_sent_messages(@message,sender)
      UserMailer.coordinator_contact_reply(self,ccs,@message,sender).deliver_now
    else
      UserMailer.genealogy(self,ccs).deliver_now
    end
  end

  def communicate_enhancement_suggestion(message=nil,sender=nil)
    ccs = Array.new
    UseridDetail.any_of({ person_role: 'website_coordinator', email_address_valid: true}, secondary_role: { '$in': ["website_coordinator"] }).all.each do |person|
      ccs << person.email_address
    end
    UseridDetail.where(:person_role => 'project_manager', :email_address_valid => true).all.each do |person|
      ccs << person.email_address
    end
    if ccs.blank?
      UseridDetail.where(:person_role => 'system_administrator', :email_address_valid => true).all.each do |person|
        ccs << person.email_address
      end
    end
    @message = message
    unless @message.blank?
      reply_sent_messages(@message,sender)
      UserMailer.coordinator_contact_reply(self,ccs,@message,sender).deliver_now
    else
      UserMailer.enhancement(self,ccs).deliver_now
    end
  end

  def communicate_volunteering(message=nil,sender=nil)
    ccs = Array.new
    UseridDetail.any_of({ person_role: "volunteer_coordinator", email_address_valid: true}, secondary_role: { '$in': ["volunteer_coordinator"] }).all.each do |person|
      ccs << person.email_address
    end
    #UseridDetail.where(:person_role => 'contacts_coordinator', :email_address_valid => true).all.each do |person|
     # ccs << person.email_address
    #end
    if ccs.blank?
      UseridDetail.where(:person_role => 'system_administrator', :email_address_valid => true).all.each do |person|
        ccs << person.email_address
      end
    end
    @message = message
    unless @message.blank?
      reply_sent_messages(@message,sender)
      UserMailer.coordinator_contact_reply(self,ccs,@message,sender).deliver_now
    else
      UserMailer.volunteer(self,ccs).deliver_now
    end
  end

  def communicate_general(message=nil,sender=nil)
    ccs = Array.new
    UseridDetail.any_of({ person_role: "general_communication_coordinator", email_address_valid: true}, secondary_role: { '$in': ["general_communication_coordinator"] }).all.each do |person|
      ccs << person.email_address
    end
    #UseridDetail.where(:person_role => 'contacts_coordinator', :email_address_valid => true).all.each do |person|
      #ccs << person.email_address
    #end
    if ccs.blank?
      UseridDetail.where(:person_role => 'system_administrator', :email_address_valid => true).all.each do |person|
        ccs << person.email_address
      end
    end
    @message = message
    unless @message.blank?
      reply_sent_messages(@message,sender)
      UserMailer.coordinator_contact_reply(self,ccs,@message,sender).deliver_now
    else
      UserMailer.general(self,ccs).deliver_now
    end
  end

  def get_coordinator
    entry = SearchRecord.find(self.record_id).freereg1_csv_entry
    record = Freereg1CsvEntry.find(entry)
    file = record.freereg1_csv_file
    county = file.county #this is chapman code
    coordinator = UseridDetail.where(:userid => County.where(:chapman_code => county).first.county_coordinator).first
    return coordinator
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

  def self.github_enabled
    !Rails.application.config.github_issues_password.blank?
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

  def has_replies?(contact_id)
    Message.where(source_contact_id: contact_id).exists?
  end

  private
  def contact_recipients
    recipients = Array.new
    case self.contact_type
    when 'Website Problem'
      recipients << "website_coordinator"
      recipients << "system_administrator" if UseridDetail.any_of({ person_role: "website_coordinator", email_address_valid: true}, secondary_role: { '$in': ["website_coordinator"] }).all.count == 0
    when 'Data Question'
      recipients << "contacts_coordinator"
      recipients << "system_administrator" if UseridDetail.any_of({ person_role: "contacts_coordinator", email_address_valid: true}, secondary_role: { '$in': ["contacts_coordinator"] }).all.count == 0
    when 'Data Problem'
      recipients.push("county_coordinator","contact_coordinator")
      recipients << "system_administrator" if UseridDetail.any_of({ person_role: "contacts_coordinator", email_address_valid: true}, secondary_role: { '$in': ["contacts_coordinator"] }).all.count == 0
    when 'Volunteering Question'
      recipients.push("volunteer_coordinator")
      recipients << "system_administrator" if UseridDetail.any_of({ person_role: "volunteer_coordinator", email_address_valid: true}, secondary_role: { '$in': ["volunteer_coordinator"] }).all.count == 0
    when 'General Comment'
      recipients.push("general_communication_coordinator")
      recipients << "system_administrator" if UseridDetail.any_of({ person_role: "general_communication_coordinator", email_address_valid: true}, secondary_role: { '$in': ["general_communication_coordinator"] }).all.count == 0
    when "Thank you"
      recipients.push("publicity_coordinator")
      recipients << "system_administrator" if UseridDetail.any_of({ person_role: "publicity_coordinator", email_address_valid: true}, secondary_role: { '$in': ["publicity_coordinator"] }).all.count == 0
    when 'Genealogical Question'
      recipients.push("genealogy_coordinator")
      recipients << "system_administrator" if UseridDetail.any_of({ person_role: "genealogy_coordinator", email_address_valid: true}, secondary_role: { '$in': ["genealogy_coordinator"] }).all.count == 0
    when 'Enhancement Suggestion'
      recipients.push("website_coordinator", "project_manager")
      recipients << "system_administrator" if UseridDetail.any_of({ person_role: { '$in': ["website_coordinator", "project_manager"] }, email_address_valid: true}, secondary_role: { '$in': ["website_coordinator", "project_manager"] }).all.count == 0
    else
      recipients.push("general_communication_coordinator")
      recipients << "system_administrator" if UseridDetail.any_of({ person_role: "general_communication_coordinator", email_address_valid: true}, secondary_role: { '$in': ["general_communication_coordinator"] }).all.count == 0
    end
    return recipients
  end

  def reply_sent_messages(message, sender)
    @message = message
    @sent_message = SentMessage.new(message_id: @message.id, sender: sender.userid, recipients: contact_recipients, other_recipient: self.email_address, sent_time: Time.now)
    @message.sent_messages <<  [ @sent_message ]
    @sent_message.save
  end
end
