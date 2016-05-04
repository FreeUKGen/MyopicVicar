  class ManageResourcesController < ApplicationController
    require "county"
    require 'userid_role'
  skip_before_filter :require_login, only: [:index,:new]
  def index
      clean_session 
      clean_session_for_syndicate
      clean_session_for_county
      session[:initial_page] = request.original_url
      if current_refinery_user.nil?
       redirect_to refinery.logout_path
       return
      end
     
  end

  def new
      clean_session 
      clean_session_for_syndicate
      clean_session_for_county
      session[:initial_page] = request.original_url
  # the applications controller has set the administration cookie to ensure that this is processed on the master server  
  #we do not accept  
      if current_refinery_user.nil? || current_refinery_user.userid_detail.nil? 
        flash[:notice] = "You are not currently registered with FreeReg "
        sign_out(current_refinery_user) unless current_refinery_user.nil?
        redirect_to refinery.login_path
        return
      end
      unless  current_refinery_user.userid_detail.active
      flash[:notice] = "You are not active, if you believe this to be a mistake please contact your coordinator"
       sign_out(current_refinery_user) unless current_refinery_user.nil?
       redirect_to refinery.login_path
       return
      end
      @user = current_refinery_user.userid_detail 
      if @user.person_role == "researcher"  || @user.person_role == 'pending' 
       flash[:notice] = "You are not currently permitted to access the system as your functions are still under development"
       sign_out(current_refinery_user) unless current_refinery_user.nil?
       redirect_to refinery.login_path
       return
      end
      #we set the mongo_config.yml member open flag. true is open. false is closed We do allow technical people in
      if !Rails.application.config.member_open
        unless @user.person_role == "system_administrator"  || @user.person_role == 'technical' 
          sign_out(current_refinery_user) unless current_refinery_user.nil?
          flash[:notice] = "The system is presently undergoing maintenance and is unavailable"
          redirect_to refinery.login_path
          return
        end
      end     

      if @page = Refinery::Page.where(:slug => 'information-for-members').exists?
       @page = Refinery::Page.where(:slug => 'information-for-members').first.parts.first.body.html_safe
      else
       @page = ""
      end
      @manage_resources = ManageResource.new 
      session[:userid] = @user.userid
      @first_name = @user.person_forename
      session[:first_name] = @user.person_forename
      session[:manager] = manager?(@user)  
      session[:role] = @user.person_role
      @roles = UseridRole::OPTIONS.fetch(session[:role])
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

  def load(userid_id)
     @first_name = session[:first_name]
     @user = UseridDetail.find(userid_id)
  end

  end

