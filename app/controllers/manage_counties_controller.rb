class ManageCountiesController < ActionController::Base

	 
def index
  
  clean_session
   
	@userid = session[:userid]
  @first_name = session[:first_name]
  @user = UseridDetail.where(:userid => session[:userid]).first
  session[:role] = 'counties'
  session[:return] = request.referer
  @counties = @user.county_groups
  @countries = @user.country_groups
 unless @countries.nil?
  
     @countries.each do |county|
        @counties << county unless  @counties.include?(county)
     end
 end
 @number_of_counties = @counties.length
 redirect_to manage_resource_path(@user) if @number_of_counties == 0
   @manage_county = ManageCounty.new
   if @number_of_counties == 1 
        session[:chapman_code] = @counties[0]
        @county = ChapmanCode.has_key(@counties[0])
        session[:county] = @county
        redirect_to places_path
    end
      
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
    redirect_to places_path
  end # create


end
