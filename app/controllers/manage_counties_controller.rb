class ManageCountiesController < ActionController::Base

	 
def index

	@userid = session[:userid]
  @first_name = session[:first_name]
  @user = UseridDetail.where(:userid => session[:userid]).first
  @counties = County.where(:county_coordinator => session[:userid]).all
  @number_of_counties = @counties.length
  

   redirect_to manage_resource_path(@user) if @number_of_counties == 0
   @manage_county = ManageCounty.new
  
    if @number_of_counties == 1 
        @counties = County.where(:county_coordinator => session[:userid]).first#this needs changing to counties when that collection is set up
        session[:chapman_code] = @counties.chapman_code
        @county = ChapmanCode.has_key(@counties.chapman_code)
        session[:county] = @county
        redirect_to places_path
    else
       session[:muliple] = true
       synd = Array.new
       @counties.each do |syn|
        synd << syn.chapman_code #this needs changing to counties when that collection is set up
       end
       @counties = synd
    end #end if
end


def new

  	
  
  	@manage_county = ManageCounty.new
    @first_name = session[:first_name]
    @county	= session[:county]
     redirect_to places_path
 
 end #end new


 def create
  
 
  	session[:chapman_code] = params[:manage_county][:chapman_code]
    @county = ChapmanCode.has_key(session[:chapman_code])
    session[:county] = @county
  
    # redirect_to :action => :new
    #redirect_to coordinators_path(params)
    redirect_to places_path

  	
  
  end # create


end
