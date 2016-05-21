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
  field :screenshot, type: String
  field :identifier, type: String
  attr_accessor :action

  mount_uploader :screenshot, ScreenshotUploader

  validate :title_or_body_exist

  before_create :url_check, :add_identifier, :add_email
 
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

  module FeedbackType
    ISSUE='issue' #log a GitHub issue
    # To be added: contact form and other problems
  end

  def communicate
    ccs = Array.new
    UseridDetail.where(:person_role => 'contacts_coordinator').all.each do |person|
      ccs << person.email_address
    end
    if ccs.blank?
      UseridDetail.where(:person_role => 'system_administrator').all.each do |person|
        ccs << person.email_address
      end
    end
    UserMailer.feedback(self,ccs).deliver    
  end 

  def github_issue
    if Feedback.github_enabled
      Octokit.configure do |c|
        c.login = Rails.application.config.github_login
        c.password = Rails.application.config.github_password
      end
      response = Octokit.create_issue(Rails.application.config.github_repo, issue_title, issue_body, :labels => [])
      logger.info("FREEREG:GITHUB response: #{response}")
      logger.info(response.inspect)
      self.update_attributes(:github_issue_url => response[:html_url],:github_comment_url => response[:comments_url], :github_number => response[:number])
    else
      logger.error("FREEREG:Tried to create an issue, but Github integration is not enabled!")
    end
  end

  def self.github_enabled
    !Rails.application.config.github_password.blank?
  end

  def issue_title
   "#{identifier} #{title} (#{name})"
  end

  def issue_body
    issue_body = ApplicationController.new.render_to_string(:partial => 'feedbacks/github_issue_body.txt', :locals => {:feedback => self})
    issue_body
  end

end
