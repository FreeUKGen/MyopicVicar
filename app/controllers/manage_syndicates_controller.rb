class ManageSyndicatesController < ApplicationController

  def batches_with_errors
    get_user_info_from_userid
    @county = session[:syndicate]
    @who = @user.person_forename
    @sorted_by = '; sorted by descending number of errors and then file name'
    session[:sorted_by] = @sorted_by
    session[:sort] = "error DESC, file_name ASC"
    redirect_to freereg1_csv_files_path
  end

  def change_recruiting_status
    syndicate = Syndicate.where(:syndicate_code => session[:syndicate]).first
    status = !syndicate.accepting_transcribers
    syndicate.update_attributes(:accepting_transcribers => status)
    flash[:notice] = "Accepting volunteers is now #{status}"
    redirect_to :action => 'select_action'
  end

  def create
    session[:syndicate] = params[:manage_syndicate][:syndicate]
    redirect_to :action => 'select_action'
    return
  end

  def display_by_filename
    get_user_info_from_userid
    @county = session[:syndicate]
    @who = @user.person_forename
    @sorted_by = '; sorted by file name ascending'
    session[:sorted_by] = @sorted_by
    session[:sort] = "file_name ASC"
    redirect_to freereg1_csv_files_path
  end

  def display_by_userid_filename
    get_user_info_from_userid
    @county = session[:syndicate]
    @who = @user.person_forename
    @sorted_by = '; sorted by userid and then file name ascending)'
    session[:sorted_by] = @sorted_by
    session[:sort] = "userid_lower_case ASC, file_name ASC"
    redirect_to freereg1_csv_files_path
  end

  def display_by_descending_uploaded_date
    get_user_info_from_userid
    @county = session[:syndicate]
    @who = @user.person_forename
    @sorted_by = '; sorted by most recent date of upload'
    session[:sorted_by] = @sorted_by
    session[:sort] = "uploaded_date DESC"
    redirect_to freereg1_csv_files_path
  end

  def display_by_ascending_uploaded_date
    get_user_info_from_userid
    @county = session[:syndicate]
    @who = @user.person_forename
    @sorted_by = '; sorted by oldest date of upload'
    session[:sort] = "uploaded_date ASC"
    session[:sorted_by] = @sorted_by
    redirect_to freereg1_csv_files_path
  end

  def display_files_waiting_to_be_processed
    @person = session[:syndicate]
    @batches = ManageSyndicate.get_waiting_files_for_syndicate(session[:syndicate])
    @sorted_by = "; waiting to be processed "
    render 'physical_files/index'
  end

  def display_files_not_processed
    @person = session[:syndicate]
    @batches = ManageSyndicate.get_not_processed_files_for_syndicate(session[:syndicate])
    @sorted_by = "; not processed "
    render 'physical_files/index'
  end

  def get_syndicates_for_selection
    all = true if  @user.person_role == 'volunteer_coordinator' || @user.person_role == 'data_manager' || @user.person_role == 'system_administrator' || @user.person_role == "SNDManager" ||  @user.person_role == 'documentation_coordinator'
    @syndicates = @user.syndicate_groups
    @syndicates = Syndicate.all.order_by(syndicate_code: 1) if all
    synd = Array.new
    @syndicates.each do |syn|
      synd << syn unless all
      synd << syn.syndicate_code if all
      @syndicates = synd
    end
  end

  def index
    redirect_to :action => 'new'
  end

  def member_by_email
    redirect_to :controller => 'userid_details', :action => 'selection', :option =>"Select specific email"
    return
  end

  def member_by_userid
    redirect_to :controller => 'userid_details', :action => 'selection', :option => "Select specific userid"
  end

  def member_by_name
    redirect_to :controller => 'userid_details', :action => 'selection', :option =>"Select specific surname/forename"
  end

  def new
    clean_session_for_syndicate
    session.delete(:syndicate)
    session.delete(:chapman_code)
    session.delete(:county)
    session[:page] = request.original_url
    get_user_info_from_userid
    get_syndicates_for_selection
    number_of_syndicates = @syndicates.length unless @syndicates.nil?
    if number_of_syndicates == 0
      flash[:notice] = 'You do not have any syndicates to manage'
      redirect_to new_manage_resource_path
      return
    end
    if number_of_syndicates == 1
      @syndicate = @syndicates[0]
      session[:syndicate] =  @syndicate
      redirect_to :action => 'select_action'
      return
    end
    @manage_syndicate = ManageSyndicate.new
    @options = @syndicates
    @prompt = 'You have access to multiple syndicates, please select one'
    @location = 'location.href= "/manage_syndicates/" + this.value +/selected/'
  end

  def select_action
    clean_session_for_syndicate
    session[:edit_userid] = true
    get_user_info_from_userid
    unless params[:syndicate].nil?
      session[:syndicate] = params[:syndicate]
    end
    @manage_syndicate = ManageSyndicate.new
    @syndicate = session[:syndicate]
    @options= UseridRole::SYNDICATE_MANAGEMENT_OPTIONS
    @prompt = 'Select Action?'
  end

  def selected
    session[:syndicate] = params[:id]
    redirect_to :action => 'select_action'
  end

  def show
    redirect_to :action => 'new'
  end

  def review_a_specific_batch
    get_user_info_from_userid
    @manage_syndicate = ManageSyndicate.new
    @county = session[:syndicate]
    @files = Hash.new
    userids = Syndicate.get_userids_for_syndicate(session[:syndicate])
    Freereg1CsvFile.in(userid: userids).order_by.order_by(file_name: 1).each do |file|
      @files["#{file.file_name}:#{file.userid}"] = file._id unless file.file_name.nil?
    end
    @options = @files
    @location = 'location.href= "/freereg1_csv_files/" + this.value'
    @prompt = 'Select batch'
    render '_form_for_selection'
  end

  def review_all_members
    get_user_info_from_userid
    session[:active] =  'All Members'
    redirect_to userid_details_path
    return
  end

  def review_active_members
    get_user_info_from_userid
    session[:active] =  'Active Members'
    redirect_to userid_details_path
    return
  end

  def upload_batch
    redirect_to new_csvfile_path
  end
end
