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

  def commit_action(f, message, params = nil)
    case
    when message.nature == 'communication' && params[:id].present? && !(params[:source] == 'comment')
      f.action :submit, as: :input,  label: 'Reply Communication', button_html: {class: 'btn'}, wrapper_html: { class: 'grid__item  one-whole text--center' }
    when message.nature == 'communication' && params[:id].present? && params[:source] == 'comment'
      f.action :submit, as: :input,  label: 'Communication Comment', button_html: {class: 'btn'}, wrapper_html: { class: 'grid__item  one-whole text--center' }
    when message.nature == 'communication'
      f.action :submit, as: :input,  label: 'Save Communication', button_html: {class: 'btn'}, wrapper_html: { class: 'grid__item  one-whole text--center' }
    when (message.nature == 'syndicate' || message.nature == 'general') && !params[:id].present?
      f.action :submit, as: :input,  label: 'Save Message', button_html: {class: 'btn'}, wrapper_html: { class: 'grid__item  one-whole text--center' }
    when (message.nature == 'syndicate' || message.nature == 'general' || message.nature == 'feedback' || message.nature == 'contact') && params[:id].present? && !(params[:source] == 'comment')
      f.action :submit, as: :input,  label: 'Reply Message', button_html: {class: 'btn'}, wrapper_html: { class: 'grid__item  one-whole text--center' }
    when (message.nature == 'syndicate' || message.nature == 'general' || message.nature == 'feedback' || message.nature == 'contact') && params[:id].present? && params[:source] == 'comment'
      f.action :submit, as: :input,  label: 'Message Comment', button_html: {class: 'btn'}, wrapper_html: { class: 'grid__item  one-whole text--center' }
    when params[:source_feedback_id].present? && params[:source].blank?
      f.action :submit, as: :input,  label: 'Reply Feedback', button_html: {class: 'btn'}, wrapper_html: { class: 'grid__item  one-whole text--center' }
    when params[:source_feedback_id].present? && params[:source].present?
      f.action :submit, as: :input,  label: 'Feedback Comment', button_html: {class: 'btn'}, wrapper_html: { class: 'grid__item  one-whole text--center' }
    when params[:source_contact_id].present? && params[:source].blank?
      f.action :submit, as: :input,  label: 'Reply Contact', button_html: {class: 'btn'}, wrapper_html: { class: 'grid__item  one-whole text--center' }
    when params[:source_contact_id].present? && params[:source].present?
      f.action :submit, as: :input,  label: 'Contact Comment', button_html: {class: 'btn'}, wrapper_html: { class: 'grid__item  one-whole text--center' }
    when params[:id].present?
      f.action :submit, as: :input, label: 'Save & Send', button_html: { class: 'btn ' }, wrapper_html: { class: 'grid__item  one-whole text--center' }
    else
      f.action :submit, as: :input, label: 'Submit', button_html: {class: 'btn'}, wrapper_html: { class: 'grid__item  one-whole text--center' }
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
    if session[:message_base] == 'userid_messages' || session[:message_base] == 'communication'
      do_we_permit = true if message.mine?(@user) && !message.message_sent?
    elsif session[:message_base] == 'syndicate' || session[:message_base] == 'general'
      do_we_permit = true if message.source_message_id.blank? && message.mine?(@user) && !message.message_sent?
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
    elsif session[:message_base] == 'syndicate' || session[:message_base] == 'general'|| session[:message_base] == 'communication'
      if !message.message_sent?
        do_we_permit = false
      else
        do_we_permit = true if message.not_archived? && message.not_a_reply?
      end
    else
      do_we_permit = true if message.not_archived? && message.not_a_reply?
    end
    do_we_permit
  end

  def do_we_show_destroy_action?(message)
    do_we_permit = false
    if session[:message_base] == 'userid_messages' || session[:message_base] == 'communication'
      do_we_permit = true if !message.message_sent? && message.mine?(@user)
    elsif session[:message_base] == 'syndicate' || session[:message_base] == 'general'
      do_we_permit = true if !message.message_sent? && message.mine?(@user)
    else
      do_we_permit = true if message.archived? && message.not_being_kept? && message.not_a_reply?
    end
    do_we_permit
  end

  def do_we_show_keep_action?(message)
    (session[:message_base] == 'communication' || session[:message_base] == 'syndicate' || session[:message_base] == 'general' ) && message.message_sent?   && message.keep.blank? && !message.a_reply? ? do_we_permit = true : do_we_permit = false
    do_we_permit
  end

  def do_we_show_unkeep_action?(message)
    (session[:message_base] == 'communication' || session[:message_base] == 'syndicate' || session[:message_base] == 'general' ) && message.message_sent?  && message.keep.present? && !message.a_reply? ? do_we_permit = true :  do_we_permit = false
    do_we_permit
  end

  def do_we_show_restore_action?(message)
    do_we_permit = false
    if session[:message_base] == 'userid_messages'
      do_we_permit = false
    elsif session[:message_base] == 'syndicate' || session[:message_base] == 'general' || session[:message_base] == 'communication'
      if !message.message_sent?
        do_we_permit = false
      else
        do_we_permit = true if message.archived? && message.not_being_kept? && message.not_a_reply?
      end
    else
      do_we_permit = true if message.not_archived? && message.not_being_kept? && message.not_a_reply?
    end
    do_we_permit
  end

  def do_we_show_replies_action?(message)
    message.there_are_reply_messages? ? do_we_permit = true : do_we_permit = false
    do_we_permit
  end

  def edit_breadcrumb(message)
    case session[:message_base]
    when 'communication'
      breadcrumb :edit_communication, message
    when 'syndicate'
      breadcrumb :edit_syndicate_message, message
    when 'general'
      breadcrumb :edit_message, message
    when 'userid_messages'
      breadcrumb :edit_userid_message, message
    else
      breadcrumb :edit_message, message
    end
  end

  def edit_title
    case session[:message_base]
    when 'communication'
      edit_title = 'Edit Communication Reference'
    when 'syndicate'
      edit_title = 'Edit Syndicate Message Reference'
    else
      edit_title = 'Edit Message Reference'
    end
    edit_title
  end

  def formatted_date(message)
    message.sent_time.blank? ? response = '' : response = message.sent_time.strftime('Sent at %H:%M on %e %b %Y')
    response
  end

  def index_action_archive(message)
    if do_we_show_archive_action?(message)
      link_to 'Archive', archive_message_path(message.id, source: 'original'),
        :class => 'btn btn--small',
        data: { confirm: 'Are you sure you want to archive this message'}
    elsif do_we_show_restore_action?(message)
      link_to 'Restore', restore_message_path(message.id, source: 'original'),
        :class => 'btn btn--small',
        data: { confirm: 'Are you sure you want to restore this message' }
    end
  end

  def index_action_edit(message)
    if do_we_permit_an_edit?(message)
      link_to 'Edit', edit_message_path(message.id, source: 'original'), :class => 'btn btn--small', method: :get
    end
  end

  def index_action_show(message)
    if message.nature == 'contact'
      params[:source] = 'reply'
      link_to 'Show', show_reply_message_path(message.id, source: 'reply'), :class => 'btn btn--small', method: :get
    elsif message.nature == 'feedback'
      params[:source] = 'reply'
      link_to 'Show', show_reply_message_path(message.id, source: 'reply'), :class => 'btn btn--small', method: :get
    elsif message.not_a_reply?
      params[:source] = 'original'
      link_to 'Show', message_path(message.id, source: 'original'), :class => 'btn btn--small', method: :get
    elsif message.a_reply?
      params[:source] = 'reply'
      link_to 'Show', show_reply_message_path(message.id, source: 'reply'), :class => 'btn btn--small', method: :get
    end
  end

  def index_action_view_replies(message)
    if (message.nature == 'feedback'|| message.nature == 'contact') && message.there_are_reply_messages?
      params[:source] = 'reply'
      link_to 'View Replies', reply_messages_path(message.id, source: 'reply'), :class => 'btn btn--small', method: :get
    elsif message.not_a_reply?
      params[:source] = 'original'
      link_to 'View Replies', reply_messages_path(message.id, source: 'original'), :class => 'btn btn--small', method: :get  if do_we_show_replies_action?(message)
    elsif message.a_reply?
      params[:source] = 'reply'
      link_to 'View Replies', reply_messages_path(message.id, source: 'reply'), :class => 'btn btn--small', method: :get  if do_we_show_replies_action?(message)
    end
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

  def index_breadcrumbs
    case
    when session[:message_base] == 'syndicate'
      breadcrumb :syndicate_messages
    when session[:message_base] == 's'
      breadcrumb :userid_messages
    when session[:message_base] == 'communication'
      breadcrumb :communications
    when session[:message_base] == 'general'
      breadcrumb :messages
    when params[:action] == 'feedback_reply_messages'
      breadcrumb :feedback_messages, @feedback
    when params[:action] == 'contact_reply_messages'
      breadcrumb :contact_messages, @contact
    else
      breadcrumb :messages
    end
  end

  def index_explanation
    case
    when session[:message_base] == 'syndicate'
      explanation = 'These are the messages created and sent to your syndicate'
    when session[:message_base] == 'userid_messages'
      explanation = 'These are the messages that have been sent to you. Select the SHOW button to see the full message. The message can be removed from the list by selecting the REMOVE button on the SHOW page.'
    when session[:message_base] == 'communication'
      explanation = 'These are the communications you have written for a member of the team. Select the SHOW button to see the full message and options for SENDing it.'
    when session[:message_base] == 'general'
      explanation = 'These are the general messages written and sent to selected groups of individuals'
    when params[:action] == 'feedback_reply_messages'
      explanation = 'These are replies written and sent in response to a specific feedback'
    when params[:action] == 'contact_reply_messages'
      explanation = 'These are replies written and sent in response to a specific contact'
    end
    explanation
  end

  def index_header_create_link
    case session[:message_base]
    when 'communication'
      link_to 'Create Communication', new_message_path(:source => params[:source]), method: :get , :class => 'btn btn--small'
    when 'general'
      link_to 'Create Message', new_message_path(:source => params[:source]), method: :get , :class => 'btn btn--small'
    when 'syndicate'
      link_to 'Create Syndicate Message', new_message_path(:source => params[:source]), method: :get , :class => 'btn btn--small'
    end
  end

  def index_header_list_link
    if session[:message_base] == 'syndicate' && !session[:archived_contacts]
      link_to 'Archived Syndicate Messages', list_archived_syndicate_messages_path(:source => params[:source]) , method: :get , :class => 'btn btn--small'
    elsif session[:message_base] == 'syndicate' && session[:archived_contacts]
      link_to 'Active Syndicate Messages', list_syndicate_messages_path(:source => params[:source]), method: :get , :class => 'btn btn--small'
    elsif session[:message_base] == 'general' && !session[:archived_contacts]
      link_to 'Archived Messages', list_archived_messages_path(:source => params[:source]) , method: :get , :class => 'btn btn--small'
    elsif session[:message_base] == 'general' && session[:archived_contacts]
      link_to 'Active Messages', messages_path(:source => params[:source]), method: :get , :class => 'btn btn--small'
    elsif session[:message_base] == 'communication' && !session[:archived_contacts]
      link_to 'Archived Communications', list_archived_communications_messages_path(:source => params[:source]) , method: :get , :class => 'btn btn--small'
    elsif session[:message_base] == 'communication' && session[:archived_contacts]
      link_to 'Active Communications', communications_messages_path(:source => params[:source]), method: :get , :class => 'btn btn--small'
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
      if syndicate.present?
        header = header + 'Syndicate Messages for ' + syndicate
      elsif session[:message_base] == 'communication'
        header = header + 'Communications'
      else
        header = header + 'Messages'
      end
    end
    header
  end

  
  def index_partial_render(messages=nil, explanation=nil, source_type=nil)
    controller.controller_name
    if controller.controller_name == 'contacts' || controller.controller_name == 'feedbacks'
      render 'messages/index_table', messages:messages, explanation: explanation, source_type: source_type
    else
      render 'index_table', messages:messages
    end
  end

  def index_remove_link(message)
    if session[:message_base] == 'userid_messages'
      link_to 'Remove', remove_from_userid_detail_path(message.id, source: 'original'),
        :class => 'btn btn--small',
        data: { confirm: 'Are you sure you want to remove this message' },
        method: :delete
    end
  end

  def index_sort_links?
    session[:message_base] == 'general' ? index_sort_links = true : index_sort_links = false
    index_sort_links
  end

  def kept(message)
    message.keep.present? ? keep = 'Yes' : keep = 'No'
    keep
  end

  def message_attachment_tag(message)
    if message.attachment.present?
      content_tag :td, :class => 'weight--semibold' do
        link_to("Attachment named #{@message[:attachment]}", @message.attachment_url, :class => 'btn btn--small', target: '_blank', title: 'The link will open in a new tab')
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
    when !@respond_to_feedback.blank?
      text_field_tag 'message[subject]', "Re: Thank you for your feedback. Reference #{@respond_to_feedback.identifier}", :class => 'text-input flush--bottom', readonly: true, title: "Re: Thank you for your feedback. Reference #{@respond_to_feedback.identifier}"
    when !@respond_to_contact.blank?
      text_field_tag 'message[subject]', contact_subject(@respond_to_contact), :class => 'text-input flush--bottom', readonly: true, title: contact_subject(@respond_to_contact)
    when !@respond_to_message.blank?
      text_field_tag 'message[subject]', "Re: #{@respond_to_message.subject}", :class => 'text-input flush--bottom', readonly: true
    when @message.subject.blank? && @respond_to_message.blank? && @respond_to_feedback.blank?
      text_field_tag 'message[subject]', nil, :class => 'text-input flush--bottom', placeholder: 'Mandatory', required: true
    when @message.subject.present? && @respond_to_message.blank? && @respond_to_feedback.blank?
      text_field_tag 'message[subject]', "#{@message.subject}", :class => 'text-input'
    end
  end

  def new_breadcrumb(message, id)
    if session[:message_base] == 'communication'
      if id.present?
        breadcrumb :create_reply_communication, message, id
      else
        breadcrumb :create_communication, message
      end
    elsif session[:message_base] == 'syndicate'
      if id.present?
        breadcrumb :create_reply_syndicate_message, message, id
      else
        breadcrumb :create_syndicate_message, message
      end
    elsif session[:message_base] == 'general'
      if id.present?
        breadcrumb :create_message_reply, message, id
      else
        breadcrumb :create_message, message
      end
    elsif session[:message_base] == 'userid_messages'
      breadcrumb :create_reply_userid_message, message, id
    else
      breadcrumb :create_message, message
    end
  end

  def new_title(message, id)
    case
    when session[:message_base] == 'communication'
      if id.present?
        new_title = 'Reply for a Communication'
      else
        new_title = 'Create a Communication'
      end
    when session[:message_base] == 'syndicate'
      if id.present?
        new_title = 'Reply for a Syndicate Message'
      else
        new_title = 'Create a Syndicate Message'
      end
    when session[:message_base] == 'general'
      if id.present?
        new_title = 'Reply for a General Message'
      else
        new_title = 'Create a General Message'
      end
    when session[:message_base] == 'userid_messages'
      if id.present?
        new_title = 'Reply for a Message'
      else
        new_title = 'Create a Message'
      end
    end
    new_title
  end

  def open_status(message)
    field = message.open_data_status
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
    if @message.nature == 'communication'
      options_for_select(@people, @people[0])
    elsif @syndicate
      options_for_select(['Members of Syndicate'])
    else
      options_for_select(@options, @sent_message.recipients)
    end
  end

  def replies_breadcrumbs
    case
    when session[:message_base] == 'userid_messages'
      breadcrumb :userid_reply_messages, @main_message
    when session[:message_base] == 'syndicate'
      breadcrumb :list_replies_to_syndicate_message, @main_message
    when session[:message_base] == 'general'
      breadcrumb :reply_messages_list, @main_message
    when session[:message_base] == 'communication'
      breadcrumb :list_reply_communications, @main_message
    else
      breadcrumb :reply_messages_list, @main_message
    end
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

  def reply_action(message)
    case
    when ReplyUseridRole::GENERAL_REPLY_ROLES.include?(session[:role])
      link_to 'Reply', reply_messages_path(message.id), method: :get, :class => 'btn btn--small' if message.source_message_id.blank?
    when session[:syndicate].present? &&  ReplyUseridRole::COORDINATOR_ROLES.include?(session[:role])
      link_to 'Reply', reply_messages_path(message.id), method: :get, :class => 'btn btn--small' if message.source_message_id.blank?
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
    when session[:message_base] == 'communication'
      if params[:source] == 'reply'
        breadcrumb :show_reply_communication, @message
      else
        breadcrumb :show_communication, @message
      end
    when session[:message_base] == 'syndicate'
      if params[:source] == 'reply'
        breadcrumb :show_syndicate_reply_message, @message
      else
        breadcrumb :show_syndicate_message, @message
      end
    when session[:message_base] == 'userid_messages'
      if @message.nature == 'contact' && params[:source] == 'reply'
        breadcrumb :show_reply_contact_message, @message
      elsif @message.nature == 'feedback' && params[:source] == 'reply'
        breadcrumb :show_reply_feedback_message, @message
      elsif @message.nature == 'general' && params[:source] == 'reply'
        breadcrumb :show_reply_message, @message
      elsif params[:source] == 'reply'
        breadcrumb :show_userid_reply_message, @message
      else
        breadcrumb :show_userid_message, @message
      end
    when session[:message_base] == 'general'
      if params[:source] == 'reply'
        breadcrumb :show_reply_message, @message
      else
        breadcrumb :show_message, @message
      end
    when @message.nature == 'contact' && params[:source] == 'reply'
      breadcrumb :show_reply_contact_message, @message
    when @message.nature == 'feedback' && params[:source] == 'reply'
      breadcrumb :show_reply_feedback_message, @message
    end
  end

  def show_create_reply_link(message, action)
    if message.nature == 'contact' && !(session[:message_base] == 'userid_messages')
      link_to 'Reply', reply_contact_path(source_contact_id: message.source_contact_id), :class => "btn btn--small"
    elsif message.nature == 'feedback' && !(session[:message_base] == 'userid_messages')
      link_to 'Reply', reply_feedback_path(source_feedback_id: message.source_feedback_id), :class => "btn btn--small"
    elsif message.message_sent?
      link_to 'Reply', new_reply_messages_path(message.id, source: action), :class => 'btn btn--small' unless session[:message_base] == 'userid_messages' && (message.nature == 'contact' || message.nature == 'feedback')
    end
  end

  def show_add_comment_link(message, action)
    if message.nature == 'contact' && !(session[:message_base] == 'userid_messages')
      #link_to 'Comment', reply_contact_path(source_contact_id: message.source_contact_id, source: 'comment'), :class => "btn btn--small"
    elsif message.nature == 'feedback' && !(session[:message_base] == 'userid_messages')
      #link_to 'Reply', reply_feedback_path(source_feedback_id: message.source_feedback_id), :class => "btn btn--small"
    elsif message.message_sent?
      link_to 'Comment', new_reply_messages_path(message.id, source: 'comment'), :class => "btn btn--small"
    end
  end

  def show_destroy_link(message, action)
    if do_we_show_destroy_action?(message)
      link_to 'Destroy', force_destroy_messages_path(message.id, :source => action),
        :class => 'btn btn--small', title: 'This message may have replies which and will also be destroyed with this action',
        data: { confirm: 'This message may have replies. Are you sure you want to delete this message and all its replies' }
    end
  end

  def show_edit_link(message, action)
    if do_we_permit_an_edit?(message)
      link_to 'Edit', edit_message_path(message.id, source: action), :class => 'btn btn--small'
    end
  end

  def show_keep_link(message, action)
    if do_we_show_keep_action?(message)
      link_to 'Keep until I say so', keep_message_path(message.id, :source => action), :class => 'btn btn--small',
        data: { confirm: 'Are you sure you want keep this message' }
    elsif do_we_show_unkeep_action?(message)
      link_to 'Remove Keep Designation', unkeep_message_path(@message.id,:source => action), :class => 'btn btn--small',
        data: { confirm: 'Are you sure you want remove the keep designation for this message' }
    end
  end

  def show_remove_link(message, action)
    if session[:message_base] == 'userid_messages'
      link_to 'Remove', remove_from_userid_detail_path(message.id, source: 'original'),
        :class => 'btn btn--small',
        data: { confirm: 'Are you sure you want to remove this message' },
        method: :delete
    end
  end

  def show_send_link(message, action)
    if message.nature == 'communication' && !message.message_sent? && message.not_a_reply? && message.mine?(@user)
      link_to 'Send Communication', select_role_message_path(message.id, source: action), :class => 'btn btn--small' , data: { confirm: 'Are you sure you want to send this message'}, method: :get
    elsif message.nature == 'communication' && message.message_sent? && message.not_a_reply? && message.mine?(@user)
      link_to 'Resend Communication', select_role_message_path(message.id, source: action), :class => 'btn btn--small' , data: { confirm: 'Are you sure you want to send this message'}, method: :get
    elsif message.nature == 'syndicate' && !message.message_sent? && message.not_a_reply? && message.mine?(@user)
      link_to 'Select Syndicate Message Recipients and Send', select_recipients_messages_path(message.id, source: action), :class => 'btn btn--small' , data: { confirm: 'Are you sure you want to select recipients and send this message'}, method: :get
    elsif message.nature == 'syndicate' && message.message_sent? && message.not_a_reply? && message.mine?(@user)
      link_to 'Select Syndicate Message Recipients and Resend', select_recipients_messages_path(message.id, source: action), :class => 'btn btn--small' , data: { confirm: 'Are you sure you want to select recipients and resend this message'}, method: :get
    elsif message.nature == 'general' && !message.message_sent? && message.not_a_reply? && message.mine?(@user)
      link_to 'Select Message Recipients and Send', select_recipients_messages_path(message.id, source: action), :class => 'btn btn--small' , data: { confirm: 'Are you sure you want to select recipients and send this message'}, method: :get
    elsif message.nature == 'general' && message.message_sent? && message.not_a_reply? && message.mine?(@user)
      link_to 'Select Message Recipients and Resend', select_recipients_messages_path(message.id, source: action), :class => 'btn btn--small' , data: { confirm: 'Are you sure you want to select recipients and resend this message'}, method: :get
    end
  end
  def show_view_replies_link(message, action)
    if do_we_show_replies_action?(message)
      link_to 'View Replies', reply_messages_path(message.id, source: action), :class => 'btn btn--small', method: :get
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

  def show_status_title(message)
    case
    when message.archived? && message.being_kept?
      the_show_title = 'The message is both archived and being kept. '
    when message.archived?
      the_show_title = 'The message is archived. '
    when message.being_kept?
      the_show_title = 'The message is being kept. '
    else
      the_show_title = nil
    end
    the_show_title
  end

  def show_attachment_title(message)
    case
    when message.attachment.blank? && message.images.blank?
      the_show_title = 'There are no attachments or images.'
    when message.attachment.present? && message.images.present?
      the_show_title = 'There are both an attachment and an image.'
    when message.attachment.blank?
      the_show_title = 'There is an image with the message.'
    else
      the_show_title = 'There is an attachment with the message.'
    end
    the_show_title
  end

  def show_title(message)
    case message.nature
    when 'communication'
      message.a_reply? ? the_show_title = "A response created by #{message.userid} on #{message.created_at.strftime('%F')} in response to a Communication" :
        the_show_title = "Communication created by #{message.userid} on #{message.created_at.strftime('%F')}"
    when 'general'
      message.a_reply? ? the_show_title = "A response created by #{message.userid} on #{message.created_at.strftime('%F')} in response to a Message" :
        the_show_title = "Message created by #{message.userid} on #{message.created_at.strftime('%F')}"
    when 'syndicate'
      message.a_reply? ? the_show_title = "A response created by #{message.userid} on #{message.created_at.strftime('%F')} in response to a Syndicate Message" :
        the_show_title = "Syndicate Message created by #{message.userid} on #{message.created_at.strftime('%F')}"
    when 'feedback'
      message = Feedback.id(@message.source_feedback_id).first
      if message.present?
        the_show_title = "Feedback response created by #{message.name} on #{message.created_at.strftime('%F')}"
      else
        message = Message.id(@message.source_message_id).first
        the_show_title = "Feedback response created by #{message.userid} on #{message.created_at.strftime('%F')}"
      end
    when 'contact'
      message = Contact.id(@message.source_contact_id).first
      if message.present?
        the_show_title = "Contact response created by #{message.name} on #{message.created_at.strftime('%F')}"
      else
        message = Message.id(@message.source_message_id).first
        the_show_title = "Contact response created by #{message.userid} on #{message.created_at.strftime('%F')}"
      end
    end
    the_show_title
  end

  def source(message)
    source = ''
    case message.nature
    when 'syndicate'
      source = 'Syndicate'
    when 'general'
      source = 'General'
    when 'communication'
      source = 'Communication'
    when 'feedback'
      source = 'Feedback'
    when 'contact'
      source = 'Contact'
    end
    source = source + ' Reply' if message.source_message_id.present? || message.source_contact_id.present? || message.source_feedback_id.present?
    source
  end

  def message_synicate_coordinator_first_reminder
    get_user_info_from_userid
    if @user.present? && session[:role] == 'transcriber'
      content_tag :span, "Have you already tried contacting your Syndicate Coordinator?"
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
      'Thank-you' => 'RE: Thank you for your review',
      'Genealogical Question' => 'RE: Thank you for a genealogical question',
      'Enhancement Suggestion' => 'RE: Thank you for the suggested enhancement'
    }
  end
end
