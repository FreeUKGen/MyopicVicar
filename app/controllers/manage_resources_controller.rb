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
      @user = current_refinery_user.userid_detail
      @manage_resources = ManageResource.new 
      session[:userid] = @user.userid
      session[:first_name] = @user.person_forename
      session[:manager] = manager?(@user)  
      session[:role] = @user.person_role
      p session[:role]
      @roles = UseridRole::OPTIONS.fetch(session[:role])
      p @roles
      @location = 'location.href= "/manage_resources/selection?option=" + this.value'
      @prompt = 'Select Function'
      #redirect_to manage_resource_path(@user) 
  end

  def selection
    p "selecting"
    p params
    p params[:option]
    if UseridRole::OPTIONS_TRANSLATION.has_key?(params[:option])
      p "OK"
      value = UseridRole::OPTIONS_TRANSLATION[params[:option]]
      p value
      redirect_to value
      return
    else
      p "failure"
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

