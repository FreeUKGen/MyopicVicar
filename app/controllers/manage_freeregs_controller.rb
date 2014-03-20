class ManageFreeregsController < ApplicationController
	layout "places"
  require "county"
def index
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
	 render "userid_details/index"
end
def all_files
	 @first_name = session[:first_name]
	  @user = UseridDetail.where(:userid => session[:userid]).first
	  session[:sort] =  sort = "file_name ASC"
	@freereg1_csv_files = Freereg1CsvFile.all.order_by(session[:sort]) 
	render "freereg1_csv_files/index"
end
def new

end

def create
	redirect_to manage_resources_path
end


end

