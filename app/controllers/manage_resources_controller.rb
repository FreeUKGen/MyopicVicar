class ManageResourcesController < ApplicationController
  require "county"
def index
    reset_session
    @manage_resources = ManageResource.new  
     @people =Array.new
    people = UseridDetail.where(:person_role => 'transcriber', :number_of_files.gt => 10, :number_of_records.gt => 1000).first
    @people << people.userid_lower_case unless people.nil?
    people = UseridDetail.where(:person_role => 'researcher').first
    @people << people.userid_lower_case unless people.nil?
    people = County.all.distinct(:county_coordinator_lower_case)
   
    people.each do |mine|
    @people << mine  unless @people.include?(mine) 
    end 
    people = Syndicate.all.distinct(:syndicate_coordinator_lower_case)
    people.each do |mine|
    @people << mine unless @people.include?(mine) 
    end 
    people = Country.all.distinct(:country_coordinator_lower_case)
    people.each do |mine|
    @people << mine unless @people.include?(mine) 
    end 
    @people = @people.sort
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

