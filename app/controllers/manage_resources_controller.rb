class ManageResourcesController < ApplicationController
  require "county"
  require 'userid_role'
  skip_before_filter :require_login, only: [:index,:new]

  def create
    @user = UseridDetail.where(:userid => params[:manage_resource][:userid] ).first
    session[:userid] = @user.userid
    session[:first_name] = @user.person_forename
    session[:manager] = manager?(@user)
    redirect_to manage_resource_path(@user)
  end

  def index
    redirect_to :new
  end

  def load(userid_id)
    @first_name = session[:first_name]
    @user = UseridDetail.find(userid_id)
  end

  def new
    clean_session
    clean_session_for_syndicate
    clean_session_for_county
    get_userid_from_current_authentication_devise_user
    # the applications controller has set the administration cookie to ensure that this is processed on the master server
    #we do not accept
    unless  @user.active
      flash[:notice] = "You are not active, if you believe this to be a mistake please contact your coordinator"
      redirect_to refinery.logout_path
      return
    end
    if @user.person_role == "researcher"  || @user.person_role == 'pending'
      flash[:notice] = "You are not currently permitted to access the system as your functions are still under development"
      redirect_to refinery.logout_path
    end

    #we set the mongo_config.yml member open flag. true is open. false is closed We do allow technical people in
    if !Rails.application.config.member_open
      unless @user.person_role == "system_administrator"  || @user.person_role == 'technical'
        flash[:notice] = "The system is presently undergoing maintenance and is unavailable"
        redirect_to refinery.logout_path
        return
      end
    end

    if @page = Refinery::Page.where(:slug => 'information-for-members').exists?
      @page = Refinery::Page.where(:slug => 'information-for-members').first.parts.first.body.html_safe
    else
      @page = ""
    end
    @manage_resources = ManageResource.new
    if @user.person_role == "computer"
      redirect_to new_transreg_user_path
      return
    end
  end

  def selection
    if UseridRole::OPTIONS_TRANSLATION.has_key?(params[:option])
      value = UseridRole::OPTIONS_TRANSLATION[params[:option]]
      redirect_to value
      return
    else
      flash[:notice] = 'Invalid option'
      redirect_to :back
      return
    end
  end

  def create

    @user = UseridDetail.where(:userid => params[:manage_resource][:userid] ).first
    session[:userid] = @user.userid
    session[:first_name] = @user.person_forename
    session[:manager] = manager?(@user)
    redirect_to manage_resource_path(@user)
  end

  def show
    load(params[:id])
  end

end
