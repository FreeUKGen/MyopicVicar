module ContactsHelper

  def do_we_show_archive_contact_action?(contact)
    !contact.archived? && contact.not_being_kept? ? do_we_permit = true : do_we_permit = false
    do_we_permit
  end

  def do_we_show_keep_contact_action?(contact)
    contact.not_being_kept? ? do_we_permit = true : do_we_permit = false
    do_we_permit
  end

  def do_we_show_github_create_contact_action?(contact)
    Contact.github_enabled ? do_we_permit = true : do_we_permit = false
    do_we_permit
  end

  def do_we_show_restore_contact_action?(contact)
    contact.archived? && contact.not_being_kept? ? do_we_permit = true : do_we_permit = false
    do_we_permit
  end

  def do_we_show_unkeep_contact_action?(contact)
    contact.being_kept? ? do_we_permit = true :  do_we_permit = false
    do_we_permit
  end

  def show_contact_title(contact)
    show_title = "#{contact.name} contacted us with a #{contact.contact_type} on #{contact.contact_time.strftime("%F")}"
  end

  def show_contact_title_line_two(contact)
    show_title = "We assigned reference number #{contact.identifier} and it is "
    contact.archived? ? show_title = show_title + 'archived ' : show_title = show_title + 'active '
    contact.screenshot_url.present? ?  show_title = show_title + 'and a screenshot was provided' : show_title = show_title + ' and no screenshot is available'
  end

  def show_contact_add_comment_link(message, action)
    link_to 'Comment', reply_contact_path(source_contact_id: message.id, source: 'comment'), :class => "btn btn--small"
  end

  def use_communicate_action_reminder
    get_user_info_from_userid
    if @user.present? && @user.person_role == 'transcriber'
      content_tag(:span, content_tag(:strong, "For transcribing queries, please contact your Syndicate Coordinator using the #{communicate_link}".html_safe))
    end
  end

  def communicate_link
    link_to('Communicate Action','/messages/new?source=original', target: '_blank')
  end

  # Renders a report-error subsection answer. Supports:
  # - Plain text and formatted HTML: sanitized and output (use when answer contains <p>, <ul>, <a>, etc.).
  def render_report_error_answer(answer)
    return '' if answer.blank?
    if answer.to_s.include?('<')
      sanitize(answer.to_s, tags: %w[p br ul ol li a strong em], attributes: { 'a' => ['href', 'target'] })
    else
      simple_format(answer)
    end
  end
end
