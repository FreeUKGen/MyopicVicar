class ManageSyndicatesController < ApplicationController
layout "manage_counties"

	def index
  
  clean_session
  

	@userid = session[:userid]
  @first_name = session[:first_name]
  @user = UseridDetail.where(:userid => session[:userid]).first
  syndicates =@user.syndicate_groups
  number_of_syndicates = syndicates.length
  session[:role] = 'syndicate'

   redirect_to manage_resource_path(@user) if number_of_syndicates == 0
   @manage_syndicate = ManageSyndicate.new
  
    if number_of_syndicates == 1 
        @syndicates = syndicates[0]
       session[:syndicate] =  @syndicates
      
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


def select_userid

  
end


def new
 end 


 def create
  
 
  	session[:syndicate] = params[:manage_syndicate][:syndicate] if session[:muliple] == true
  
    case 
    when params[:manage_syndicate][:action] == 'Review Members listed alphabetically'
     redirect_to userid_details_path
     return
     when params[:manage_syndicate][:action] == 'Review Batches listed by filename'
      session[:sort] =  sort = "file_name ASC"
  
       
     when params[:manage_syndicate][:action] == 'Review Batches with errors'
        session[:sort] =  sort = "error DESC, file_name ASC"
        
    
      when params[:manage_syndicate][:action] == 'Review Batches listed by userid then filename'
      session[:sort] =  sort = "userid ASC, file_name ASC"
      
      
      when params[:manage_syndicate][:action] == 'Review Batches listed by uploaded date'
      session[:sort] =  sort = "uploaded_date DESC"
        
    else
       @user = UseridDetail.where(:userid => session[:userid]).first
      redirect_to manage_resource_path(@user)
      return
    end
      
        redirect_to freereg1_csv_files_path
   
  	
  
  end # create


end


