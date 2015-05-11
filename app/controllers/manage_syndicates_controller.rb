class ManageSyndicatesController < ApplicationController

  def index
    redirect_to :action => 'new'
  end
  def new
    clean_session
    session[:syndicate] = nil
    session[:role] = 'syndicate'
    session[:page] = request.original_url
    get_user_info_from_userid
    get_syndicates_for_selection
    number_of_syndicates = @syndicates.length
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
    @prompt = 'Please select a syndicates:'
    @location = 'location.href= "/manage_syndicates/select_action?syndicate=" + this.value'
  end
  def select_action
    get_user_info_from_userid
    unless params[:syndicate].nil?
      session[:syndicate] = params[:syndicate]
    end
    @manage_syndicate = ManageSyndicate.new
    @syndicate = session[:syndicate]
    @options= UseridRole::SYNDICATE_MANAGEMENT_OPTIONS
    @prompt = 'Select Action?'
  end

  def review_all_members
    get_user_info_from_userid
    @userids = UseridDetail.get_userids_for_display(session[:syndicate],params[:page])
    @sorted_by = 'All Members'
    render 'userid_details/index'
    return
  end
  def review_active_members
    get_user_info_from_userid
    @userids = UseridDetail.get_active_userids_for_display(session[:syndicate],params[:page])
    @sorted_by = 'Active Members'
    render 'userid_details/index'
    return
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
  def batches_with_errors
    get_user_info_from_userid
    @county = session[:syndicate]
    @who = nil
    @sorted_by = '(Sorted by descending number of errors and then filename)'
    @freereg1_csv_files = Freereg1CsvFile.syndicate(session[:syndicate]).order_by("error DESC, file_name ASC" ).page(params[:page])
    render 'freereg1_csv_files/index'
  end
  def display_by_filename
    get_user_info_from_userid
    @county = session[:syndicate]
    @who = nil
    @sorted_by = '(Sorted by filename ascending)'
    @freereg1_csv_files = Freereg1CsvFile.syndicate(session[:syndicate]).order_by("file_name ASC" ).page(params[:page])
    render 'freereg1_csv_files/index'
  end
  def upload_batch
    redirect_to new_csvfile_path
  end
  def display_by_userid_filename
    get_user_info_from_userid
    @county = session[:syndicate]
    @who = nil
    @sorted_by = '(Sorted by userid and then filename ascending)'
    @freereg1_csv_files = Freereg1CsvFile.syndicate(session[:syndicate]).order_by("userid ASC, file_name ASC" ).page(params[:page])
    render 'freereg1_csv_files/index'
  end
  def display_by_descending_uploaded_date
    get_user_info_from_userid
    @county = session[:syndicate]
    @who = nil
    @sorted_by = '(Sorted by most recent date of upload)'
    @freereg1_csv_files = Freereg1CsvFile.syndicate(session[:syndicate]).order_by("uploaded_date DESC" ).page(params[:page])
    render 'freereg1_csv_files/index'
  end
  def display_by_ascending_uploaded_date
    get_user_info_from_userid
    @county = session[:syndicate]
    @who = nil
    @sorted_by = '(Sorted by oldest date of upload)'
    @freereg1_csv_files = Freereg1CsvFile.syndicate(session[:syndicate]).order_by("uploaded_date ASC" ).page(params[:page])
    render 'freereg1_csv_files/index'
  end
  def review_a_specific_batch
    get_user_info_from_userid
    @manage_county = ManageSyndicate.new
    @county = session[:syndicate]
    @files = Array.new
    Freereg1CsvFile.syndicate(session[:syndicate]).order_by(file_name: 1).each do |file|
      @files << file.file_name
    end
    @options = @files
    @location = 'location.href= "/manage_counties/files?params=" + this.value'
    @prompt = 'Select batch'
    render '_form'
  end
  def change_recruiting_status
    syndicate = Syndicate.where(:syndicate_code => session[:syndicate]).first
    status = !syndicate.accepting_transcribers
    syndicate.update_attributes(:accepting_transcribers => status)
    flash[:notice] = "Accepting volunteers is now #{status}" 
    redirect_to :action => 'select_action'  
  end

  def get_syndicates_for_selection
    all = true if  @user.person_role == 'volunteer_coordinator' || @user.person_role == 'system_administrator' || @user.person_role == "SNDManager"
    @syndicates = @user.syndicate_groups
    @syndicates = Syndicate.all.order_by(syndicate_code: 1) if all
    synd = Array.new
    @syndicates.each do |syn|
      synd << syn unless all
      synd << syn.syndicate_code if all
      @syndicates = synd
    end
  end



end
