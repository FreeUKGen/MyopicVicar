class ManageSyndicatesController < ApplicationController
layout "manage_counties"

	def index
    if session[:userid].nil?
      redirect_to '/', notice: "You are not authorised to use these facilities"
    end
  clean_session
  @userid = session[:userid]
  @first_name = session[:first_name]
  @user = UseridDetail.where(:userid => session[:userid]).first
  syndicates =@user.syndicate_groups
  syndicates = Syndicate.all.order_by(syndicate_code: 1) if session[:userid] == "SNDManager"
  number_of_syndicates = syndicates.length
  session[:role] = 'syndicate'
  session[:page] = request.original_url
   redirect_to manage_resource_path(@user) if number_of_syndicates == 0
    
   @manage_syndicate = ManageSyndicate.new
  
    if number_of_syndicates == 1 
        @syndicates = syndicates[0]
       session[:syndicate] =  @syndicates
      
      session[:multiple] = false

    else
       session[:multiple] = true
       synd = Array.new
       syndicates.each do |syn|
        synd << syn unless session[:userid] == "SNDManager"
        synd << syn.syndicate_code if session[:userid] == "SNDManager"
       end
       @syndicates = synd

    end #end if
   
end


def select_userid
end

def new
 end 

 def create
    	session[:syndicate] = params[:manage_syndicate][:syndicate] if session[:multiple] == true
      case 
       when params[:manage_syndicate][:action] == 'Upload New Batch'
         redirect_to new_csvfile_path
         return
       
        when params[:manage_syndicate][:action] == 'Review Batches listed by filename'
          session[:sort] =  sort = "file_name ASC"    
        when params[:manage_syndicate][:action] == 'Review Batches with errors'
          session[:sort] =  sort = "error DESC, file_name ASC" 
        when params[:manage_syndicate][:action] == 'Review Batches listed by userid then filename'
           session[:sort] =  sort = "userid ASC, file_name ASC"
        when params[:manage_syndicate][:action] == 'Review Batches listed by uploaded date'
           session[:sort] =  sort = "uploaded_date DESC"
         when params[:manage_syndicate][:action] == 'Review Active Members' 
             @first_name = session[:first_name]
             @user = UseridDetail.where(:userid => session[:userid]).first
             session[:type] = "manager"
             session[:my_own] = "no"
             users = UseridDetail.where(:syndicate => session[:syndicate], :active => true).all.order_by(userid_lower_case: 1) 
             @userids = Array.new
                users.each do |user|
                @userids << user
             end
          render 'userid_details/index'
          return


       
         
          when params[:manage_syndicate][:action] == 'Review all Members'
             redirect_to userid_details_path  
             return
        else
           @user = UseridDetail.where(:userid => session[:userid]).first
            redirect_to manage_resource_path(@user)
           return
        end
          redirect_to freereg1_csv_files_path
  end # create
end


