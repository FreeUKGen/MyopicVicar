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
 
  after_create :communicate
  
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
      response = Octokit.create_issue(Rails.application.config.github_repo, issue_title, issue_body)
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
    issue_body = <<END_OF_ISSUE
Issue reported by **#{user_id}** at #{created_at}
Time: #{feedback_time}
Session ID: #{session_id}
Problem Page URL: [#{problem_page_url}](#{problem_page_url})
Previous Page URL: [#{previous_page_url}](#{previous_page_url})
Reported Issue:
#{body}    
END_OF_ISSUE
  end
  
end
