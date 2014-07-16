class ManageFreeregsController < ApplicationController
	layout "places"
  require "county"
def index
	 if session[:userid].nil?
      redirect_to '/', notice: "You are not authorised to use these facilities"
    end
    @first_name = session[:first_name]
   @user = UseridDetail.where(:userid => session[:userid]).first
    render 'new'
    
end
def all
	@first_name = session[:first_name]
	  @user = UseridDetail.where(:userid => session[:userid]).first
	 @userids = Array.new
	 profiles = UseridDetail.all.order_by(userid_lower_case: 1) 
	  
	 profiles.each do |profile|
	 	@userids << profile
	 end
	  @userids = Kaminari.paginate_array(@userids).page(params[:page]) 
	 render "userid_details/index"
end

def new

end

def create
	redirect_to manage_resources_path
end


end

