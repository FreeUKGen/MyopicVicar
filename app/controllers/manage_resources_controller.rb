class ManageResourcesController < ApplicationController
  require "county"
def index
   
     if current_refinery_user.nil?
      redirect_to '/', notice: "You are not authorised to use these facilities"
    end
    clean_session 
    @user = current_refinery_user.userid_detail
    session[:initial_page] = request.original_url
    @manage_resources = ManageResource.new 
    session[:userid] = @user.userid
    session[:first_name] = @user.person_forename
    session[:manager] = false
    session[:manager] = true if (@user.person_role == 'system_administrator' || @user.person_role == 'country_coordinator'  || @user.person_role == 'county_coordinator'  || @user.person_role == 'volunteer_coordinator' || @user.person_role == 'syndicate_coordinator')
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
    session[:manager] = false
    session[:manager] = true if (@user.person_role == 'system_administrator' || @user.person_role == 'country_coordinator'  || @user.person_role == 'county_coordinator'  || @user.person_role == 'volunteer_coordinator' || @user.person_role == 'syndicate_coordinator')
        
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

