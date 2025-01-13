namespace :freereg do
  desc 'Notify when issue is closed'
  task notify_issue_closed: [:environment] do
    p Time.current
    Feedback.github_issue_status_closed
    p 'finished'
  end
end
