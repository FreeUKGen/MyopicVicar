class SyndicatesController < ApplicationController
layout "places"

def index
	 @first_name = session[:first_name]
      @user = UseridDetail.where(:userid => session[:userid]).first
	 @syndicates = Syndicate.all.order_by(syndicate_code: 1)

end

def new
	@first_name = session[:first_name]
	@syndicate = Syndicate.new
	get_userids_and_transcribers
end

def edit
	load(params[:id])
	get_userids_and_transcribers
end

def create
    @syndicate = Syndicate.new(params[:syndicate])
	@syndicate.save
 if @syndicate.errors.any?
     session[:errors] = @syndicate.errors.messages
     flash[:notice] = "The addition of the Syndciate was unsuccsessful"
     render :action => 'edit'
     return
 else
 	flash[:notice] = "The addition of the Syndicate was succsessful"
 	 #Syndicate.change_userid_fields(params)
     redirect_to syndicates_path
 end
end

def update
	 load(params[:id])
	 previous_syndicate_coordinator = @syndicate.syndicate_coordinator
	 params[:syndicate][:previous_syndicate_coordinator] = previous_syndicate_coordinator  unless @syndicate.syndicate_coordinator == params[:syndicate][:syndicate_coordinator]
	 @syndicate.update_attributes(params[:syndicate])
if @syndicate.errors.any?
     session[:errors] = @syndicate.errors.messages
     flash[:notice] = "The change to the Syndicate was unsuccsessful"
     render :action => 'edit'
     return
 else
 	flash[:notice] = "The change to the Syndicate was succsessful"
 	
     redirect_to syndicates_path
 end
	
end

def show
	load(params[:id])
	person = UseridDetail.where(:userid => @syndicate.syndicate_coordinator).first
    @person = person.person_forename + ' ' + person.person_surname unless person.nil? 
    person = UseridDetail.where(:userid => @syndicate.previous_syndicate_coordinator).first
     @previous_person = person.person_forename + ' ' + person.person_surname unless person.nil? 
end

def load(id)
   @first_name = session[:first_name]
   @syndicate = Syndicate.find(id)
end

def get_userids_and_transcribers
  @user = UseridDetail.where(:userid => session[:userid]).first
  case
    when @user.person_role == 'system_administrator' ||  @user.person_role == 'volunteer_coordinator'
        @userids = UseridDetail.all.order_by(userid_lower_case: 1)
    when  @user.person_role == 'country_cordinator'
        @userids = UseridDetail.where(:syndicate => @user.syndicate ).all.order_by(userid_lower_case: 1) # need to add ability for more than one county
    when  @user.person_role == 'county_coordinator'  
        @userids = UseridDetail.where(:syndicate => @user.syndicate ).all.order_by(userid_lower_case: 1) # need to add ability for more than one syndicate  
    when  @user.person_role == 'sydicate_coordinator'  
        @userids = UseridDetail.where(:syndicate => @user.syndicate ).all.order_by(userid_lower_case: 1) # need to add ability for more than one syndicate  
    else
    @userids = @user
    end #end case
    @people =Array.new
    @userids.each do |ids|
    @people << ids.userid
    end
 end
end

