# encoding: utf-8
namespace :github do
  desc 'Email feedback/contact submitters when their linked GitHub issue is closed'
  task notify_closed_issues: :environment do
    Feedback.github_issue_status_closed
    #Contact.github_issue_status_closed
  end

  desc 'Email submitters for Feedback/Contact rows linked to GitHub issues closed yesterday (uses GitHub search by closed date). Optional DATE=YYYY-MM-DD for a specific day.'
  task notify_yesterday_closed_issues: :environment do
    GithubClosedYesterdayNotifier.run!(date: ENV['DATE'].presence)
  end

  desc 'Archive Feedback rows whose linked GitHub issue is closed. Set DRY_RUN=1 to list without archiving.'
  task archive_closed_feedbacks: :environment do
    dry_run = ENV['DRY_RUN'].present?
    if dry_run
      puts 'DRY RUN — no feedback will be archived'
    elsif !Feedback.github_enabled
      puts 'GitHub issues integration is not enabled (github_issues_password blank).'
      exit 1
    end

    puts 'Checking Feedback rows with linked GitHub issues...'
    stats = Feedback.archive_with_closed_github_issues(dry_run: dry_run)
    puts "Examined #{stats[:examined]}; #{dry_run ? 'would archive' : 'archived'} #{stats[:archived]}; skipped #{stats[:skipped]}; errors #{stats[:errors]}"
  end
end

# Uses GitHub issue search (closed:DAY..DAY) then matches Contact/Feedback by github_number.
class GithubClosedYesterdayNotifier
  def self.run!(date: nil)
    day = if date.present?
            Date.parse(date)
          else
            Time.zone.today - 1
          end
    from = Date.new(2025, 11, 22)
    to   = Date.yesterday

    unless Feedback.github_enabled
      puts 'GitHub issues integration is not enabled (github_issues_password blank).'
      return
    end

    Octokit.configure do |c|
      c.access_token = Rails.application.config.github_issues_access_token
    end

    repo = Rails.application.config.github_issues_repo
    day_s = day.strftime('%Y-%m-%d')
    query = "repo:#{repo} is:issue is:closed created:#{from.strftime('%Y-%m-%d')}..#{to.strftime('%Y-%m-%d')} closed:#{day_s}..#{day_s}"

    items = search_all_issues(query)
    puts "GitHub search returned #{items.size} issue(s) closed on #{day_s} in #{repo}."

    notified = 0
    items.each do |issue|
      record = find_closable_for_issue(issue.number)
      next if record.blank?

      if record.notified_issue_closed == true
        puts "  skip ##{issue.number}: #{record.class} #{record.id} already notified"
        next
      end

      record.deliver_github_issue_closed_notification!('closed')
      puts "  emailed ##{issue.number}: #{record.class} #{record.id} -> #{record.email_address}"
      notified += 1
    end

    puts "Sent #{notified} notification(s)."
  end

  def self.search_all_issues(query)
    was = Octokit.auto_paginate
    Octokit.auto_paginate = true
    Octokit.search_issues(query, per_page: 100).items.to_a
  ensure
    Octokit.auto_paginate = was
  end

  def self.find_closable_for_issue(issue_number)
    nums = [issue_number, issue_number.to_s].uniq
   # Contact.where(:github_number.in => nums, :github_issue_url.ne => nil).first ||
      Feedback.where(:github_number.in => nums, :github_issue_url.ne => nil).first
  end
end
