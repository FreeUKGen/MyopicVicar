class ManageFreeregsController < ApplicationController
	
  require "county"
def index
   get_user_info(session[:userid],session[:first_name])
   render 'new'
    
end

def create
  p self
  respond_to do |format|
      format.html {redirect_to manage_resources_path}
      format.js 
    end
	
end
def all
  p "all"
  p self

  
end

end

