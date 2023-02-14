# Copyright 2012 Trustees of FreeBMD
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
#
class MessagesController < ApplicationController
  # Looks after the management of messages sent between members of the organization
  require 'freereg_options_constants'
  require 'userid_role'
  require 'reply_userid_role'

  def archive
    @message = Message.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The message was not found') && return if @message.blank?

    @message.archive
    session[:archived_contacts] = true
    flash.notice = 'Message archived'
    return_after_archive(params[:source], params[:id], params[:action])
  end

  def communications
    get_user_info_from_userid
    session[:message_base] = 'communication'
    session[:archived_contacts] = false
    session.delete(:original_message_id)
    session.delete(:message_id)
    order = 'message_time DESC'
    @messages = Message.list_communications(params[:action], session[:archived_contacts], order, @user.userid)
    render :index
  end

  def create
    @message = Message.new(message_params)
    @message.file_name = @message.attachment_identifier
    case params[:commit]
    when 'Save Message' # applies to both general and syndicate messages
      create_for_submit
    when 'Save & Send'
      create_for_submit_and_send
    when 'Reply Feedback'
      create_for_feedback_reply
    when 'Feedback Comment'
      create_for_feedback_comment
    when 'Reply Contact'
      create_for_contact_reply
    when 'Contact Comment'
      create_for_contact_comment
    when 'Reply Message'
      create_for_message_reply
    when 'Message Comment'
      create_for_message_comment
    when 'Save Communication'
      create_for_communication
    when 'Reply Communication'
      create_for_communication_reply
    when 'Communication Comment'
      create_for_communication_comment
    end
  end

  def create_for_communication
    @message.nature = 'communication'
    if @message.subject.blank?
      @message.subject = '...'
      flash[:notice] = 'There was no subject for your communication. You will have to reattach any file or image'
      render :new
    elsif @message.save
      flash[:notice] = 'Communication saved'
      redirect_to action: 'communications'
    else
      flash[:notice] = 'There was a problem with your communication, possibly you attached a file with an incorrect file type or an image as a file'
      redirect_to action: :new
    end
  end

  def create_for_communication_comment
    get_user_info_from_userid
    @message.nature = 'communication'
    original_message = Message.id(@message.source_message_id).first
    @sent_message = SentMessage.new(message_id: @message.id, sender: @user.userid, recipients: ['comment_only'], sent_time: Time.now)
    @message.sent_messages << [@sent_message]
    @sent_message.save
    @message.save
    redirect_back(fallback_location: message_path(original_message), notice: "The message was not created #{@message.errors.full_messages}") && return if @message.errors.any?

    flash[:notice] = 'Message created'
    redirect_to(show_reply_message_path(original_message), source: params[:source]) && return
  end

  def create_for_communication_reply
    get_user_info_from_userid
    @message.nature = 'communication'
    @message.save
    redirect_back(fallback_location: new_manage_resource_path, notice: "The message was not created #{@message.errors.full_messages}") && return if @message.errors.any?

    flash[:notice] = 'Message created'
    reply_for_communication(@message); return if performed?
  end

  def create_for_contact_comment
    @message.nature = 'contact'
    @contact = Contact.id(@message.source_contact_id).first
    @message.save
    redirect_back(fallback_location: contact_path(@contact), notice: "The message was not created #{@message.errors.full_messages}") && return if @message.errors.any?

    flash[:notice] = 'Contact comment was saved'
    flash.keep
    redirect_to(contact_path(@contact)) && return
  end

  def create_for_contact_reply
    @message.nature = 'contact'
    @message.save
    redirect_back(fallback_location: message_path(@message), notice: "The message was not created #{@message.errors.full_messages}") && return if @message.errors.any?

    flash[:notice] = 'Reply for Contact was created and sent'
    flash.keep
    reply_for_contact; return if performed?
  end

  def create_for_feedback_comment
    @message.nature = 'feedback'
    @feedback = Feedback.id(@message.source_feedback_id).first
    @message.save
    redirect_back(fallback_location: feedback_path(@feedback), notice: "The message was not created #{@message.errors.full_messages}") && return if @message.errors.any?

    flash[:notice] = 'Feedback comment was saved'
    flash.keep
    redirect_to(feedback_path(@feedback)) && return
  end

  def create_for_feedback_reply
    @message.nature = 'feedback'
    @message.save
    redirect_back(fallback_location: message_path(@message), notice: "The message was not created #{@message.errors.full_messages}") && return if @message.errors.any?

    flash[:notice] = 'Reply for Feedback was created and sent'
    flash.keep
    reply_for_feedback; return if performed?
  end

  def create_for_message_comment
    get_user_info_from_userid
    original_message = Message.id(@message.source_message_id).first
    @message.syndicate = original_message.syndicate
    @message.nature = original_message.nature
    @sent_message = SentMessage.new(message_id: @message.id, sender: @user.userid, recipients: ['comment_only'], sent_time: Time.now)
    @message.sent_messages << [@sent_message]
    @sent_message.save
    @message.save
    redirect_back(fallback_location: message_path(original_message), notice: "The message was not created #{@message.errors.full_messages}") && return if @message.errors.any?

    flash[:notice] = 'Message comment was saved'
    flash.keep
    redirect_to(show_reply_message_path(original_message)) && return
  end

  def create_for_message_reply
    get_user_info_from_userid
    original_message = Message.find(@message.source_message_id)
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The message was not found') && return if original_message.blank?

    @message.syndicate = original_message.syndicate
    @message.nature = original_message.nature
    @message.save
    redirect_back(fallback_location: message_path(original_message), notice: "The message was not created #{@message.errors.full_messages}") && return if @message.errors.any?

    flash[:notice] = 'Reply for Message was created and sent'
    flash.keep
    reply_for_message(@message); return if performed?
  end

  def create_for_submit
    if session[:syndicate].present?
      @message.syndicate = session[:syndicate]
      @message.nature = 'syndicate'
    else
      @message.syndicate = nil
      @message.nature = 'general'
    end
    if @message.subject.blank?
      @message.subject = '...'
      flash[:notice] = 'There was no subject for your message. You will have to reattach any file or image'
      render :new
    elsif @message.save
      flash[:notice] = 'Message created'
      return_for_create
    else
      flash[:notice] = 'There was a problem with your message, possibly you attached a file with an incorrect file type or an image as a file'
      flash.keep
      redirect_to action: :new
    end
  end

  def create_for_submit_and_send
    if @message.save
      flash[:notice] = 'Reply created'
      params[:id] = @message.id if @message
      send_message
    else
      flash[:notice] = 'Reply not created'
      flash.keep
      redirect_to(reply_messages_path(@message.source_message_id)) && return
    end
  end

  def force_destroy
    @message = Message.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The message was not found') && return if @message.blank?

    @message.destroy
    flash.notice = 'Message destroyed'
    return_after_destroy
  end

  def edit
    @message = Message.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The message was not found') && return if @message.blank?
  end

  def index
    get_user_info_from_userid
    session[:message_base] = 'general'
    session[:archived_contacts] = false
    session.delete(:original_message_id)
    session.delete(:message_id)
    params[:source] = 'original'
    @syndicate = session[:syndicate]
    order = 'message_time DESC'
    @messages = Message.list_messages(params[:action], @syndicate, session[:archived_contacts], order)
  end

  def keep
    @message = Message.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The message was not found') && return if @message.blank?

    session[:archived_contacts] = true
    @message.update_keep
    flash.notice = 'Message to be retained'
    return_after_keep(params[:source], params[:id])
  end

  def list_active_communications
    get_user_info_from_userid
    session[:message_base] = 'communication'
    params[:source] = 'original'
    session[:archived_contacts] = false
    session.delete(:original_message_id)
    session.delete(:message_id)
    order = 'message_time DESC'
    @messages = Message.list_communications(params[:action], session[:archived_contacts], order, @user.userid)
    render :index
  end

  def list_archived_communications
    get_user_info_from_userid
    session[:message_base] = 'communication'
    params[:source] = 'original'
    session[:archived_contacts] = true
    session.delete(:original_message_id)
    session.delete(:message_id)
    order = 'message_time DESC'
    @messages = Message.list_communications(params[:action], session[:archived_contacts], order, @user.userid)
    render :index
  end

  def list_archived
    get_user_info_from_userid
    session[:message_base] = 'general'
    params[:source] = 'original'
    session[:archived_contacts] = true
    @syndicate = session[:syndicate]
    session.delete(:original_message_id)
    session.delete(:message_id)
    order = 'message_time DESC'
    @messages = Message.list_messages(params[:action], @syndicate, session[:archived_contacts], order)
    render :index
  end

  def list_by_name
    get_user_info_from_userid
    @syndicate = session[:syndicate]
    order = 'name ASC'
    @messages = Message.list_messages(params[:action],session[:syndicate],session[:archived_contacts],order)
    render :index
  end

  def list_feedback_reply_message
    get_user_info_from_userid
    order = 'message_time DESC'
    @messages = Message.list_messages(params[:action],session[:syndicate],session[:archived_contacts],order)
    render :index
  end

  def list_contact_reply_message
    get_user_info_from_userid
    order = 'message_time DESC'
    @messages = Message.list_messages(params[:action],session[:syndicate],session[:archived_contacts],order)
    render :index
  end

  def list_by_date
    get_user_info_from_userid
    @syndicate = session[:syndicate]
    order = 'message_time ASC'
    @messages = Message.list_messages(params[:action], session[:syndicate], session[:archived_contacts], order)
    render :index
  end

  def list_by_most_recent
    get_user_info_from_userid
    @syndicate = session[:syndicate]
    order = 'message_time DESC'
    @messages = Message.list_messages(params[:action], session[:syndicate], session[:archived_contacts], order)
    render :index
  end

  def list_syndicate_messages
    get_user_info_from_userid
    session[:archived_contacts] = false
    session[:message_base] = 'syndicate'
    params[:source] = 'original'
    session.delete(:original_message_id)
    session.delete(:message_id)
    @syndicate = session[:syndicate]
    order = 'message_time DESC'
    @messages = Message.list_messages(params[:action], session[:syndicate], session[:archived_contacts], order)
    render :index
  end

  def list_archived_syndicate_messages
    get_user_info_from_userid
    session[:archived_contacts] = true
    session[:message_base] = 'syndicate'
    params[:source] = 'original'
    session.delete(:original_message_id)
    session.delete(:message_id)
    @syndicate = session[:syndicate]
    order = 'message_time DESC'
    @messages = Message.list_messages(params[:action], session[:syndicate], session[:archived_contacts], order)
    render :index
  end

  def list_unsent_messages
    get_user_info_from_userid
    @syndicate = session[:syndicate]
    order = 'message_time DESC'
    @messages = Message.list_messages(params[:action], session[:syndicate], session[:archived_contacts], order)
    render :index
  end

  def new
    get_user_info_from_userid
    session[:hold_source] = params[:source]
    if params[:id].present?
      # reply
      @respond_to_message = Message.find(params[:id])
      redirect_back(fallback_location: new_manage_resource_path, notice: 'The message was not found') && return if @respond_to_message.blank?

      get_user_info_from_userid
      @reply_messages = Message.fetch_replies(params[:id])
      @sent_replies = Message.sent_messages(@reply_messages)
      @message = Message.new(nature: @respond_to_message.nature, syndicate: @respond_to_message.syndicate,
                             userid: @user.userid, message_time: Time.now)
      @userids = array_of_userids
    else
      # create
      session[:message_base] == 'syndicate' ? syndicate = session[:syndicate] : syndicate = nil
      @message = Message.new(nature: session[:message_base], syndicate: syndicate,
                             userid: @user.userid, message_time: Time.now)
    end
  end

  def remove_from_userid_detail
    get_user_info_from_userid
    @user.remove_checked_messages(params[:id])
    flash[:notice] = 'Message removed'
    if @user.userid_messages.length > 0
      redirect_to userid_messages_path
    else
      redirect_to new_manage_resource_path
    end
  end

  def reply_for_contact
    sender = UseridDetail.where(userid: @message.userid).first
    @contact = Contact.find(@message.source_contact_id)
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The message was not found') && return if sender.blank? || @contact.blank?

    @contact.communicate_contact_reply(@message, sender.userid)
    @message.add_message_to_userid_messages(sender)
    @contact.add_message_to_userid_messages_for_contact(@message)
    redirect_to(contact_path(@contact)) && return
  end

  def reply_for_feedback
    sender = UseridDetail.where(userid: @message.userid).first
    @feedback = Feedback.find(@message.source_feedback_id)
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The message was not found') && return if sender.blank? || @feedback.blank?

    @feedback.communicate_feedback_reply(@message, sender.userid)
    @message.add_message_to_userid_messages(sender)
    @feedback.add_message_to_userid_messages_for_contact(@message)
    redirect_to(feedback_path(@feedback)) && return
  end

  def reply_for_message(reply)
    original_message = Message.find(reply.source_message_id)
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The message was not found') && return if original_message.blank?

    reply.communicate_message_reply(original_message)
    flash[:notice] = 'Reply for Message was created and sent'
    params[:source] = 'reply'
    redirect_to(show_reply_message_path(reply.id, source: 'reply')) && return
  end

  def reply_for_communication(reply)
    original_message = Message.find(reply.source_message_id)
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The message was not found') && return if original_message.blank?

    reply.communicate_message_reply(original_message)
    flash[:notice] = 'Reply for Communication was created and sent'
    params[:source] = 'reply' #
    #  redirect_to message_path(reply.id, source: source) and return
    redirect_to(show_reply_message_path(reply.id, source: params[:source])) && return
  end

  def reply_messages
    get_user_info_from_userid
    @user.reload
    session[:original_message_id] = params[:id] if params[:source] == 'original'
    params[:source] = 'reply'
    @user_messages = UseridDetail.id(@user.id).first.userid_messages
    @reply_messages = Message.fetch_replies(params[:id])
    @messages = Message.sent_messages(@reply_messages)
    @main_message = Message.id(params[:id]).first
  end

  def return_for_create
    case session[:message_base]
    when 'userid_messages'
      redirect_to action: 'userid_messages'
    when 'syndicate'
      redirect_to action: 'list_syndicate_messages'
    when 'general'
      redirect_to action: 'index'
    when 'communication'
      redirect_to action: 'communications'
    end
  end

  def return_after_archive(source, id, action)
    case session[:message_base]
    when 'userid_messages'
      redirect_to action: 'userid_messages', source: source
    when 'syndicate'
      redirect_to action: 'list_syndicate_messages', source: source
    when 'general'
      redirect_to action: 'index', source: source
    when 'communication'
      redirect_to action: 'communications', source: source
    end
  end

  def return_after_destroy
    if @message.source_feedback_id.present?
      redirect_to list_feedback_reply_message_path
    elsif @message.source_contact_id.present?
      redirect_to list_contact_reply_message_path
    elsif @message.source_message_id.present?
      redirect_to show_reply_messages_path
    elsif session[:message_base] == 'syndicate'
      redirect_to list_syndicate_messages_path
    elsif session[:message_base] == 'general'
      redirect_to action: 'index'
    elsif session[:message_base] == 'communication'
      redirect_to action: 'communications'
    end
  end

  def return_after_keep(source, id)
    case session[:message_base]
    when 'userid_messages'
      redirect_to action: 'userid_messages', source: source
    when 'syndicate'
      redirect_to action: 'list_syndicate_messages', source: source
    when 'general'
      redirect_to action: 'index', source: source
    when 'communication'
      redirect_to action: 'communications', source: source
    end
  end

  def return_after_restore(source, id)
    case session[:message_base]
    when 'userid_messages'
      redirect_to action: 'userid_messages', source: source
    when 'syndicate'
      redirect_to action: 'list_syndicate_messages', source: source
    when 'general'
      redirect_to action: 'index', source: source
    when 'communication'
      redirect_to action: 'communications', source: source
    end
  end

  def return_after_unkeep(source, id)
    case session[:message_base]
    when 'userid_messages'
      redirect_to action: 'userid_messages', source: source
    when 'syndicate'
      redirect_to action: 'list_syndicate_messages', source: source
    when 'general'
      redirect_to action: 'index', source: source
    when 'communication'
      redirect_to action: 'communications', source: source
    end
  end

  def restore
    @message = Message.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The message was not found') && return if @message.blank?

    @message.restore
    session[:archived_contacts] = false
    flash.notice = 'Message restored'
    return_after_restore(params[:source], params[:id])
  end

  def select_by_identifier
    get_user_info_from_userid
    @options = {}
    order = 'identifier ASC'
    @messages = Message.list_messages(params[:action],session[:syndicate],session[:archived_contacts],order)
    @messages.each do |message|
      @options[message.identifier] = message.id
    end
    @message = Message.new
    @location = 'location.href= "/messages/" + this.value'
    @prompt = 'Select Identifier'
    render '_form_for_selection'
  end

  def select_individual
    @message = Message.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The message was not found') && return if @message.blank?

    session[:com_role] = params[:role]
    @people = @message.select_the_list_of_individuals(params[:role])
    redirect_to(select_role_message_path(@message.id, source: params[:action]), notice: 'There is no one associated with that role') && return if @people.blank?
  end

  def select_recipients
    @message = Message.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The message was not found') && return if @message.blank?

    get_user_info_from_userid
    @sent_message = SentMessage.new(message_id: @message.id, sender: @user_userid, inactive_reason: ['temporary'])
    @message.sent_messages << [@sent_message]
    session[:sent_message_id] = @sent_message.id
    @options = UseridRole::VALUES
    @inactive_reason = []
    UseridRole::REASONS_FOR_INACTIVATING.each_pair do |key, value|
      @inactive_reason << value
    end
    @open_data_status = SentMessage::ALL_STATUS_MESSAGES
    @senders = []
    if @syndicate.present?
      @senders << @user.userid
      @senders << Syndicate.syndicate_code(@syndicate).first.syndicate_coordinator if Syndicate.is_syndicate(@syndicate)
    else
      UseridDetail.active(true).all.order_by(userid_lower_case: 1).each do |sender|
        @senders << sender.userid
      end
    end
    render 'select_recipients'
  end

  def select_role
    @message = Message.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The message was not found') && return if @message.blank?

    get_user_info_from_userid
    @options = FreeregOptionsConstants::COMMUNICATION_ROLES
    @prompt = 'Select Role?'
  end

  def send_communication
    get_user_info_from_userid
    acutal_recipients = @message.extract_actual_recipients(params[:recipients], session[:com_role])
    session.delete(:com_role)
    @sent_message = SentMessage.new(message_id: @message.id, sender: @user_userid, recipients: acutal_recipients)
    @message.sent_messages << [@sent_message]
    @sent_message.save
    UserMailer.send_message(@message, acutal_recipients, @user_userid, session[:host]).deliver_now
    @sent_message.update_attributes(sent_time: Time.now)
    @message.add_message_to_userid_messages(UseridDetail.look_up_id(@user_userid)) unless @user_userid.blank?
    acutal_recipients.each do |recipient|
      @message.add_message_to_userid_messages(UseridDetail.look_up_id(recipient))
    end
    flash[:notice] = 'Communication Sent'
  end

  def send_message
    @message = Message.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The message was not found') && return if @message.blank?

    get_user_info_from_userid
    if session[:syndicate].present?
      params[:recipients] = Array.new
      params[:recipients] << 'Members of Syndicate'
      @syndicate = session[:syndicate]
    end
    if params[:recipients].blank?
      flash[:notice] = 'You did not select any recipients'
      redirect_to(action: 'select_recipients') && return
    else
      sender = params[:sender]
      reasons = []
      @sent_message = @message.sent_messages.id(session[:sent_message_id]).first
      @sent_message.save
      session.delete(:sent_message_id)
      reasons = params[:inactive_reason] if !params[:active]
      @sent_message.update_attributes(recipients: params[:recipients], active: params[:active], inactive_reason: reasons, sender: sender, open_data_status: params[:open_data_status], syndicate: @syndicate)
      @message.communicate(params[:recipients],  params[:active], reasons, sender, params[:open_data_status], @syndicate, session[:host])
      @sent_message.update_attributes(sent_time: Time.now)
      @message.update_attributes(message_sent_time: Time.now)
      flash[:notice] = @message.reciever_notice(params)
    end
  end

  def send_contact_message
    get_user_info_from_userid
    if @message.present?
      @sent_message = SentMessage.new(:message_id => @message.id,:sender => @user_userid, recipients: [params[:email]])
      @message.sent_messages << [@sent_message]
      @sent_message.save
    end
  end

  def show
    @message = Message.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The message was not found') && return if @message.blank?

    get_user_info_from_userid
    @user.reload
    session[:message_id] = @message.id if @message.present?
    session[:original_message_id] = @message.id if params[:source] == 'original'
    @reply_messages = Message.fetch_replies(params[:id])
    @sent_replies = Message.sent_messages(@reply_messages)
    @sent = @message.sent_messages.order_by(sent_time: 1) unless @message.sent_messages.blank?
  end

  def show_reply_message
    @message = Message.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The message was not found') && return if @message.blank?

    get_user_info_from_userid
    @user.reload
    @reply_messages = Message.fetch_replies(params[:id])
    @sent_replies = Message.sent_messages(@reply_messages)
    @sent = @message.sent_messages.order_by(sent_time: 1) unless @message.sent_messages.blank?
    render 'show'
  end

  def unkeep
    @message = Message.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The message was not found') && return if @message.blank?

    get_user_info_from_userid
    @message.update_unkeep
    flash.notice = 'Message no longer being kept'
    return_after_unkeep(params[:source], params[:id])
  end

  def user_reply_messages
    @main_message = Message.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The message was not found') && return if @main_message.blank?

    get_user_info_from_userid
    @user.reload
    @reply_messages = Message.fetch_replies(params[:id])
    @user_replies = @reply_messages.where(userid: @user.userid).all
    @messages = Message.sent_messages(@user_replies)
  end

  def userid_reply_messages
    get_user_info_from_userid
    @user.reload
    @reply_messages = Message.fetch_replies(params[:id])
    @reply_messages = Message.sent_messages(@reply_messages)
    session[:syndicate].blank? ? @messages = @reply_messages : @messages = syndicate_messages(@reply_messages, session[:syndicate])
  end

  def userid_messages
    session[:message_base] = 'userid_messages'
    params[:source] = 'original'
    get_user_info_from_userid
    @user.reload
    session[:manager] = @manager
    @main_messages = Message.in(id: @user.userid_messages).all.order_by(message_time: -1)
    session[:syndicate].blank? ? @messages = @main_messages : @messages = syndicate_messages(@main_messages, session[:syndicate])
  end

  def update
    @message = Message.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The message was not found') && return if @message.blank?

    case params[:commit]
    when 'Save'
      @message.update_attributes(message_params)
    when 'Select Role'
      redirect_to action: 'select_individual', id: params[:id], role: params[:message][:action]
      return
    when 'Send Communication'
      send_communication
    else
      send_message
    end
    redirect_to message_path(@message.id, source: 'original')
  end

  private

  def message_params
    params.require(:message).permit!
  end

  def syndicate_messages(messages, syndicate)
    syndicate_messages = messages.reject do |msg|
      msg.sent_messages.syndicate_messages(syndicate).blank?
    end
    messages = syndicate_messages
    messages
  end
end
