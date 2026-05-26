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

    def configure_github_octokit!
      Octokit.configure do |c|
        c.access_token = Rails.application.config.github_issues_access_token
      end
    end

    def poll_github_issues_closed
      return unless github_enabled

      configure_github_octokit!

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

    issue = fetch_github_issue
    return if issue.blank?
    return unless issue.state == 'closed'

    deliver_github_issue_closed_notification!(issue.state)
  rescue Octokit::Error => e
    Rails.logger.error("#{self.class.name}##{id} GitHub issue poll: #{e.class}: #{e.message}")
  end

  # Archives the record (and reply tree via #archive) when the linked GitHub issue is closed.
  def archive_if_github_issue_closed!
    return false if github_issue_url.blank? || github_number.blank?
    return false if respond_to?(:archived?) && archived?

    issue = fetch_github_issue
    return false if issue.blank?
    return false unless issue.state == 'closed'

    archive if respond_to?(:archive)
    update_attributes(github_issue_state: 'closed') if respond_to?(:github_issue_state)
    true
  rescue Octokit::Error => e
    Rails.logger.error("#{self.class.name}##{id} GitHub issue archive poll: #{e.class}: #{e.message}")
    false
  end

  def fetch_github_issue
    self.class.configure_github_octokit!
    Octokit.issue(Rails.application.config.github_issues_repo, github_number)
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
