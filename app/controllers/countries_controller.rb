class CountriesController < InheritedResources::Base


def index
      if session[:userid].nil?
      redirect_to '/', notice: "You are not authorised to use these facilities"
    end
  

	 @first_name = session[:first_name]
   @user = UseridDetail.where(:userid => session[:userid]).first
	 @counties = Country.all.order_by(chapman_code: 1)

end

def new
	@first_name = session[:first_name]
	@country = Country.new
	get_userids_and_transcribers
end

def edit
	load(params[:id])
	get_userids_and_transcribers
end

def create
    @country = Country.new(params[:country])
	@country.save
 if @country.errors.any?
    
     flash[:notice] = "The addition of the Country was unsuccessful"
     render :action => 'edit'
     return
 else
 	flash[:notice] = "The addition of the Country was successful"
 	 #Syndicate.change_userid_fields(params)
     redirect_to countries_path
 end
end

def update
	load(params[:id])
	 previous_country_coordinator = @country.country_coordinator
	 params[:country][:previous_country_coordinator] = previous_country_coordinator  unless @country.country_coordinator == params[:country][:country_coordinator]
	 @country.update_attributes(params[:country])
     if @country.errors.any?
       
       flash[:notice] = "The change to the country was unsuccessful"
        render :action => 'edit'
        return
     else
 	   flash[:notice] = "The change to the country was successful"
 	
     redirect_to countries_path
     end
	
end

def show
	load(params[:id])
	person = UseridDetail.where(:userid => @country.country_coordinator).first
    @person = person.person_forename + ' ' + person.person_surname unless person.nil? 
    person = UseridDetail.where(:userid => @country.previous_country_coordinator).first
     @previous_person = person.person_forename + ' ' + person.person_surname unless person.nil? 
end

def load(id)
   @first_name = session[:first_name]
   @country = Country.find(id)
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
