class ManageSyndicatesController < ApplicationController

def index
  clean_session
  session[:role] = 'syndicate'
  session[:page] = request.original_url
  get_user_info(session[:userid],session[:first_name])
  syndicates = @user.syndicate_groups
  syndicates = Syndicate.all.order_by(syndicate_code: 1) if session[:userid] == "SNDManager"
  number_of_syndicates = syndicates.length
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
  get_user_info(session[:userid],session[:first_name])
  @userids = UseridDetail.get_active_userids_for_display(session[:syndicate],params[:page]) 
  session[:type] = "manager"
  session[:my_own] = "no"
  render 'userid_details/index'
  return
 when params[:manage_syndicate][:action] == 'Select Specific Member by Userid'
  redirect_to :controller => 'userid_details', :action => 'selection', :userid => "Select specific userid"
  return
 when params[:manage_syndicate][:action] == 'Select Specific Member by Email Address' 
  redirect_to :controller => 'userid_details', :action => 'selection', :userid =>"Select specific email"
  return
 when params[:manage_syndicate][:action] == 'Select Specific Member by name'
  redirect_to :controller => 'userid_details', :action => 'selection', :userid =>"Select specific surname"
  return
 when params[:manage_syndicate][:action] == 'Review all Members'
    @userids = UseridDetail.get_active_userids_for_display(session[:syndicate],params[:page]) 
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
    session[:type] = "manager"
    session[:my_own] = "no"
    render 'userid_details/index'
    return
 else
    @user = UseridDetail.where(:userid => session[:userid]).first
    redirect_to manage_resource_path(@user)
    return
 end
 redirect_to freereg1_csv_files_path
end # create

end


