  class ManageResourcesController < ApplicationController
    require "county"
    require 'userid_role'
  skip_before_filter :require_login, only: [:index,:new]


  def index
      clean_session 
      session[:initial_page] = request.original_url
      if current_refinery_user.nil?
       redirect_to refinery.logout_path
       return
      end
     
  end

  def new
      unless current_refinery_user
        redirect_to refinery.login_path
        return
      end

      @user = current_refinery_user.userid_detail 
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
      clean_session
      session[:userid_lower_case] = params[:manage_resource][:userid] 
      @user = UseridDetail.where(:userid_lower_case => session[:userid_lower_case]).first
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

