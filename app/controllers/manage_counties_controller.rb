class ManageCountiesController < ActionController::Base

	 
def index
	p "entering index"
	p session
  redirect_to :action => :new
end


def new
 if session[:initial] == "yes"
 	p  "entering  first time setup"
 	p session
  @userid = session[:userid]
  @first_name = session[:first_name]
  @user = session[:user]
  @counties = Syndicate.where(:syndicate_coordinator => session[:userid]).all#this needs changing to counties when that collection is set up
  @number_of_counties = @counties.length
  p "number of counties"
  p @number_of_counties
   redirect_to manage_resource_path(@user) if @number_of_counties == 0
   @manage_county = ManageCounty.new
   session[:manage_county] = @manage_county
    if @number_of_counties == 1 
        @counties = Syndicate.where(:syndicate_coordinator => session[:userid]).first#this needs changing to counties when that collection is set up
        session[:chapman_code] = @counties.chapman_code
        @county = ChapmanCode.has_key(@counties.chapman_code)
        session[:county] = @county
        redirect_to places_path
    else
   	   session[:muliple] = true
   	   synd = Array.new
   	   @counties.each do |syn|
   	    synd << syn.syndicate_code #this needs changing to counties when that collection is set up
   	   end
   	   @counties = synd
    end #end if
  else
  	p "entering second time"
  	p session
  	@manage_county = session[:manage_county]
    @first_name = session[:first_name]
    @county	= session[:county]
     redirect_to places_path
  end #end unless

 end #end new


 def create
  p "creating"
  p session
  p params
  if session[:initial] == "yes"
  	session[:chapman_code] = params[:manage_county][:chapman_code]
    @county = ChapmanCode.has_key(session[:chapman_code])
    session[:county] = @county
    session[:initial] = "no"
    # redirect_to :action => :new
    #redirect_to coordinators_path(params)
    redirect_to place_path
  else
  	p "creating second"
  	p session
  	p params

    redirect_to :action => :new
  end #if
  end # create


end
