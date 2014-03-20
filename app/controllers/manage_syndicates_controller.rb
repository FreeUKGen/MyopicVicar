class ManageSyndicatesController < ApplicationController
layout "manage_counties"

	def index

	@userid = session[:userid]
  @first_name = session[:first_name]
  @user = UseridDetail.where(:userid => session[:userid]).first
  syndicates =@user.syndicate_groups
  number_of_syndicates = syndicates.length
  

   redirect_to manage_resource_path(@user) if number_of_syndicates == 0
   @manage_syndicate = ManageSyndicate.new
  
    if number_of_syndicates == 1 
        @syndicates = syndicates[0]
       session[:syndicate] =  @syndicates
       p  session[:syndicate]
      session[:muliple] = false

    else
       session[:muliple] = true
       synd = Array.new
       syndicates.each do |syn|
        synd << syn
       end
       @syndicates = synd
    end #end if

     
end


def new
 end 


 def create
  
 
  	session[:syndicate] = params[:manage_syndicate][:syndicate] if session[:muliple] == true
    p  session[:syndicate]
    case 
    when params[:manage_syndicate][:action] == 'Review Members listed alphabetically'
     redirect_to userid_details_path
     return
     when params[:manage_syndicate][:action] == 'Review Batches listed by filename'
      session[:sort] =  sort = "file_name ASC"
      redirect_to freereg1_csv_files_path
      return
       
     when params[:manage_syndicate][:action] == 'Review Batches listed by number of errors then filename'
      session[:sort] =  sort = "error DESC, file_name ASC"
      redirect_to freereg1_csv_files_path
      return
      when params[:manage_syndicate][:action] == 'Review Batches listed by userid then filename'
      session[:sort] =  sort = "userid ASC, file_name ASC"
      redirect_to freereg1_csv_files_path
      return
      when params[:manage_syndicate][:action] == 'Review Batches listed by uploaded date'
      session[:sort] =  sort = "uploaded_date DESC"
      redirect_to freereg1_csv_files_path
      return
     when params[:manage_syndicate][:action] == 'Review Batches listed by userid and then uploaded date'
      session[:sort] =  sort = "userid ASC, uploaded_date DESC"
      redirect_to freereg1_csv_files_path
      return
    end
    @user = UseridDetail.where(:userid => session[:userid]).first
   redirect_to manage_resource_path(@user)

  	
  
  end # create


end


