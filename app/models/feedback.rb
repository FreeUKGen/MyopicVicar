class Feedback
  include Mongoid::Document
  include Mongoid::Timestamps
  field :title, type: String
  field :body, type: String
  field :feedback_time, type: DateTime
  field :user_id, type: String
  field :email_address, type: String
  field :session_id, type: String
  field :problem_page_url, type: String
  field :previous_page_url, type: String
  field :feedback_type, type: String
  field :github_issue_url, type: String
  field :session_data, type: Hash
  field :screenshot, type: String
  field :identifier, type: String

  mount_uploader :screenshot, ScreenshotUploader

  validate :title_or_body_exist

  before_save :url_check, :add_identifier, :github_issue; :add_email
  after_create :communicate
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
    set = Random.new(123456789)
    self.identifier = set.rand(10000000)  
  end
  def add_email
    reporter = UseridDetail.userid(self.user_id).first
    self.email_address unless reporter.nil?
  end

  module FeedbackType
    ISSUE='issue' #log a GitHub issue
    # To be added: contact form and other problems
  end

  def communicate
    ccs = Array.new
    UseridDetail.where(:person_role => 'system_administrator').all.each do |person|
     ccs << person.email_address
    end
    UserMailer.website(self,ccs).deliver
  end

  def github_issue
    if Feedback.github_enabled
      Octokit.configure do |c|
        c.login = Rails.application.config.github_login
        c.password = Rails.application.config.github_password
      end
      response = Octokit.create_issue(Rails.application.config.github_repo, issue_title, issue_body, :labels => [])
      logger.info("APP: #{response}")
      self.github_issue_url = response[:html_url]
      self.save!
    else
      logger.error("Tried to create an issue, but Github integration is not enabled!")
    end
  end

  def self.github_enabled
    !Rails.application.config.github_password.blank?
  end

  def issue_title
    "#{title} (#{user_id})"
  end

  def issue_body
    issue_body = ApplicationController.new.render_to_string(:partial => 'feedbacks/github_issue_body.txt', :locals => {:feedback => self})
    issue_body
  end

end
