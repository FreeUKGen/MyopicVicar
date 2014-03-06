class ManageSyndicatesController < ApplicationController
layout "manage_counties"

	def index

	@userid = session[:userid]
  @first_name = session[:first_name]
  @user = UseridDetail.where(:userid => session[:userid]).first
  syndicates = Syndicate.where(:syndicate_coordinator => session[:userid]).all
  number_of_syndicates = syndicates.length
  

   redirect_to manage_resource_path(@user) if number_of_syndicates == 0
   @manage_syndicate = ManageSyndicate.new
  
    if number_of_syndicates == 1 
        @syndicates = Syndicate.where(:syndicate_coordinator => session[:userid]).first.syndicate_code#this needs changing to counties when that collection is set up
       session[:syndicate] =  @syndicates
        session[:muliple] = false

    else
       session[:muliple] = true
       synd = Array.new
       syndicates.each do |syn|
        synd << syn.syndicate_code #this needs changing to counties when that collection is set up
       end
       @syndicates = synd
    end #end if

     
end


def new
 end 


 def create
  
 
  	session[:syndicate] = params[:manage_syndicate][:syndicate] if  session[:muliple] == true

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
      when params[:manage_syndicate][:action] == 'Review Batches listed by number of userid then filename'
      session[:sort] =  sort = "userid ASC, file_name ASC"
      redirect_to freereg1_csv_files_path
      return
      when params[:manage_syndicate][:action] == 'Review Batches listed by uploaded date (ascending) then userid'
      session[:sort] =  sort = "uploaded_date DESC, userid ASC"
      redirect_to freereg1_csv_files_path
      return
     when params[:manage_syndicate][:action] == 'Review Batches listed by uploaded date (descending) then userid'
      session[:sort] =  sort = "uploaded_date ASC, userid ASC"
      redirect_to freereg1_csv_files_path
      return
    end
    @user = UseridDetail.where(:userid => session[:userid]).first
   redirect_to manage_resource_path(@user)

  	
  
  end # create


end


