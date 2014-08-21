class ManageFreeregsController < ApplicationController
	
  require "county"
def index
   get_user_info(session[:userid],session[:first_name])
   render 'new'
    
end

def create
	redirect_to manage_resources_path
end


end

