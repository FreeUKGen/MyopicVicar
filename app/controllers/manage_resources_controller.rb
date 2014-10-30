class ManageResourcesController < ApplicationController
  require "county"
skip_before_filter :require_login, only: [:index]


def index
    clean_session 
    session[:initial_page] = request.original_url
    if current_refinery_user.nil?
     redirect_to refinery.logout_path
     return
    end
    @user = current_refinery_user.userid_detail
    @manage_resources = ManageResource.new 
    session[:userid] = @user.userid
    session[:first_name] = @user.person_forename
    session[:manager] = manager?(@user)  
    redirect_to manage_resource_path(@user)
end

def new
  @manage_resources = ManageResource.new  
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

