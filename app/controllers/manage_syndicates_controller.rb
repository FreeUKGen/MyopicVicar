class ManageSyndicatesController < ApplicationController
layout "manage_counties"

	def index

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
      @freereg1_csv_files = Freereg1CsvFile.where(:transcriber_syndicate => session[:syndicate] ).all.order_by(session[:sort]) 
       
     when params[:manage_syndicate][:action] == 'Review Batches with errors'
        session[:sort] =  sort = "error DESC, file_name ASC"
         @freereg1_csv_files = Freereg1CsvFile.where(:transcriber_syndicate => session[:syndicate], :error.gt => 0  ).all.order_by(session[:sort]) 
    
      when params[:manage_syndicate][:action] == 'Review Batches listed by userid then filename'
      session[:sort] =  sort = "userid ASC, file_name ASC"
      
      
      when params[:manage_syndicate][:action] == 'Review Batches listed by uploaded date'
      session[:sort] =  sort = "uploaded_date DESC"
     @freereg1_csv_files = Freereg1CsvFile.where(:transcriber_syndicate => session[:syndicate] ).all.order_by(session[:sort]) 
   
     when params[:manage_syndicate][:action] == 'Review Batches listed by userid and then uploaded date'
       @freereg1_csv_files = Freereg1CsvFile.where(:transcriber_syndicate => session[:syndicate] ).all.order_by(session[:sort]) 
      
    else
       @user = UseridDetail.where(:userid => session[:userid]).first
      redirect_to manage_resource_path(@user)
      return
    end
       @type = params[:manage_syndicate][:action]
        @register = session[:register_id]
        @user = UseridDetail.where(:userid => session[:userid]).first
        @first_name = session[:first_name]
        session[:my_own] = 'no'
        render 'freereg1_csv_files/index'
   
  	
  
  end # create


end


