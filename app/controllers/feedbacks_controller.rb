class FeedbacksController < ApplicationController
  require 'reply_userid_role'
  #skip_before_filter :require_login, only: [:new]
  def archive
    @feedback = Feedback.id(params[:id]).first
    if @feedback.present?
      @feedback.update_attribute(:archived, true)
       flash.notice = "Feedback archived"
      redirect_to :action => "list_archived" and return
    else
      go_back("feedback",params[:id])
    end
  end

  def convert_to_issue
    @feedback = Feedback.id(params[:id]).first
    if @feedback.present?
      if @feedback.github_issue_url.blank?
        @feedback.github_issue
        flash.notice = "Issue created on Github."
        redirect_to feedback_path(@feedback.id)
        return
      else
        flash.notice = "Issue has already been created on Github."
        redirect_to :action => "show"
        return
      end
    else
      go_back("feedback",params[:id])
    end
  end

  def create
    @feedback = Feedback.new(feedback_params)
    #eliminate any flash message as the conversion to bson fails
    session.delete(:flash)
    @feedback.session_data = session.to_hash
    @feedback.session_data["warden_user_authentication_devise_user_key_key"] = @feedback.session_data["warden.user.authentication_devise_user.key"][0].to_s.gsub(/\W/, "") unless @feedback.session_data["warden.user.authentication_devise_user.key"].blank?
    @feedback.session_data["warden_user_authentication_devise_user_key_value"] = @feedback.session_data["warden.user.authentication_devise_user.key"][1] unless @feedback.session_data["warden.user.authentication_devise_user.key"].blank?
    @feedback.session_data.delete("warden.user.authentication_devise_user.key") unless @feedback.session_data["warden.user.authentication_devise_user.key"].blank?
    @feedback.session_data["warden_user_authentication_devise_user_key_session"] = @feedback.session_data["warden.user.authentication_devise_user.session"]
    @feedback.session_data.delete("warden.user.authentication_devise_user.session") unless @feedback.session_data["warden.user.authentication_devise_user.session"].blank?
    @feedback.session_id = session.to_hash["session_id"]
    @feedback.save
    if @feedback.errors.any?
      flash.notice = "There was a problem reporting your feedback!"
      render :action => 'new'
      return
    end
    flash.notice = "Thank you for your feedback!"
    @feedback.communicate_initial_contact
    if session[:return_to].present?
      redirect_to session.delete(:return_to)
    else
      redirect_to :action => 'new'
    end
  end

  def destroy
    @feedback = Feedback.id(params[:id]).first
    if @feedback.present?
      @feedback.delete
      flash.notice = "Feedback destroyed"
      redirect_to :action => 'index'
      return
    else
      go_back("feedback",params[:id])
    end
  end

  def delete_reply_messages(feedback_id)
    Message.where(source_feedback_id: feedback_id).destroy
  end

  def edit
    session[:return_to] ||= request.referer
    @feedback = Feedback.id(params[:id]).first
    if @feedback.present?
      if @feedback.github_issue_url.present?
        flash[:notice] = "Issue cannot be edited as it is already committed to GitHub. Please edit there"
        redirect_to :action => 'show'
        return
      end
    else
      go_back("feedback",params[:id])
    end
  end

  def feedback_reply_messages
    p "messages controller"
    get_user_info_from_userid; return if performed?
    @feedback = Feedback.id(params[:id]).first
    if @feedback.present?
      @messages = Message.where(source_feedback_id: params[:id]).all
      @link = false
      render 'messages/index'
    end
  end


  def force_destroy
    @feedback = Feedback.id(params[:id]).first
    if @feedback.present? && @feedback.has_replies?(params[:id])
      delete_reply_messages(params[:id])
      @feedback.delete
      flash.notice = "Feedback and all its replies are destroyed"
      redirect_to :action => 'index'
      return
    else
      go_back("feedback",params[:id])
    end
  end

  def index
    session[:archived_contacts] = false
    get_user_info_from_userid
    order = "feedback_time DESC"
    @feedbacks = Feedback.archived(session[:archived_contacts]).order_by(order)
    @archived = session[:archived_contacts]
  end

  def list_archived
    session[:archived_contacts] = true
    get_user_info_from_userid
    order = "feedback_time DESC"
    @feedbacks = Feedback.archived(session[:archived_contacts]).order_by(order)
    @archived = session[:archived_contacts]
    render :index
  end

  def list_by_date
    get_user_info_from_userid
    order = "feedback_time ASC"
    @feedbacks = Feedback.archived(session[:archived_contacts]).order_by(order)
    @archived = session[:archived_contacts]
    render :index
  end
  
  def list_by_most_recent
    get_user_info_from_userid
    order = "feedback_time DESC"
    @feedbacks = Feedback.archived(session[:archived_contacts]).order_by(order)
    @archived = session[:archived_contacts]
    render :index
  end

  def list_by_identifier
    get_user_info_from_userid
    order = "identifier ASC"
    @feedbacks = Feedback.archived(session[:archived_contacts]).order_by(order)
    @archived = session[:archived_contacts]
    render :index
  end

  def list_by_name
    get_user_info_from_userid
    order = "name ASC"
    @feedbacks = Feedback.archived(session[:archived_contacts]).order_by(order)
    @archived = session[:archived_contacts]
    render :index
  end

  def list_by_type
    get_user_info_from_userid
    order = "feedback_type ASC"
    @feedbacks = Feedback.archived(session[:archived_contacts]).order_by(order)
    @archived = session[:archived_contacts]
    render :index
  end
  
  def list_by_userid
    get_user_info_from_userid
    order = "user_id ASC"
    @feedbacks = Feedback.archived(session[:archived_contacts]).order_by(order)
    @archived = session[:archived_contacts]
    render :index
  end
  
  def new
    session[:return_to] ||= request.referer
    get_user_info_from_userid
    @feedback = Feedback.new(new_params) if params[:source_feedback_id].nil?
    @message = Message.new
    @message.message_time = Time.now
    @message.userid = @user.userid
    @respond_to_feedback = Feedback.id(params[:source_feedback_id]).first
    @feedback_replies = Message.fetch_feedback_replies(params[:source_feedback_id])
  end

  def restore
    get_user_info_from_userid
    @feedback = Feedback.id(params[:id]).first
    if @feedback.present?
      @feedback.update_attribute(:archived, false)
       flash.notice = "Feedback restored"
      redirect_to :action => "index" and return
    else
      go_back("feedback",params[:id])
    end
  end
  
  def reply_feedback
    p "reply feedback ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,"
    get_user_info_from_userid; return if performed?
    @respond_to_feedback = Feedback.id(params[:source_feedback_id]).first
    @feedback_replies = Message.where(source_feedback_id: params[:source_feedback_id]).all
    @feedback_replies.each do |reply|
      p "replymmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm"
      p reply
      p reply.sent_messages
    end
    @message = Message.new
    @message.message_time = Time.now
    @message.userid = @user.userid
  end


  def select_by_identifier
    get_user_info_from_userid
    @options = Hash.new
    order = "identifier ASC"
    @feedbacks = Feedback.archived(session[:archived_contacts]).order_by(order).each do |contact|
      @options[contact.identifier] = contact.id
    end
    @feedback = Feedback.new
    @location = 'location.href= "/feedbacks/" + this.value'
    @prompt = 'Select Identifier'
    render '_form_for_selection'
  end



  def show
    get_user_info_from_userid
    @feedback = Feedback.id(params[:id]).first
    if @feedback.present?
      @feedback
    else
      go_back("feedback",params[:id])
    end
  end

  def update
    @feedback = Feedback.id(params[:id]).first
    if @feedback.present?
      @feedback.update_attributes(feedback_params)
      redirect_to :action => 'show'
      return
    else
      go_back("feedback",params[:id])
    end
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
end
