class FeedbacksController < ApplicationController

  skip_before_filter :require_login

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

    @feedback.session_data["warden.user.authentication_devise_user.key_key"] = @feedback.session_data["warden.user.authentication_devise_user.key"][0].to_s.gsub(/\W/, "")

    @feedback.session_data["warden.user.authentication_devise_user.key_value"] = @feedback.session_data["warden.user.authentication_devise_user.key"][1]
    @feedback.session_data.delete("warden.user.authentication_devise_user.key")
    p @feedback.session_data
    @feedback.session_id = session.to_hash["session_id"]
    @feedback.save
    if @feedback.errors.any?
      flash.notice = "There was a problem reporting your feedback!"
      render :action => 'new'
      return
    end
    flash.notice = "Thank you for your feedback!"
    @feedback.communicate
    redirect_to session.delete(:return_to)
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

  def index
    @feedbacks = Feedback.all.order_by(feedback_time: -1)
  end

  def list_by_date
    get_user_info_from_userid
    @feedbacks = Feedback.all.order_by(feedback_time: 1)
    render :index
  end

  def list_by_identifier
    get_user_info_from_userid
    @feedbacks = Feedback.all.order_by(identifier: -1)
    render :index
  end

  def list_by_name
    get_user_info_from_userid
    @feedbacks = Feedback.all.order_by(name: 1)
    render :index
  end

  def list_by_userid
    get_user_info_from_userid
    @feedbacks = Feedback.all.order_by(user_id: 1)
    render :index
  end

  def new
    session[:return_to] ||= request.referer
    get_user_info_from_userid
    @feedback = Feedback.new(new_params)
  end

  def select_by_identifier
    get_user_info_from_userid
    @options = Hash.new
    @feedbacks = Feedback.all.order_by(identifier: -1).each do |contact|
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
