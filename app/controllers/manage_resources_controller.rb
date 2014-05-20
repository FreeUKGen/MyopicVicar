class ManageResourcesController < ApplicationController
  require "county"
def index
    reset_session
    p 'testing'
    p current_refinery_user.username.inspect
    @user = UseridDetail.where(:userid => current_refinery_user.username).first
    @user = UseridDetail.where(:userid_lower_case => current_refinery_user.username).first if @user.nil?
    session[:initial_page] = request.original_url
    p @user
    unless  @user.nil?
    @manage_resources = ManageResource.new 
   
    session[:userid] = @user.userid
    session[:first_name] = @user.person_forename
    session[:manager] = false
    session[:manager] = true if (@user.person_role == 'system_administrator' || @user.person_role == 'country_coordinator'  || @user.person_role == 'county_coordinator'  || @user.person_role == 'volunteer_coordinator' || @user.person_role == 'syndicate_coordinator')
     redirect_to manage_resource_path(@user)
 else
    redirect_to '/', notice: "Pay attention to the road"
 end
end

def new
  @manage_resources = ManageResource.new  
end

def create
    reset_session
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

