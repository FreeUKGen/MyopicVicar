class ManageFreeregsController < ApplicationController
	layout "places"
  require "county"
def index
    @first_name = session[:first_name]
   @user = UseridDetail.where(:userid => session[:userid]).first
    render 'new'
    
end

def new

end

def create
	redirect_to manage_resources_path
end


end

