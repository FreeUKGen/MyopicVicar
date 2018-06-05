class Feedback
  include Mongoid::Document
  include Mongoid::Timestamps
  field :title, type: String
  field :body, type: String
  field :feedback_time, type: DateTime
  field :user_id, type: String
  field :name, type: String
  field :email_address, type: String
  field :session_id, type: String
  field :problem_page_url, type: String
  field :previous_page_url, type: String
  field :feedback_type, type: String
  field :github_issue_url, type: String
  field :github_comment_url, type: String
  field :github_number, type: String
  field :session_data, type: Hash
  field :screenshot_location, type: String
  field :screenshot, type: String
  field :identifier, type: String
  attr_accessor :action

  mount_uploader :screenshot, ScreenshotUploader

  validate :title_or_body_exist

  before_create :url_check, :add_identifier, :add_email, :add_screenshot_location

  class << self
    def id(id)
      where(:id => id)
    end
  end

  def title_or_body_exist
    errors.add(:title, "Either the Summary or Body must have content") if self.title.blank? && self.body.blank?
  end

  def url_check

    self.problem_page_url = "unknown" if self.problem_page_url.nil?
    self.previous_page_url = "unknown" if self.previous_page_url.nil?
  end

  def add_identifier
    self.identifier = Time.now.to_i - Time.gm(2015).to_i
  end

  def add_email
    reporter = UseridDetail.userid(self.user_id).first
    self.email_address = reporter.email_address unless reporter.nil?
    self.name = reporter.person_forename unless reporter.nil?
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
    self.screenshot_location = "uploads/feedback/screenshot/#{self.screenshot.model._id.to_s}/#{self.screenshot.filename}" if self.screenshot.filename.present?
  end

  module FeedbackType
    ISSUE='issue' #log a GitHub issue
    # To be added: contact form and other problems
  end

  def communicate
    ccs = Array.new
    UseridDetail.any_of({ person_role: 'website_coordinator', email_address_valid: true}, secondary_role: { '$in': ["website_coordinator"] }).all.each do |person|
      add_feedback_to_userid(person)
      ccs << person.email_address
    end

    user = UseridDetail.where(userid: self.user_id).first
    add_feedback_to_userid(user)
    #UseridDetail.where(:person_role => 'contacts_coordinator').email_address_valid.all.each do |person|
     # ccs << person.email_address
    #end
    if ccs.blank?
      UseridDetail.where(:person_role => 'system_administrator').email_address_valid.all.each do |person|
        add_feedback_to_userid(person)
        ccs << person.email_address
      end
    end
    UserMailer.feedback(self,ccs).deliver_now
  end

  def communicate_reply(message,recipient_email, sender_email)
    ccs = Array.new
    UseridDetail.any_of({ person_role: 'website_coordinator', email_address_valid: true}, secondary_role: { '$in': ["website_coordinator"] }).all.each do |person|
     update_reply_for_feedback(person,message)
     ccs << person.email_address
    end
    recipient = UseridDetail.where(email_address: recipient_email).first
    update_reply_for_feedback(recipient,message)
    if ccs.blank?
      UseridDetail.where(:person_role => 'system_administrator').email_address_valid.all.each do |person|
        update_reply_for_feedback(person,message)
        ccs << person.email_address
      end
    end
    UserMailer.feedback_reply(message,recipient_email,sender_email,ccs).deliver_now
  end

  def github_issue
    if Feedback.github_enabled
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
    "#{identifier} #{title} (#{name})"
  end

  def issue_body
    issue_body = ApplicationController.new.render_to_string(:partial => 'feedbacks/github_issue_body.txt', :locals => {:feedback => self})
    issue_body
  end

  def has_replies?(feedback_id)
    Message.where(source_feedback_id: feedback_id).exists?
  end

  def member_can_reply?(user)
    @user = user
    permitted_person_role || permitted_secondary_role
  end

  private

  def add_reply_to_userid_feedbacks(person)
    @reply_feedback_userid =  person.userid_feedback_replies
    if !@reply_feedback_userid.include? self.id.to_s
        @message_userid << self.id.to_s
        person.update_attribute(:userid_messages, @message_userid)
    end
  end

  def add_feedback_to_userid(person)
    @feedback_userid = person.userid_feedback_replies
    if !@feedback_userid.has_key?(self.id)
      @feedback_userid.store(self.id.to_s, [])
      person.update_attribute(:userid_feedback_replies, @feedback_userid)
    end
  end

  def update_reply_for_feedback(person,message)
    @feedback_userid = person.userid_feedback_replies
    if @feedback_userid.has_key?(self.id.to_s)
      @feedback_userid[self.id.to_s] << message.id.to_s unless @feedback_userid[self.id.to_s].include?(message.id.to_s)
      person.update_attribute(:userid_feedback_replies, @feedback_userid)
    end
  end

  def permitted_person_role
    ReplyUseridRole::FEEDBACK_REPLY_ROLE.include?(@user.person_role)
  end
  def permitted_secondary_role
    (@user.secondary_role & ReplyUseridRole::FEEDBACK_REPLY_ROLE).any?
  end
end
