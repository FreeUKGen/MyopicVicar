module FeedbacksHelper
  def do_we_show_keep_feedback_action?(feedback)
    feedback.not_being_kept? ? do_we_permit = true : do_we_permit = false
    do_we_permit
  end

  def do_we_show_unkeep_feedback_action?(feedback)
    feedback.being_kept? ? do_we_permit = true :  do_we_permit = false
    do_we_permit
  end

  def do_we_show_restore_feedback_action?(feedback)
    feedback.archived? && feedback.not_being_kept? ? do_we_permit = true : do_we_permit = false
    do_we_permit
  end

  def do_we_show_archive_feedback_action?(feedback)
    !feedback.archived? && feedback.not_being_kept? ? do_we_permit = true : do_we_permit = false
    do_we_permit
  end

  def do_we_show_github_create_feedback_action?(feedback)
    Contact.github_enabled ? do_we_permit = true : do_we_permit = false
    do_we_permit
  end

  def show_feedback_title(feedback)
    show_title = "#{feedback.user_id} submitted feedback #{feedback.title}"
  end

  def show_feedback_title_line_two(feedback)
    show_title = "We assigned reference number #{feedback.identifier} and it is "
    feedback.archived? ? show_title = show_title + 'archived ' : show_title = show_title + 'active '
    feedback.screenshot_url.present? ?  show_title = show_title + 'and a screenshot was provided' : show_title = show_title + ' and no screenshot is available'
  end

  def show_feedback_add_comment_link(message, action)
    link_to 'Comment', reply_feedback_path(source_feedback_id: message.id, source: 'comment'), :class => "btn btn--small"
  end
end
