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

    p  @syndicates
   
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
      redirect_to freereg1_csv_files_path
      return
      when params[:manage_syndicate][:action] == 'Add Member' 
      redirect_to new_userid_detail_path
       return
    end
    @user = UseridDetail.where(:userid => session[:userid]).first
   redirect_to manage_resource_path(@user)

  	
  
  end # create


end


