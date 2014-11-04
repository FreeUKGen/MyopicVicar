class CountiesController < InheritedResources::Base

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
def selection
  get_user_info(session[:userid],session[:first_name])
  session[:county] = 'all' if @user.person_role == 'system_administrator'
  case 
    when params[:county] == "Browse counties"
      @counties = County.all.order_by(chapman_code: 1)
      render "index"
      return
    when params[:county] == "Create county"
      redirect_to :action => 'new' 
      return 
     
    when params[:county] == "Edit specific county"
      counties = County.all.order_by(chapman_code: 1)
      @counties = Array.new
      counties.each do |county|
        @counties << county.chapman_code
      end
      @location = 'location.href= "select?act=edit&county=" + this.value'
    when params[:county] == "Show specific county"
      counties = County.all.order_by(chapman_code: 1)
      @counties = Array.new
      counties.each do |county|
        @counties << county.chapman_code
      end
       @location = 'location.href= "select?act=show&county=" + this.value'
    else
      flash[:notice] = 'Invalid option'
      redirect_to :back
      return   
    end
     
      @prompt = 'Select county'
      params[:county] = nil
      @county = session[:county]
end
def select
    p params
  get_user_info(session[:userid],session[:first_name])
  case 
  when !params[:county].nil? 
    if params[:county] == ""
       flash[:notice] = 'Blank cannot be selected'
       redirect_to :back
       return
    else
      county = County.where(:chapman_code => params[:county]).first
      if params[:act] == "show"
        p "in show"
        redirect_to county_path(county)
        return
      else
        p 'in edit'
        redirect_to edit_county_path(county)
        return
      end
    end
  else
    flash[:notice] = 'Invalid option'
    redirect_to :back
    return   
  end
end 
def create
    @county = County.new(params[:county])
	@county.save
 if @county.errors.any?
    
     flash[:notice] = "The addition of the County was unsuccessful"
     render :action => 'edit'
     return
 else
 	flash[:notice] = "The addition of the County was successful"
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
      
       flash[:notice] = "The change to the county was unsuccessful"
        render :action => 'edit'
        return
     else
 	   flash[:notice] = "The change to the county was successful"
 	
     redirect_to counties_path
     end
	
end

def show
	load(params[:id])
	person = UseridDetail.where(:userid => @county.county_coordinator).first
    @person = person.person_forename + ' ' + person.person_surname unless person.nil? 
    person = UseridDetail.where(:userid => @county.previous_county_coordinator).first
    @previous_person = person.person_forename + ' ' + person.person_surname unless person.nil? || person.person_forename.nil?
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
