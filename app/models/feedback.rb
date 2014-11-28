class Feedback
  include Mongoid::Document
  include Mongoid::Timestamps
  field :title, type: String
  field :body, type: String
  field :feedback_time, type: DateTime
  field :user_id, type: String
  field :session_id, type: String
  field :problem_page_url, type: String
  field :previous_page_url, type: String
  field :feedback_type, type: String
  field :github_issue_url, type: String
  field :session_data, type: Hash
  field :screenshot, type: String
 
  mount_uploader :screenshot, ScreenshotUploader

 before_save :url_check
  after_create :communicate

  def url_check

    self.problem_page_url = "unknown" if self.problem_page_url.nil?
    self.previous_page_url = "unknown" if self.previous_page_url.nil?
  end
  
  module FeedbackType
    ISSUE='issue' #log a GitHub issue
    # To be added: contact form and other problems
  end
  
  
  def communicate
    if feedback_type == FeedbackType::ISSUE
      github_issue
    end
  end
  
  def github_issue
    if Feedback.github_enabled
      Octokit.configure do |c|
        c.login = Rails.application.config.github_login
        c.password = Rails.application.config.github_password
      end
      response = Octokit.create_issue(Rails.application.config.github_repo, issue_title, issue_body, :labels => [])
      logger.info(response)
      p response
      self.github_issue_url=response[:html_url]
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
