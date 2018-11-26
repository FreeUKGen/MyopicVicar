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
    @selection = session[:syndicate]
    @nature = "syndicate"
    @batches = ManageSyndicate.get_waiting_files_for_syndicate(session[:syndicate])
    @sorted_by = "; waiting to be processed "
    render 'physical_files/index'
  end

  def display_files_not_processed
    @selection = session[:syndicate]
    @nature = "syndicate"
    @batches = ManageSyndicate.get_not_processed_files_for_syndicate(session[:syndicate])
    @sorted_by = "; not processed "
    render 'physical_files/index'
  end

  def display_by_zero_date
    get_user_info_from_userid
    @county = session[:syndicate]
    @who = @user.person_forename
    @sorted_by = '; selects files with zero date records then alphabetically by userid and file name'
    session[:sorted_by] = @sorted_by
    session[:sort] = "userid_lower_case ASC, file_name ASC"
    @freereg1_csv_files = Freereg1CsvFile.syndicate(session[:syndicate]).datemin('0').no_timeout.order_by(session[:sort]).page(params[:page]).per(FreeregOptionsConstants::FILES_PER_PAGE)
    render 'freereg1_csv_files/index'
  end


  def get_syndicates_for_selection
    all = true if  @user.person_role == 'volunteer_coordinator' || @user.person_role == 'data_manager' || @user.person_role == 'system_administrator' || @user.person_role == "SNDManager" ||  @user.person_role == 'documentation_coordinator'
    @syndicates = @user.syndicate_groups
    @syndicates = Syndicate.all.order_by(syndicate_code: 1) if all
    unless @syndicates.nil?
      synd = Array.new
      @syndicates.each do |syn|
        synd << syn unless all
        synd << syn.syndicate_code if all
      end
      @syndicates = synd
    else
      logger.warn "FREEREG::USER #{@user.userid} has no syndicates and attempting to manage one"
      logger.warn "FREEREG::USER #{@user.inspect}"
    end
  end

  def index
    redirect_to :action => 'new'
  end

  def list_fully_reviewed_group
    get_user_info_from_userid

    if session[:syndicate].nil?
      flash[:notice] = 'Your other actions cleared the syndicate information, please select syndicate again'
      redirect_to main_app.new_manage_resource_path
      return
    else
      @source,@group_ids,@group_id = ImageServerGroup.group_ids_by_syndicate(session[:syndicate], 'r')

      # added for 'email CC of all image groups' button under 'List Fully Reviewed Groups'
      @completed_groups = []
      @group_ids.each {|x| @completed_groups  << x[0] }

      if @source.nil?
        flash[:notice] = 'No Fully Reviewed Image Groups Under This Syndicate'
        redirect_to manage_image_group_manage_syndicate_path(session[:Syndicate])
      else
        session.delete(:from_source)
        session[:image_group_filter] = 'fully_reviewed'
        render 'list_fully_reviewed_group'
      end
    end
  end

  def list_fully_transcribed_group
    get_user_info_from_userid

    if session[:syndicate].nil?
      flash[:notice] = 'Your other actions cleared the syndicate information, please select syndicate again'
      redirect_to main_app.new_manage_resource_path
      return
    else
      @source,@group_ids,@group_id = ImageServerGroup.group_ids_by_syndicate(session[:syndicate], 't')

      # added for 'email CC of all image groups' button under 'List Fully Transcribed Groups'
      @completed_groups = []
      @group_ids.each {|x| @completed_groups  << x[0] }

      if @source.nil?
        flash[:notice] = 'No Fully Transcribed Image Groups Under This Syndicate'
        redirect_to manage_image_group_manage_syndicate_path(session[:Syndicate])
      else
        session.delete(:from_source)
        session[:image_group_filter] = 'fully_transcribed'
        render 'list_fully_transcribed_group'
      end
    end
  end

  def manage_image_group
    get_user_info_from_userid
    clean_session_for_managed_images

    if session[:syndicate].nil?
      redirect_to main_app.new_manage_resource_path
      return
    else
      @source,@group_ids,@group_id = ImageServerGroup.group_ids_by_syndicate(session[:syndicate])

      render 'image_server_group_by_syndicate'
    end
  end

  def member_by_email
    redirect_to :controller => 'userid_details', :action => 'selection', :option =>"Select specific email", :syndicate => session[:syndicate]
    return
  end

  def member_by_userid
    redirect_to :controller => 'userid_details', :action => 'selection', :option => "Select specific userid", :syndicate => session[:syndicate]
  end

  def member_by_name
    redirect_to :controller => 'userid_details', :action => 'selection', :option =>"Select specific surname/forename", :syndicate => session[:syndicate]
  end

  def new
    #raise @syndicates.inspect
    clean_session_for_syndicate
    session.delete(:syndicate)
    session.delete(:chapman_code)
    session.delete(:county)
    session[:page] = request.original_url

    clean_session_for_images
    session[:manage_user_origin] = 'manage syndicate'

    get_user_info_from_userid
    get_syndicates_for_selection
    @syndicates.nil? ? number_of_syndicates = 0 : number_of_syndicates = @syndicates.length
    case number_of_syndicates
    when 0
      flash[:notice] = 'You do not have any syndicates to manage'
      redirect_to new_manage_resource_path
      return
    when 1
      @syndicate = @syndicates[0]
      session[:syndicate] =  @syndicate
      redirect_to :action => 'select_action'
      return
    else
      @manage_syndicate = ManageSyndicate.new
      @options = @syndicates
      @prompt = 'You have access to multiple syndicates, please select one'
      @location = 'location.href= "/manage_syndicates/" + this.value +/selected/'
    end
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

  def display_no_syndicate_message
    flash[:notice] = 'You do not have any syndicates to manage'
    redirect_to new_manage_resource_path
  end
end
