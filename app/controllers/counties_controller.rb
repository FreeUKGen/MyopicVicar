class CountiesController < InheritedResources::Base
layout "places"
require 'county'

def index
     if session[:userid].nil?
      redirect_to '/', notice: "You are not authorised to use these facilities"
    end
	 @first_name = session[:first_name]
     @user = UseridDetail.where(:userid => session[:userid]).first
	 @counties = County.all.order_by(chapman_code: 1)

end

def new
	@first_name = session[:first_name]
	@county = County.new
	get_userids_and_transcribers
end

def edit
	load(params[:id])
	get_userids_and_transcribers
end

def create
    @county = County.new(params[:county])
	@county.save
 if @county.errors.any?
    
     flash[:notice] = "The addition of the County was unsuccsessful"
     render :action => 'edit'
     return
 else
 	flash[:notice] = "The addition of the County was succsessful"
 	 #Syndicate.change_userid_fields(params)
     redirect_to counties_path
 end
end

def update
	load(params[:id])
	 previous_county_coordinator = @county.county_coordinator
	 params[:county][:previous_county_coordinator] = previous_county_coordinator  unless @county.county_coordinator == params[:county][:county_coordinator]
	 @county.update_attributes(params[:county])
     if @county.errors.any?
      
       flash[:notice] = "The change to the county was unsuccsessful"
        render :action => 'edit'
        return
     else
 	   flash[:notice] = "The change to the county was succsessful"
 	
     redirect_to counties_path
     end
	
end

def show
	load(params[:id])
	person = UseridDetail.where(:userid => @county.county_coordinator).first
    @person = person.person_forename + ' ' + person.person_surname unless person.nil? 
    person = UseridDetail.where(:userid => @county.previous_county_coordinator).first
     @previous_person = person.person_forename + ' ' + person.person_surname unless person.nil? 
end

def load(id)
   @first_name = session[:first_name]
   @county = County.find(id)
end

def get_userids_and_transcribers
  @user = UseridDetail.where(:userid => session[:userid]).first
  
        @userids = UseridDetail.all.order_by(userid_lower_case: 1)
    
    @people =Array.new
    @userids.each do |ids|
    @people << ids.userid
    end
 end




end
