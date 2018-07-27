module MessagesHelper
  def attachment(message)
    if message.attachment.present? || message.images.present?
      attachment = "Yes"
    else
      attachment = "No"
    end
    attachment
  end
  def sent(message)
    if message.sent_messages.deliveries.count != 0 #present? && message.message_sent_time.present?
      sent_messages = "Yes"
    else
      sent_messages = "No"
    end
    sent_messages
  end
  def active_field(message)
    if message.active
      response = "Active"
    else
      response = "Inactive"
    end
    response
  end
  def formatted_date(message)
    if message.sent_time.blank?
      response = ""
    else
      response = message.sent_time.strftime("Sent at %H:%M on %e %b %Y")
    end
    response
  end
  def reason(list)
    if list.blank?
      response = ""
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
      options_for_select(["Members of Syndicate"])
    else
      options_for_select(@options,@sent_message.recipients)
    end
  end

  def reply_messages_count(source_message)
    reply_messages = Message.fetch_replies(source_message.id).reject do |message|
      message.sent_messages.deliveries.count == 0
    end
    reply_messages.count
  end

  def message_attachment_tag(message)
    if message.attachment.present?
      content_tag :td, :class => "weight--semibold" do
        link_to("#{@message[:attachment]}", @message.attachment_url, target: "_blank", title: 'The link will open in a new tab')
      end
    else
      content_tag(:td, "No text document attached.", :class => "weight--semibold")
    end
  end

  def message_image_tag(message)
    if message.images.present?
      content_tag :td, :class => "weight--semibold" do
        image_tag message.images_url
      end
    else
      content_tag :td, 'No images attached', :class => "weight--semibold"
    end
  end

  def reply_action(message)
    case
    when ReplyUseridRole::GENERAL_REPLY_ROLES.include?(@user.person_role)
      link_to 'Reply', reply_messages_path(message.id),method: :get,:class => "btn weight--light  btn--small" if message.source_message_id.blank?
    when session[:syndicate].present? &&  ReplyUseridRole::COORDINATOR_ROLES.include?(@user.person_role)
      link_to 'Reply', reply_messages_path(message.id),method: :get,:class => "btn weight--light  btn--small" if message.source_message_id.blank?
    end
  end

  def show_links
    case
    when @message.source_feedback_id.present?
      dynamic_link('Show Feedback', feedback_path(@message.source_feedback_id), {class: "btn weight--light  btn--small", method: :get})
    when @message.source_contact_id.present?
      dynamic_link('Show Contact', contact_path(@message.source_contact_id), {class: "btn weight--light  btn--small", method: :get})
    else
      primary_links(*default_links)
    end
  end

  def index_breadcrumbs
    case
    when session[:syndicate]
      breadcrumb :message_to_syndicate
    when params[:action] == "feedback_reply_messages"
      breadcrumb :feedback_messages, @feedback
    when params[:action] == "list_feedback_reply_message"
      breadcrumb :list_feedback_reply_messages
    when params[:action] == "contact_reply_messages"
      breadcrumb :contact_messages, @contact
    when params[:action] == "list_contact_reply_message"
      breadcrumb :list_contact_reply_messages
    else
      breadcrumb :messages
    end
  end

  def commit_action(f,key=nil)
    case key
    when "id"
      f.action :submit, as: :input, label: 'Save & Send' , button_html: { class: "btn " }, wrapper_html: { class: "grid__item  one-whole text--center" }
    when "source_feedback_id"
      f.action :submit, as: :input,  label: 'Reply Feedback' , button_html: { :class => "btn " }, wrapper_html: { class: "grid__item  one-whole text--center" }
    when "source_contact_id"
      f.action :submit, as: :input,  label: 'Reply Contact' , button_html: { :class => "btn " }, wrapper_html: { class: "grid__item  one-whole text--center" }
    else
      f.action :submit, as: :input,  label: 'Submit' , button_html: { :class => "btn " }, wrapper_html: { class: "grid__item  one-whole text--center" }
    end
  end

  def reply_message_email
    case
    when params.has_key?(:source_feedback_id)
      content_tag :li, class: "grid__item  one-whole  palm-one-whole push--bottom" do
        label_tag 'To Email'
        text_field_tag 'email', "#{@respond_to_feedback.email_address}", :class => "text-input", readonly: true
      end
    when params.has_key?(:source_contact_id)
      content_tag :li, class: "grid__item  one-whole  palm-one-whole push--bottom" do
        label_tag 'To Email'
        text_field_tag 'email', "#{@respond_to_contact.email_address}", :class => "text-input", readonly: true
      end
    end
  end

  def message_subject
    case
    when !@respond_to_feedback.nil?
      text_field_tag 'message[subject]', "Re: Thank you for your feedback. Reference #{@respond_to_feedback.identifier}", :class => "text-input", readonly: true, title: "Re: Thank you for your feedback. Reference #{@respond_to_feedback.identifier}"
    when !@respond_to_contact.nil?
      text_field_tag 'message[subject]', contact_subject(@respond_to_contact), :class => "text-input", readonly: true, title: contact_subject(@respond_to_contact)
    when !@respond_to_message.nil?
      text_field_tag 'message[subject]', "Re: #{@respond_to_message.subject}", :class => "text-input", readonly: true
    when @message.subject.nil? && @respond_to_message.nil? && @respond_to_feedback.nil?
      text_field_tag 'message[subject]', nil, :class => "text-input", placeholder: "Mandatory", required: true
    when @message.subject.present? && @respond_to_message.nil? && @respond_to_feedback.nil?
      text_field_tag 'message[subject]', "#{@message.subject}", :class => "text-input"
    end
  end

  def index_header(action)
    case action
    when "list_feedback_reply_message"
      header = "List of Feedback Reply messages"
    when "feedback_reply_messages"
      header = "List of Reply Message for feedback sent by #{@feedback.name}, reference: #{@feedback.identifier}"
    when "list_contact_reply_message"
      header = "List of Contact Reply messages"
    when "contact_reply_messages"
      header = "List of Reply Message for contact sent by #{@contact.name}, reference: #{@contact.identifier}"
    else
      header = "List of all messages"
    end
    return header
  end

  def contact_subject(contact)
    if contact_subject_hash.has_key?(contact.contact_type)
       subject = contact_subject_hash[contact.contact_type]
    else
      subject = contact_subject_hash['General Comment']
    end
    return "#{subject}.Reference #{contact.identifier}"
  end

  private
  def primary_links(link_1,link_2)
    capture do
      concat link_1
      concat " "
      concat link_2
      concat " "
      concat dynamic_link("View #{pluralize(@sent_replies.count, 'Reply') }", show_reply_messages_path(@message.id)) unless @sent_replies.count == 0
    end
  end

  def default_links
    [dynamic_link('Send this Message', send_message_messages_path(@message.id), data: { confirm: 'Are you sure you want to send this message'}, method: :get),
    dynamic_link('Edit this Message', edit_message_path(@message.id), method: :get)]
  end

  def dynamic_link(name,path, options={})
    link_to(name, path, class: "btn weight--light  btn--small", **options)
  end

  def contact_subject_hash
    {
      'Website Problem' => "RE: Thank you for reporting a website problem",
      'Data Question' => "RE: Thank you for your data question",
      'Data Problem' => "RE: Thank you for reporting a problem with our data",
      'Volunteering Question' => "RE: Thank you for question about volunteering",
      'General Comment' => "RE: Thank you for the general comment",
      'Thank-you' => "RE: Thank you for your compliments",
      'Genealogical Question' => "RE: Thank you for a genealogical question",
      'Enhancement Suggestion' => "RE: Thank you for the suggested enhancement"
    }
  end
end



    
    
    
