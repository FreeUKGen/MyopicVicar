class ManageFreeregsController < ApplicationController
	
  require "county"
  def index
   @manage_freeregs = ManageFreereg.new
   get_user_info(session[:userid],session[:first_name])
   @options_userids=["Browse userids","Create userid","Incomplete registrations","Select specific email","Select specific userid", "Select specific surname"]
   @location_manage_userid = 'location.href= "/userid_details/selection?userid=" + this.value'
   


   render 'new'
   
 end

 def create

  respond_to do |format|
    format.html {redirect_to manage_resources_path}
    format.js 
  end
  
end
def all
  
end

end

