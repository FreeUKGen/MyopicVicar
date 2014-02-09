class ManageResourcesController < ApplicationController
  require "county"
def index
    reset_session
    @manage_resources = ManageResource.new  
    @coordinators = County.all.distinct(:county_coordinator)
end

def new
  @manage_resources = ManageResource.new  
end

def create
    reset_session
    
    session[:initial] = "yes"
    session[:userid] = params[:manage_resource][:userid] 
    @user = UseridDetail.where(:userid => session[:userid]).first
    session[:user] = @user
    session[:first_name] = @user.person_forename
    session[:manager] = false
    session[:manager] = true if (session[:user].person_role == 'system_administrator' || session[:user].person_role == 'country_coordinator'  || session[:user].person_role == 'county_coordinator'  || session[:user].person_role == 'volunteer_coordinator' || session[:user].person_role == 'syndicate_coordinator')
    p "create"
   p session
    redirect_to manage_resource_path(@user)
    
end

def show
    load(params[:id]) 
end

def load(userid_id)
   @first_name = session[:first_name]
   @user = UseridDetail.find(userid_id)
  
  end

def my_syndicates

  
end
end

