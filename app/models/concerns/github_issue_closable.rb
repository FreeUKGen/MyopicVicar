# encoding: utf-8
# Polls GitHub for issue state and emails the submitter when an issue is closed.
module GithubIssueClosable
  extend ActiveSupport::Concern

  included do
    field :github_issue_state, type: String
    field :notified_issue_closed, type: Boolean, default: false
  end

  module ClassMethods
    # Legacy name kept for callers (e.g. rake tasks, cron).
    def github_issue_status_closed
      poll_github_issues_closed
    end

    def poll_github_issues_closed
      return unless github_enabled

      Octokit.configure do |c|
        c.access_token = Rails.application.config.github_issues_access_token
      end

      base = where(:github_issue_url.ne => nil).where(:github_number.ne => nil).where(:notified_issue_closed.ne => true)
      criteria = base.respond_to?(:no_timeout) ? base.no_timeout : base
      criteria.each do |record|
        record.notify_if_github_issue_closed!
      end
    end
  end

  def notify_if_github_issue_closed!
    return if github_issue_url.blank? || github_number.blank?
    return if notified_issue_closed == true

    issue = Octokit.issue(Rails.application.config.github_issues_repo, github_number)
    return if issue.blank?

    issue_state = issue.state
    return unless issue_state == 'closed'

    deliver_github_issue_closed_notification!(issue_state)
  rescue Octokit::Error => e
    Rails.logger.error("#{self.class.name}##{id} GitHub issue poll: #{e.class}: #{e.message}")
  end

  # Sends the closed-issue email and persists state. Use when GitHub already shows closed
  # (e.g. issue search by +closed:+ date) to avoid an extra per-issue API call.
  def deliver_github_issue_closed_notification!(state = 'closed')
    return if notified_issue_closed == true
    return if github_issue_url.blank?

    UserMailer.communicate_github_issue_closed(self).deliver_now
    update_attributes(github_issue_state: state, notified_issue_closed: true)
  rescue StandardError => e
    Rails.logger.error("#{self.class.name}##{id} deliver_github_issue_closed_notification!: #{e.class}: #{e.message}")
  end
end
