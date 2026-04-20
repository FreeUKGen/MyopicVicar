module ContactsHelper

  FREEBMD_SECTION3_DISPLAY_ORDER = %w[event year quarter surname forename district page_number multiple_entries].freeze
  FREEBMD_SECTION3_LABELS = {
    'event' => 'Event',
    'year' => 'Year',
    'quarter' => 'Quarter',
    'surname' => 'Surname',
    'forename' => 'Forename',
    'district' => 'District',
    'page_number' => 'Page number',
    'multiple_entries' => 'Multiple entries'
  }.freeze

  def freebmd_field_report_rows(contact)
    return [] unless contact&.session_data.is_a?(Hash)

    contact.session_data['freebmd_field_report'].presence || []
  end

  # Normalized rows for the report-error "missing entry" (section 3) block in session_data.
  def freebmd_missing_entry_rows(contact)
    return [] unless contact&.session_data.is_a?(Hash)

    raw = contact.session_data['section3'] || contact.session_data[:section3]
    return [] unless raw.is_a?(Hash)

    s3 = raw.stringify_keys
    rows = []
    FREEBMD_SECTION3_DISPLAY_ORDER.each do |key|
      val = s3[key]
      next if val.blank?
      next if key == 'multiple_entries' && val.to_s != '1'

      display_val = key == 'multiple_entries' ? 'Yes' : val.to_s
      rows << { 'field' => FREEBMD_SECTION3_LABELS[key], 'value' => display_val }
    end
    rows
  end

  def format_contact_body_for_display(contact)
    body = contact&.body.to_s
    return ''.html_safe if body.blank?

    content_tag(
      :div,
      body,
      class: 'contact-body-formatted read-length',
      style: 'white-space: pre-wrap; word-wrap: break-word; max-width: 48rem;'
    )
  end

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
    rendered = answer.to_s
    if rendered.include?('{{PRIVACY_POLICY_LINK}}') && defined?(Constant::PRIVACY_POLICY_LINK)
      rendered = rendered.gsub('{{PRIVACY_POLICY_LINK}}', Constant::PRIVACY_POLICY_LINK.to_s)
    end
    rendered = rendered.gsub(/\bGRO\b/, ApplicationHelper::GRO_ABBREV_ACCESSIBILITY_HTML)

    if rendered.include?('<')
      sanitize(
        rendered,
        tags: %w[p br ul ol li a strong em span small],
        attributes: { 'a' => %w[href target rel], 'span' => %w[class] }
      )
    else
      simple_format(rendered)
    end
  end
end
