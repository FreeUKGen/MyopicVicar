module MessagesHelper

  def active_field(message)
    message.active ? response = 'Active' : response = 'Inactive'
    response
  end

  def archived(message)
    message.archived.present? ? archived = 'Yes' : archived = 'No'
    archived
  end

  def attachment(message)
    message.attachment.present? || message.images.present? ? attachment = 'Yes' : attachment = 'No'
    attachment
  end

  def commit_action(f, params=nil)
    case
    when session[:message_base] == 'userid_messages'
      f.action :submit, as: :input,  label: 'Reply Message', button_html: {class: 'btn'}, wrapper_html: { class: 'grid__item  one-whole text--center' }
    when (session[:message_base] == 'syndicate' || session[:message_base] == 'general') && !params[:id].present?
      f.action :submit, as: :input,  label: 'Submit', button_html: {class: 'btn'}, wrapper_html: { class: 'grid__item  one-whole text--center' }
    when (session[:message_base] == 'syndicate' || session[:message_base] == 'general') && params[:id].present?
      f.action :submit, as: :input,  label: 'Reply Message', button_html: {class: 'btn'}, wrapper_html: { class: 'grid__item  one-whole text--center' }
    when params[:source_feedback_id].present?
      f.action :submit, as: :input,  label: 'Reply Feedback', button_html: {class: 'btn'}, wrapper_html: { class: 'grid__item  one-whole text--center' }
    when params[:source_contact].present?
      f.action :submit, as: :input,  label: 'Reply Contact', button_html: {class: 'btn'}, wrapper_html: { class: 'grid__item  one-whole text--center' }
    when params[:id].present?
      f.action :submit, as: :input, label: 'Save & Send', button_html: { class: 'btn ' }, wrapper_html: { class: 'grid__item  one-whole text--center' }
    else
      f.action :submit, as: :input,  label: 'Submit' , button_html: {class: 'btn'}, wrapper_html: { class: 'grid__item  one-whole text--center' }
    end
  end

  def contact_subject(contact)
    if contact_subject_hash.has_key?(contact.contact_type)
      subject = contact_subject_hash[contact.contact_type]
    else
      subject = contact_subject_hash['General Comment']
    end
    "#{subject}.Reference #{contact.identifier}"
  end

  def do_we_permit_an_edit?(message)
    do_we_permit = false
    if session[:message_base] == 'userid_messages'
      do_we_permit = true if message.mine?(@user) && !message.sent?
    elsif session[:message_base] == 'syndicate' || session[:message_base] == 'general'
      do_we_permit = true if message.source_message_id.blank? && message.mine?(@user) && !message.sent?
    else
      if message.source_feedback_id.blank?
        if message.source_contact_id.blank?
          if message.source_message_id.blank?
            do_we_permit = true
          end
        end
      end
    end
    do_we_permit
  end

  def do_we_show_archive_action?(message)
    do_we_permit = false
    if session[:message_base] == 'userid_messages'
      do_we_permit = false
    elsif session[:message_base] == 'syndicate' || session[:message_base] == 'general'
      do_we_permit = true if message.not_archived? && message.not_a_reply?
    else
      do_we_permit = true if message.not_archived? && message.not_a_reply?
    end
    do_we_permit
  end

  def do_we_show_destroy_action?(message)
    do_we_permit = false
    if session[:message_base] == 'userid_messages'
      do_we_permit = false
    elsif session[:message_base] == 'syndicate' || session[:message_base] == 'general'
      do_we_permit = true if !message.sent? && message.mine?(@user)
    else
      do_we_permit = true if message.archived? && message.not_being_kept? && message.not_a_reply?
    end
    do_we_permit
  end

  def do_we_index_list_archived?
    session[:message_base] == 'general' && !session[:archived_contacts] ? do_we_permit = true :  do_we_permit = false
    do_we_permit
  end

  def do_we_index_list_index?
    session[:message_base] == 'general' && session[:archived_contacts] ? do_we_permit = true :  do_we_permit = false
    do_we_permit
  end

  def do_we_index_list_archived_syndicate?
    session[:message_base] == 'syndicate' && !session[:archived_contacts] ? do_we_permit = true :  do_we_permit = false
  end

  def do_we_index_list_index_syndicate?
    session[:message_base] == 'syndicate' && session[:archived_contacts] ? do_we_permit = true :  do_we_permit = false
  end

  def do_we_show_keep_action?(message)
    (session[:message_base] == 'syndicate' || session[:message_base] == 'general') && message.keep.blank? && !message.a_reply? ? do_we_permit = true : do_we_permit = false
    do_we_permit
  end

  def do_we_show_unkeep_action?(message)
    (session[:message_base] == 'syndicate' || session[:message_base] == 'general') && message.keep.present? && !message.a_reply? ? do_we_permit = true :  do_we_permit = false
    do_we_permit
  end

  def do_we_show_restore_action?(message)
    do_we_permit = false
    if session[:message_base] == 'userid_messages'
      do_we_permit = false
    elsif session[:message_base] == 'syndicate' || session[:message_base] == 'general'
      do_we_permit = true if message.archived? && message.not_being_kept? && message.not_a_reply?
    else
      do_we_permit = true if message.not_archived? && message.not_being_kept? && message.not_a_reply?
    end
    do_we_permit
  end

  def do_we_show_replies_action?(message)
    message.there_are_reply_messages? ? do_we_permit = true : do_we_permit = false
    do_we_permit
  end

  def do_we_show_remove_action?(message)
    session[:message_base] == 'userid_messages' ? do_we_permit = true : do_we_permit = false
    do_we_permit
  end

  def do_we_show_reply_action?(message)
    do_we_permit = false
    if session[:message_base] == 'userid_messages' || session[:message_base] == 'general' || session[:message_base] == 'syndicate'
      do_we_permit = true if message.sent? && (message.not_a_reply? ||  (message.a_reply? && @user.does_not_have_original_message?(message)))
    end
    do_we_permit
  end

  def do_we_show_resend_action?(message)
    do_we_permit = false
    if session[:message_base] == 'userid_messages'
      do_we_permit = false
    else
      do_we_permit = true if message.sent_messages.present? && message.not_a_reply?
    end
    do_we_permit
  end

  def do_we_show_send_action?(message)
    do_we_permit = false
    if session[:message_base] == 'userid_messages'
      do_we_permit = false
    else
      do_we_permit = true if !message.sent_messages.present? && message.not_a_reply?
    end
    do_we_permit
  end

  def edit_title
    session[:syndicate] ? edit_title = 'Edit Syndicate Message Reference' : edit_title = 'Edit Message Reference'
  end

  def formatted_date(message)
    message.sent_time.blank? ? response = '' : response = message.sent_time.strftime('Sent at %H:%M on %e %b %Y')
    response
  end

  def index_breadcrumbs
    case
    when params[:action] ==  'list_incoming_syndicate_messages' || params[:action] == 'list_archived_incoming_syndicate_messages'
      breadcrumb :incoming_syndicate_messages
    when session[:syndicate]
      breadcrumb :message_to_syndicate
    when params[:action] == 'feedback_reply_messages'
      breadcrumb :feedback_messages, @feedback
    when params[:action] == 'list_feedback_reply_message'
      breadcrumb :list_feedback_reply_messages
    when params[:action] == 'contact_reply_messages'
      breadcrumb :contact_messages, @contact
    when params[:action] == 'list_contact_reply_message'
      breadcrumb :list_contact_reply_messages
    else
      breadcrumb :messages
    end
  end

  def index_header(action, syndicate)
    header = ''
    case action
    when 'list_feedback_reply_message'
      header = header + 'List of Feedback Reply messages'
    when 'feedback_reply_messages'
      header = header + "List of Reply Message for feedback sent by #{@feedback.name}, reference: #{@feedback.identifier}"
    when 'list_contact_reply_message'
      header = header + 'List of Contact Reply messages'
    when 'contact_reply_messages'
      header = header + "List of Reply Message for contact sent by #{@contact.name}, reference: #{@contact.identifier}"
    else
      header = header + 'List of '
      if session[:archived_contacts]
        header = header + 'Archived '
      else
        header = header + 'Active '
      end
      syndicate.present? ? header = header + 'Syndicate Messages for ' + syndicate : header = header + 'Messages'
    end
    header
  end

  def index_sort_links?
    case
    when params[:source].present?
      index_sort_links = false
    when params[:source] == 'list_syndicate_messages' || params[:source] == 'list_archived_syndicate_messages'
      index_sort_links = false
    when params[:source] == 'show_reply_messages' || params[:source] == 'user_reply_messages' || params[:source] == 'userid_reply_messages'
      index_sort_links = false
    else
      index_sort_links = true
    end
    index_sort_links
  end

  def index_create_option?
    create_option = false
    if session[:message_base] == 'syndicate' || session[:message_base] == 'general'
      create_option = true
    end
    create_option
  end

  def index_active_links
    case
    when params[:source].present?
      index_active_links = false
    when params[:source] == 'list_syndicate_messages' || params[:source] == 'list_archived_syndicate_messages'
      index_active_links = true
    when params[:source] == 'show_reply_messages' || params[:source] == 'user_reply_messages' || params[:source] == 'userid_reply_messages'
      index_active_links = false
    else
      index_active_links = false
    end
    index_active_links
  end

  def index_show_link
    case
    when params[:source].present?
      index_show_link('Show', message_path(message.id,:source => params[:action] ), :class => 'btn weight--light  btn--small')
    when params[:source] == 'list_syndicate_messages' || params[:source] == 'list_archived_syndicate_messages'
      index_show_link('Show', message_path(message.id,:source => params[:source] ), :class => 'btn weight--light  btn--small')
    when params[:source] == 'show_reply_messages' || params[:source] == 'user_reply_messages' || params[:source] == 'userid_reply_messages'
      index_show_link('Show', message_path(message.id), :class => 'btn weight--light  btn--small')
    else
    end
  end

  def kept(message)
    message.keep.present? ? keep = 'Yes' : keep = 'No'
    keep
  end

  def message_attachment_tag(message)
    if message.attachment.present?
      content_tag :td, :class => 'weight--semibold' do
        link_to('#{@message[:attachment]}', @message.attachment_url, target: '_blank', title: 'The link will open in a new tab')
      end
    end
  end

  def message_image_tag(message)
    if message.images.present?
      content_tag :td, :class => 'weight--semibold' do
        image_tag message.images_url
      end
    end
  end

  def message_subject
    case
    when !@respond_to_feedback.nil?
      text_field_tag 'message[subject]', "Re: Thank you for your feedback. Reference #{@respond_to_feedback.identifier}", :class => 'text-input', readonly: true, title: "Re: Thank you for your feedback. Reference #{@respond_to_feedback.identifier}"
    when !@respond_to_contact.nil?
      text_field_tag 'message[subject]', contact_subject(@respond_to_contact), :class => 'text-input', readonly: true, title: contact_subject(@respond_to_contact)
    when !@respond_to_message.nil?
      text_field_tag 'message[subject]', "Re: #{@respond_to_message.subject}", :class => 'text-input', readonly: true
    when @message.subject.nil? && @respond_to_message.nil? && @respond_to_feedback.nil?
      text_field_tag 'message[subject]', nil, :class => 'text-input', placeholder: 'Mandatory', required: true
    when @message.subject.present? && @respond_to_message.nil? && @respond_to_feedback.nil?
      text_field_tag 'message[subject]', "#{@message.subject}", :class => 'text-input'
    end
  end

  def reason(list)
    if list.blank?
      response = ''
    else
      response = Array.new
      list.each do |l|
        response << l
      end
    end
    response
  end

  def recipients_list
    if @syndicate
      options_for_select(['Members of Syndicate'])
    else
      options_for_select(@options,@sent_message.recipients)
    end
  end

  def reply_action(message)
    case
    when ReplyUseridRole::GENERAL_REPLY_ROLES.include?(@user.person_role)
      link_to 'Reply', reply_messages_path(message.id),method: :get,:class => 'btn weight--light  btn--small' if message.source_message_id.blank?
    when session[:syndicate].present? &&  ReplyUseridRole::COORDINATOR_ROLES.include?(@user.person_role)
      link_to 'Reply', reply_messages_path(message.id),method: :get,:class => 'btn weight--light  btn--small' if message.source_message_id.blank?
    end
  end

  def reply_messages_count(source_message)
    reply_messages = Message.fetch_replies(source_message.id).reject do |message|
      message.sent_messages.deliveries.count == 0
    end
    reply_messages.count
  end

  def sent(message)
    message.sent_messages.deliveries.count != 0 ? sent_messages = 'Yes' : sent_messages = 'No'
    sent_messages
  end

  def show_breadcrumb
    case
    when session[:message_base] == 'syndicate'
      breadcrumb :show_list_syndicate_messages , @message
    when session[:message_base] == 'userid_messages'
      breadcrumb :show_message, @message
    when session[:message_base] == 'general'
      breadcrumb :show_message, @message
    end
  end

  def show_replies_breadcrumbs
    case
    when session[:message_base] == 'syndicate'
      breadcrumb :replies_list_syndicate_messages, @main_message
    when session[:message_base] == 'general'
      breadcrumb :reply_messages_list, @main_message
    else
      breadcrumb :reply_messages_list, @main_message
    end
  end

  def show_replies_title
    if @main_message.syndicate.present?
      replies_title = 'All Replies for Syndicate Message'
    else
      replies_title = 'All Replies for Message'
    end
    replies_title = replies_title + " created by #{@main_message.userid} on #{@main_message.created_at.strftime('%F')} and sent #{@main_message.message_time.strftime('%F')}"
    replies_title
  end

  def show_status_title
    case
    when @message.archived? && @message.being_kept?
      the_show_title = 'The message is both archived and being kept. '
    when @message.archived?
      the_show_title = 'The message is archived. '
    when @message.being_kept?
      the_show_title = 'The message is being kept. '
    else
      the_show_title = nil
    end
    the_show_title
  end

  def show_attachment_title
    case
    when @message.attachment.blank? && @message.images.blank?
      the_show_title = 'There are no attachments or images.'
    when @message.attachment.present? && @message.images.present?
      the_show_title = 'There are both an attachment and an image.'
    when @message.attachment.blank?
      the_show_title = 'There is an image with the message.'
    else
      the_show_title = 'There is an attachment with the message.'
    end
    the_show_title
  end

  def show_title
    @message.a_reply? ? the_show_title = "A reply created by #{@message.userid} on #{@message.created_at.strftime('%F')} in response to a " : the_show_title = ''
    if @message.syndicate.present?
      the_show_title = the_show_title + 'Syndicate Message'
    else
      the_show_title = the_show_title + 'Message'
    end
    message = Message.id(@message.source_message_id).first
    @message.a_reply? ? the_show_title = the_show_title + " created by #{message.userid} on #{message.created_at.strftime('%F')}" :
      the_show_title = the_show_title + " created by #{@message.userid} on #{@message.created_at.strftime('%F')}"
    the_show_title
  end

  def source(message)
    message.syndicate.present? ? source = 'Syndicate' : source = 'General'
    source = source + ' Reply' if message.source_message_id.present?
    source
  end

  def reply_message_email
    case
    when params.has_key?(:source_feedback_id)
      content_tag :li, class: 'grid__item  one-whole  palm-one-whole push--bottom' do
        label_tag 'To Email'
        text_field_tag 'email', "#{@respond_to_feedback.email_address}", :class => 'text-input', readonly: true
      end
    when params.has_key?(:source_contact_id)
      content_tag :li, class: 'grid__item  one-whole  palm-one-whole push--bottom' do
        label_tag 'To Email'
        text_field_tag 'email', "#{@respond_to_contact.email_address}", :class => 'text-input', readonly: true
      end
    end
  end

  private

  def contact_subject_hash
    {
      'Website Problem' => 'RE: Thank you for reporting a website problem',
      'Data Question' => 'RE: Thank you for your data question',
      'Data Problem' => 'RE: Thank you for reporting a problem with our data',
      'Volunteering Question' => 'RE: Thank you for question about volunteering',
      'General Comment' => 'RE: Thank you for the general comment',
      'Thank-you' => 'RE: Thank you for your compliments',
      'Genealogical Question' => 'RE: Thank you for a genealogical question',
      'Enhancement Suggestion' => 'RE: Thank you for the suggested enhancement'
    }
  end

  def default_links
    [dynamic_link('Send this Message', send_message_messages_path(@message.id), data: { confirm: 'Are you sure you want to send this message'}, method: :get),
     dynamic_link('Edit this Message', edit_message_path(@message.id), method: :get)]
  end

  def dynamic_link(name, path, options={})
    link_to(name, path, class: "btn weight--light  btn--small", **options)
  end

  def primary_links(link_1, link_2)
    capture do
      concat link_1
      concat ' '
      concat link_2
      concat ' '
      concat dynamic_link("View #{pluralize(@sent_replies.count, 'Reply') }", show_reply_messages_path(@message.id)) unless @sent_replies.count == 0
    end
  end

end
