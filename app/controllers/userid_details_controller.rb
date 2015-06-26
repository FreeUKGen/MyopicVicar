class UseridDetailsController < ApplicationController
  require 'userid_role'
  skip_before_filter :require_login, only: [:general, :create,:researcher_registration, :transcriber_registration,:technical_registration]
  rescue_from ActiveRecord::RecordInvalid, :with => :record_validation_errors
  def index
    session[:return_to] = request.fullpath
    get_user_info_from_userid
    session[:my_own] = false
    @role = session[:role]
    if session[:active] ==  'All Members'
      @userids = UseridDetail.get_userids_for_display(session[:syndicate],params[:page])
    else
      @userids = UseridDetail.get_userids_for_display(session[:syndicate],params[:page])
    end
    @syndicate = session[:syndicate]
    @sorted_by = session[:active]
  end #end method
  def new
    session[:return_to] = request.fullpath
    session[:type] = "add"
    get_user_info_from_userid
    @role = session[:role]
    @syndicates = Syndicate.get_syndicates_open_for_transcription
    @userid = UseridDetail.new
  end
  def show
    session[:return_to] = request.fullpath
    @syndicate = session[:syndicate]
    get_user_info_from_userid
    load(params[:id])
  end
  def all
    session[:return_to] = request.fullpath
    get_user_info_from_userid
    @userids = UseridDetail.get_userids_for_display('all',params[:page])
    render "index"
  end
  def my_own
    session[:return_to] = request.fullpath
    session[:my_own] = true
    get_user_info_from_userid
    @userid = @user
  end
  def edit
    session[:return_to] = request.fullpath
    session[:type] = "edit"
    get_user_info_from_userid
    @userid = @user if  session[:my_own]
    load(params[:id])
    @syndicates = Syndicate.get_syndicates
  end
  def rename
    session[:return_to] = request.fullpath
    session[:type] = "edit"
    get_user_info_from_userid
    load(params[:id])
    @syndicates = Syndicate.get_syndicates
  end
  def change_password
    load(params[:id])
    @userid.send_invitation_to_reset_password
    flash[:notice] = 'An email with instructions to reset the password have been sent'
    redirect_to refinery.login_path
    return
  end
  def general
    session[:return_to] = request.fullpath
    session[:first_name] = 'New Registrant'
  end
  def researcher_registration
    session[:return_to] = request.fullpath
    session[:first_name] = 'New Registrant'
    session[:type] = "researcher_registration"
    @userid = UseridDetail.new
    @first_name = session[:first_name]
  end
  def transcriber_registration
    session[:return_to] = request.fullpath
    session[:first_name] = 'New Registrant'
    session[:type] = "transcriber_registration"
    @userid = UseridDetail.new
    @syndicates = Syndicate.get_syndicates_open_for_transcription
    @transcription_agreement = [true,false]
    @first_name = session[:first_name]
  end
  def technical_registration
    session[:return_to] = request.fullpath
    session[:first_name] = 'New Registrant'
    session[:type] = "technical_registration"
    @userid = UseridDetail.new
  end
  def options
    session[:return_to] = request.fullpath
    get_user_info_from_userid
    if session[:userid].nil?
      redirect_to '/', notice: "You are not authorised to use these facilities"
      return
    end
    @syndicate = 'all'
    session[:syndicate] = @syndicate
    if @user.person_role == 'system_administrator' || @user.person_role == 'volunteer_coordinator'
      @options= UseridRole::USERID_MANAGER_OPTIONS
    else
      @options= UseridRole::USERID_ACCESS_OPTIONS
    end
  end
  def selection
    session[:return_to] = request.fullpath
    get_user_info_from_userid
    @userid = @user
    case
    when params[:option] == 'Browse userids'
      @userids = UseridDetail.get_userids_for_display('all',params[:page])
      render "index"
      return
    when params[:option] == "Create userid"
      redirect_to :action => 'new'
      return
    when params[:option] == "Select specific email"
      @userids = UseridDetail.get_emails_for_selection(session[:syndicate])
      @location = 'location.href= "select?email=" + this.value'
      @prompt = "Please select an email address from the following list for #{session[:syndicate]}"
    when params[:option] == "Select specific userid"
      @userids = UseridDetail.get_userids_for_selection(session[:syndicate])
      @location = 'location.href= "select?userid=" + this.value'
      @prompt = "Select userid for #{session[:syndicate]}"
    when params[:option] == "Select specific surname/forename"
      @userids = UseridDetail.get_names_for_selection(session[:syndicate])
      @location = 'location.href= "select?name=" + this.value'
      @prompt = "Select surname/forename for #{session[:syndicate]}"
    else
      flash[:notice] = 'Invalid option'
      params[:option] = nil
      redirect_to :back
      return
    end
    params[:option] = nil
    @manage_syndicate = session[:syndicate]
  end
  def select
    get_user_info(session[:userid],session[:first_name])
    case
    #selection by userid
    when !params[:userid].nil?
      if params[:userid] == ""
        flash[:notice] = 'Blank cannot be selected'
        redirect_to :back
        return
      else
        userid = UseridDetail.where(:userid => params[:userid]).first
        redirect_to userid_detail_path(userid)
        return
      end
    when !params[:email].nil?
      #selection by email
      if params[:email] == ""
        flash[:notice] = 'Blank cannot be selected'
        redirect_to :back
        return
      else
        #adjust for + having been replaced with space
        params[:email] = params[:email].gsub(/\s/,"+")
        userid = UseridDetail.where(:email_address => params[:email]).first
        redirect_to userid_detail_path(userid)
        return
      end
    when !params[:name].nil?
      #selection by name
      if params[:name] == ""
        flash[:notice] = 'Blank cannot be selected'
        redirect_to :back
        return
      else
        name = params[:name].split(":")
        number = UseridDetail.where(:person_surname => name[0],:person_forename => name[1] ).count
        if  number == 1
          userid = UseridDetail.where(:person_surname => name[0],:person_forename => name[1] ).first
          redirect_to userid_detail_path(userid)
          return
        else
          @userids = UseridDetail.where(:person_surname => name[0],:person_forename => name[1] ).all.page(params[:page])
          render 'index'
          return
        end
      end
    else
      flash[:notice] = 'Invalid option'
      redirect_to :back
      return
    end
  end
  def create
    @userid = UseridDetail.new(params[:userid_detail])
    @userid.add_fields(params[:commit])
    @userid.save
    if @userid.save
      @userid.send_invitation_to_create_password
      @userid.write_userid_file
      flash[:notice] = 'The initial registration was successful; an email has been sent to complete the process. Return to this page to login.'
      next_place_to_go_successful_create
    else
      flash[:notice] = 'The registration was unsuccessful'
      @syndicates = Syndicate.get_syndicates_open_for_transcription
      next_place_to_go_unsuccessful_create
    end
  end
  def update
    if params[:commit] == "Rename"
      load(params[:id])
      success = true
      success = false if UseridDetail.where(:userid => params[:userid_detail][:userid]).exists?
      success = Freereg1CsvFile.change_userid(params[:id], @userid.userid, params[:userid_detail][:userid]) if success
      if !success
        flash[:notice] = 'The update of the profile was unsuccessful please contact program support'
        @syndicates = Syndicate.get_syndicates_open_for_transcription
        redirect_to :action => 'all' and return
      end
    else
      load(params[:id])
      if session[:type] == "disable"
        params[:userid_detail][:disabled_date]  = DateTime.now if  @userid.disabled_date.nil?
        params[:userid_detail][:active]  = false
      end
      params[:userid_detail][:person_role] = params[:userid_detail][:person_role] unless params[:userid_detail][:person_role].nil?

    end
    @userid.update_attributes(params[:userid_detail])
    @userid.write_userid_file
    @userid.save_to_refinery
    if !@userid.errors.any?
      flash[:notice] = 'The update of the profile was successful'
      next_place_to_go_successful_update
    else
      flash[:notice] = 'The update of the profile was unsuccessful'
      @syndicates = Syndicate.get_syndicates_open_for_transcription
      next_place_to_go_unsuccessful_update
    end
  end
  def destroy
    load(params[:id])
    session[:type] = "edit"
    if @userid.has_files?
      flash[:notice] = 'The destruction of the profile is not permitted as there are batches stored under this name'
      next_place_to_go_unsuccessful_update
    else
      Freereg1CsvFile.delete_userid(@userid.userid)
      p @userid
      @userid.destroy
      flash[:notice] = 'The destruction of the profile was successful'
      redirect_to :action => 'options'
    end
  end
  def disable
    load(params[:id])
    session[:type] = "disable"
  end
  def load(userid_id)
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
    @userid = UseridDetail.find(userid_id)
    session[:userid_id] = userid_id
    @role = session[:role]
  end
  def next_place_to_go_unsuccessful_create
    case
    when session[:type] == "add"
      @user = current_refinery_user.userid_detail
      @first_name = @user.person_forename
      @manager = manager?(@user)
      @roles = UseridRole::OPTIONS.fetch(@user.person_role)
      render :action => 'new' and return
    when session[:type] == 'researcher_registration'
      render :action => 'researcher_registration' and return
    when session[:type] == 'transcriber_registration'
      @syndicates = Syndicate.get_syndicates_open_for_transcription
      @transcription_agreement = [true,false]
      render :action => 'transcriber_registration' and return
    when session[:type] == 'technical_registration'
      render :action => 'technical_registration' and return
    else
      get_user_info_from_userid
      render :action => 'new' and return
    end
  end
  def next_place_to_go_unsuccessful_update
    case
    when session[:my_own]
      get_user_info_from_userid
      @userid = @user 
      render :action => 'edit' and return
    when session[:type] == "edit" || session[:type] == "add"
      if @user.person_role == 'system_administrator'
        redirect_to :action => 'all' and return
      else
        redirect_to userid_details_path(:anchor => "#{ @userid.id}") and return
      end
    else
      redirect_to refinery.login_path and return
    end
  end
  def next_place_to_go_successful_create
    @userid.finish_creation_setup if params[:commit] == 'Submit'
    @userid.finish_researcher_creation_setup if params[:commit] == 'Register Researcher'
    @userid.finish_transcriber_creation_setup if params[:commit] == 'Register Transcriber'
    @userid.finish_technical_creation_setup if params[:commit] == 'Technical Registration'
    case
    when session[:type] == "add"
      if session[:role] == 'system_administrator'
        redirect_to session[:return_to] and return
      else
        redirect_to userid_details_path(:anchor => "#{ @userid.id}") and return
      end
    else
      redirect_to refinery.login_path and return
    end 
  end
  def next_place_to_go_successful_update
    case
    when session[:my_own]
      @userid = @user
      redirect_to :action => 'my_own' and return
    when (session[:type] == "edit" || session[:type] == "add")
      if @user.person_role == 'system_administrator'
        redirect_to session[:return_to] and return
      else
        redirect_to userid_details_path(:anchor => "#{ @userid.id}") and return
      end
    else
       redirect_to refinery.login_path and return
    end
  end
  def record_validation_errors(exception)
    flash[:notice] = "The registration was unsuccessful due to #{exception.record.errors.messages}"
    @userid.delete
    next_place_to_go_unsuccessful_update
  end
end
