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
class FeedbacksController < ApplicationController
  require 'reply_userid_role'

  def archive
    @feedback = Feedback.find(params[:id])
    redirect_back(fallback_location: feedbacks_path, notice: 'The feedback was not found') && return if @feedback.blank?

    @feedback.archive
    flash.notice = 'Feedback archived'
    flash.keep
    return_after_archive(params[:source], params[:id])
  end

  def convert_to_issue
    @feedback = Feedback.find(params[:id])
    redirect_back(fallback_location: feedbacks_path, notice: 'The feedback was not found') && return if @feedback.blank?

    if @feedback.github_issue_url.blank?
      @feedback.github_issue
      flash.notice = 'Issue created on Github.'
      redirect_to(feedback_path(@feedback.id)) && return
    else
      flash.notice = 'Issue had already been created on Github.'
      redirect_to(action: 'show') && return
    end
  end

  def create
    session[:return_to] ||= request.referer
    @feedback = Feedback.new(feedback_params)
    #eliminate any flash message as the conversion to bson fails
    session.delete(:flash)
    @feedback.session_data = session.to_hash
    @feedback.session_data['warden_user_authentication_devise_user_key_key'] = @feedback.session_data['warden.user.authentication_devise_user.key'][0].to_s.gsub(/\W/, '') if @feedback.session_data['warden.user.authentication_devise_user.key'].present?
    @feedback.session_data['warden_user_authentication_devise_user_key_value'] = @feedback.session_data['warden.user.authentication_devise_user.key'][1] if @feedback.session_data['warden.user.authentication_devise_user.key'].present?
    @feedback.session_data.delete('warden.user.authentication_devise_user.key') if @feedback.session_data['warden.user.authentication_devise_user.key'].present?
    @feedback.session_data['warden_user_authentication_devise_user_key_session'] = @feedback.session_data['warden.user.authentication_devise_user.session']
    @feedback.session_data.delete('warden.user.authentication_devise_user.session') if @feedback.session_data['warden.user.authentication_devise_user.session'].present?
    @feedback.session_id = session.to_hash['session_id']
    @feedback.save
    redirect_back(fallback_location: new_feedback_path, notice: 'There was a problem creating your feedback!') && return if @feedback.errors.any?

    flash.notice = 'Thank you for your feedback!'
    @feedback.communicate_initial_contact
    if session[:return_to].present?
      redirect_to session.delete(:return_to)
    else
      redirect_to action: 'new'
    end
  end

  def destroy
    @feedback = Feedback.find(params[:id])
    redirect_back(fallback_location: feedbacks_path, notice: 'The feedback was not found') && return if @feedback.blank?

    @feedback.delete
    flash.notice = 'Feedback destroyed'
    redirect_to action: 'index'
  end

  def edit
    session[:return_to] ||= request.referer
    @feedback = Feedback.find(params[:id])
    redirect_back(fallback_location: feedbacks_path, notice: 'The feedback was not found') && return if @feedback.blank?

    redirect_back(fallback_location: feedbacks_path, notice: 'Issue cannot be edited as it is already committed to GitHub. Please edit there') && return if @feedback.github_issue_url.present?

  end

  def feedback_reply_messages
    @feedback = Feedback.find(params[:id])
    redirect_back(fallback_location: feedbacks_path, notice: 'The feedback was not found') && return if @feedback.blank?

    get_user_info_from_userid
    @messages = Message.where(source_feedback_id: params[:id]).all
    @link = false
    render 'messages/index'
  end

  def force_destroy
    @feedback = Feedback.find(params[:id])
    redirect_back(fallback_location: feedbacks_path, notice: 'The feedback was not found') && return if @feedback.blank?

    delete_reply_messages(params[:id])
    @feedback.delete
    flash.notice = 'Feedback and all its replies are destroyed'
    redirect_to action: 'index'
  end

  def index
    session[:archived_contacts] = false
    session[:message_base] = 'feedback'
    params[:source] = 'original'
    get_user_info_from_userid
    order = 'feedback_time DESC'
    @feedbacks = Feedback.archived(session[:archived_contacts]).order_by(order)
    @archived = session[:archived_contacts]
  end

  def keep
    @feedback = Feedback.find(params[:id])
    redirect_back(fallback_location: feedbacks_path, notice: 'The feedback was not found') && return if @feedback.blank?

    session[:archived_contacts] = true
    @feedback.update_keep
    flash.notice = 'Feedback to be retained'
    flash.keep
    return_after_keep(params[:source], params[:id])
  end

  def list_archived
    session[:archived_contacts] = true
    session[:message_base] = 'feedback'
    params[:source] = 'original'
    get_user_info_from_userid
    order = 'feedback_time DESC'
    @feedbacks = Feedback.archived(session[:archived_contacts]).order_by(order)
    @archived = session[:archived_contacts]
    render :index
  end

  def list_by_date
    get_user_info_from_userid
    order = 'feedback_time ASC'
    @feedbacks = Feedback.archived(session[:archived_contacts]).order_by(order)
    @archived = session[:archived_contacts]
    render :index
  end

  def list_by_most_recent
    get_user_info_from_userid
    order = 'feedback_time DESC'
    @feedbacks = Feedback.archived(session[:archived_contacts]).order_by(order)
    @archived = session[:archived_contacts]
    render :index
  end

  def list_by_name
    get_user_info_from_userid
    order = 'name ASC'
    @feedbacks = Feedback.archived(session[:archived_contacts]).order_by(order)
    @archived = session[:archived_contacts]
    render :index
  end

  def list_by_type
    get_user_info_from_userid
    order = 'feedback_type ASC'
    @feedbacks = Feedback.archived(session[:archived_contacts]).order_by(order)
    @archived = session[:archived_contacts]
    render :index
  end

  def list_by_userid
    get_user_info_from_userid
    order = 'user_id ASC'
    @feedbacks = Feedback.archived(session[:archived_contacts]).order_by(order)
    @archived = session[:archived_contacts]
    render :index
  end

  def new
    session[:return_to] ||= request.referer
    get_user_info_from_userid
    @feedback = Feedback.new(new_params) if params[:source_feedback_id].blank?
    @message = Message.new
    @message.message_time = Time.now
    @message.userid = @user.userid
    @respond_to_feedback = Feedback.id(params[:source_feedback_id]).first
    @feedback_replies = Message.fetch_feedback_replies(params[:source_feedback_id])
  end

  def restore
    @feedback = Feedback.find(params[:id])
    redirect_back(fallback_location: feedbacks_path, notice: 'The feedback was not found') && return if @feedback.blank?

    get_user_info_from_userid
    @feedback.restore
    flash.notice = 'Feedback restored'
    flash.keep
    return_after_restore(params[:source], params[:id])
  end

  def return_after_archive(source, id)
    if source == 'show'
      redirect_to action: 'show', id: id
    else
      redirect_to action: 'index'
    end
  end

  def return_after_keep(source, id)
    if source == 'show'
      redirect_to action: 'show', id: id
    else
      redirect_to action: 'index'
    end
  end

  def return_after_restore(source, id)
    if source == 'show'
      redirect_to action: 'show', id: id
    else
      redirect_to action: 'index'
    end
  end

  def return_after_unkeep(source, id)
    if source == 'show'
      redirect_to action: 'show', id: id
    else
      redirect_to action: 'list_archived'
    end
  end

  def reply_feedback
    get_user_info_from_userid; return if performed?
    @respond_to_feedback = Feedback.find(params[:source_feedback_id])
    redirect_back(fallback_location: feedbacks_path, notice: 'The feedback was not found') && return if @respond_to_feedback.blank?

    get_user_info_from_userid
    @feedback_replies = Message.where(source_feedback_id: params[:source_feedback_id]).all
    @feedback_replies.each do |reply|
    end
    @message = Message.new
    @message.message_time = Time.now
    @message.userid = @user.userid
    @userids = array_of_userids
  end

  def select_by_identifier
    get_user_info_from_userid
    @options = {}
    order = 'identifier ASC'
    @feedbacks = Feedback.archived(session[:archived_contacts]).order_by(order).each do |contact|
      @options[contact.identifier] = contact.id
    end
    @feedback = Feedback.new
    @location = 'location.href= "/feedbacks/" + this.value'
    @prompt = 'Select Identifier'
    render '_form_for_selection'
  end

  def show
    #get_user_info_from_userid
    @feedback = Feedback.find(params[:id])
    redirect_back(fallback_location: feedbacks_path, notice: 'The feedback was not found') && return if @feedback.blank?

  end

  def unkeep
    @feedback = Feedback.find(params[:id])
    redirect_back(fallback_location: feedbacks_path, notice: 'The feedback was not found') && return if @feedback.blank?

    get_user_info_from_userid
    @feedback.update_unkeep
    flash.notice = 'Feedback no longer being kept'
    return_after_unkeep(params[:source], params[:id])
  end

  def update
    @feedback = Feedback.find(params[:id])
    redirect_back(fallback_location: feedbacks_path, notice: 'The feedback was not found') && return if @feedback.blank?

    proceed = @feedback.update_attributes(feedback_params)
    redirect_back(fallback_location: edit_feedback_path(@feedback), notice: 'The edit of the feedback failed') && return unless proceed

    redirect_to(action: 'show') && return if proceed
  end

  def userid_feedbacks
    get_user_info_from_userid
    @user.reload
    @feedbacks_without_reply = @user.userid_feedback_replies.keys.select do |feedback|
      @user.userid_feedback_replies[feedback].blank?
    end
    @feedbacks = Feedback.in(id: @feedbacks_without_reply)
  end

  def userid_feedbacks_with_replies
    get_user_info_from_userid
    @user.reload
    @feedbacks_with_reply = @user.userid_feedback_replies.keys.reject do |feedback|
      @user.userid_feedback_replies[feedback].blank?
    end
    @feedbacks = Feedback.in(id: @feedbacks_with_reply)
  end

  private

  def feedback_params
    params.require(:feedback).permit!
  end

  def new_params
    params.delete('utf8')
    params.delete('controller')
    params.delete('action')
    params.permit!
  end

  def delete_reply_messages(feedback_id)
    Message.where(source_feedback_id: feedback_id).destroy
  end
end
