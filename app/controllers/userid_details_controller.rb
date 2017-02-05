class UseridDetailsController < ApplicationController
  require 'userid_role'
  skip_before_filter :require_login, only: [:general, :create,:researcher_registration, :transcriber_registration,:technical_registration]
  rescue_from ActiveRecord::RecordInvalid, :with => :record_validation_errors


  def all
    if params[:page]
      session[:user_index_page] = params[:page]
    end
    session[:return_to] = request.fullpath
    get_user_info_from_userid
    @userids = UseridDetail.get_userids_for_display('all')
    render "index"
  end

  def change_password
    load(params[:id])
    refinery_user = Refinery::Authentication::Devise::User.where(:username => @userid.userid).first
    if refinery_user.blank?
      flash[:notice] = 'There was an issue with your request please consult your coordinator.' if session[:my_own]
      flash[:notice] = 'There was an issue with the userid please consult with system administration.' if !session[:my_own]
      logger.warn("FREEREG:USERID: The refinery entry for #{@userid.userid} does not exist. Run the Fix Refinery User Table utilty")
    else
      refinery_user.send_reset_password_instructions
      flash[:notice] = 'An email has been sent with instructions.'
    end
    if session[:my_own]
      redirect_to logout_manage_resources_path and return
    else
      redirect_to userid_detail_path(@userid) and return
    end
  end

  def confirm_email_address
    get_user_info_from_userid
    session[:edit_userid] = true
    session[:return_to] = '/manage_resources/new'
    @userid = @user
    @current = @user.email_address
    @options = [true,false]
  end

  def create
    @userid = UseridDetail.new(userid_details_params)
    @userid.add_fields(params[:commit],session[:syndicate])
    @userid.save
    if @userid.save
      refinery_user = Refinery::Authentication::Devise::User.where(:username => @userid.userid).first
      refinery_user.send_reset_password_instructions
      flash[:notice] = 'The initial registration was successful; an email has been sent to complete the process.'
      @userid.write_userid_file
      next_place_to_go_successful_create
    else
      flash[:notice] = 'The registration was unsuccessful'
      @syndicates = Syndicate.get_syndicates_open_for_transcription
      next_place_to_go_unsuccessful_create
    end
  end

  def destroy
    load(params[:id])
    session[:type] = "edit"
    if @userid.has_files?
      flash[:notice] = 'The destruction of the profile is not permitted as there are batches stored under this name'
      redirect_to :action => 'options'
    else
      Freereg1CsvFile.delete_userid_folder(@userid.userid) unless @userid.nil?
      @userid.destroy
      flash[:notice] = 'The destruction of the profile was successful'
      redirect_to :action => 'options'
    end
  end

  def disable
    session[:return_to] = request.fullpath
    load(params[:id])
    unless @userid.active
      @userid.update_attributes(:active => true, :disabled_reason_standard => nil, :disabled_reason => nil, :disabled_date => nil)
      flash[:notice] = "Userid re-activated"
      redirect_to userid_details_path(:anchor => "#{ @userid.id}") and return
    end
    session[:type] = "disable"
  end

  def display
    session[:return_to] = request.fullpath
    get_user_info_from_userid
    @syndicate = 'all'
    session[:syndicate] =  @syndicate
    @options= UseridRole::USERID_ACCESS_OPTIONS
    session[:edit_userid] = false
    render :action => "options"
  end

  def edit
    session[:return_to] = request.fullpath
    session[:type] = "edit"
    get_user_info_from_userid
    @userid = @user if  session[:my_own]
    load(params[:id])
    @syndicates = Syndicate.get_syndicates
  end

  def general
    session[:return_to] = request.fullpath
    session[:first_name] = 'New Registrant'
  end

  def index
    session[:return_to] = request.fullpath
    get_user_info_from_userid
    session[:my_own] = false
    @role = session[:role]
    if session[:active] ==  'All Members'
      @userids = UseridDetail.get_userids_for_display(session[:syndicate])
    else
      @userids = UseridDetail.get_active_userids_for_display(session[:syndicate])
    end
    @syndicate = session[:syndicate]
    @sorted_by = session[:active]
  end #end method

  def load(userid_id)
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
    @userid = UseridDetail.id(userid_id).first
    if @userid.nil?
      go_back("userid",userid_id)
    else
      session[:userid_id] = userid_id
      @syndicate = session[:syndicate]
      @role = session[:role]
    end
  end

  def new
    session[:return_to] = request.fullpath
    session[:type] = "add"
    get_user_info_from_userid
    @role = session[:role]
    @syndicates = Syndicate.get_syndicates_open_for_transcription
    @syndicates = session[:syndicate] if @user.person_role == "syndicate_coordinator" || @user.person_role == "volunteer_coordinator" ||
      @user.person_role == "data_manager"
    @syndicates = Syndicate.get_syndicates if @user.person_role == "system_administrator"
    @userid = UseridDetail.new
  end

  def my_own
    clean_session
    clean_session_for_county
    clean_session_for_syndicate
    session[:edit_userid] = true
    session[:return_to] = request.fullpath
    session[:my_own] = true
    get_user_info_from_userid
    @userid = @user
  end

  def next_place_to_go_successful_create
    @userid.finish_creation_setup if params[:commit] == 'Register as Transcriber'
    @userid.finish_researcher_creation_setup if params[:commit] == 'Register Researcher'
    @userid.finish_technical_creation_setup if params[:commit] == 'Technical Registration'
    case
    when  params[:commit] == 'Register as Transcriber'
      redirect_to :back and return
    when params[:commit] == "Submit" && session[:userid_detail_id].present?
      redirect_to userid_detail_path(@userid) and return
    when params[:commit] == "Update" && session[:my_own]
      logout_manage_resources_path and return
    when params[:commit] == "Update" && session[:userid_detail_id].present?
      redirect_to userid_detail_path(@userid) and return
    else
      logout_manage_resources_path and return
    end
  end

  def next_place_to_go_unsuccessful_create
    case
    when  params[:commit] == "Submit"
      @user = UseridDetail.where(userid:  session[:userid]).first
      render :action => 'new' and return
    when params[:commit] == 'Register Researcher'
      render :action => 'researcher_registration' and return
    when params[:commit] == 'Register as Transcriber'
      @syndicates = Syndicate.get_syndicates_open_for_transcription
      @transcription_agreement = [true,false]
      render :action => 'transcriber_registration' and return
    when params[:commit] == 'Technical Registration'
      render :action => 'technical_registration' and return
    else
      @user = UseridDetail.where(userid:  session[:userid]).first
      render :action => 'new' and return
    end
  end

  def options
    session[:return_to] = request.fullpath
    get_user_info_from_userid
    session[:edit_userid] = true
    @syndicate = 'all'
    session[:syndicate] =  @syndicate
    if @user.person_role == 'system_administrator' || @user.person_role == 'volunteer_coordinator'
      @options= UseridRole::USERID_MANAGER_OPTIONS
    else
      @options= UseridRole::USERID_ACCESS_OPTIONS
    end
  end

  def person_roles
    session[:return_to] = request.fullpath
    get_user_info_from_userid
    @userid = UseridDetail.new
    @options = UseridRole::VALUES
    @prompt = 'Select Role?'
    @location = 'location.href= "role?role=" + this.value'
  end

  def record_validation_errors(exception)
    flash[:notice] = "The registration was unsuccessful due to #{exception.record.errors.messages}"
    @userid.delete
    next_place_to_go_unsuccessful_update
  end

  def rename
    session[:return_to] = request.fullpath
    session[:type] = "edit"
    get_user_info_from_userid
    load(params[:id])
    @syndicates = Syndicate.get_syndicates
  end

  def researcher_registration
    if Rails.application.config.member_open
      cookies.signed[:Administrator] = Rails.application.config.github_issues_password
      session[:return_to] = request.fullpath
      session[:first_name] = 'New Registrant'
      session[:type] = "researcher_registration"
      @userid = UseridDetail.new
      @first_name = session[:first_name]
    else
      #we set the mongo_config.yml member open flag. true is open. false is closed We do allow technical people in
      flash[:notice] = "The system is presently undergoing maintenance and is unavailable for registration"
      redirect_to :back
      return
    end
  end

  def role
    @userids = UseridDetail.role(params[:role]).all.order_by(userid_lower_case: 1)
    @syndicate = " #{params[:role]}"
    @sorted_by = " lower case userid"
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
        case
        when number == 0
          @userids = UseridDetail.where(:person_surname => name[0]).all
          if @userids.blank?
            flash[:notice] = "could not locate the name likely because of blanks in the stored name"
          end
          render 'index'
          return
        when number == 1
          userid = UseridDetail.where(:person_surname => name[0],:person_forename => name[1] ).first
          redirect_to userid_detail_path(userid)
          return
        when number >= 2
          @userids = UseridDetail.where(:person_surname => name[0],:person_forename => name[1] ).all
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

  def selection
    session[:return_to] = request.fullpath
    get_user_info_from_userid
    @userid = @user
    case
    when params[:option] == 'Browse userids'
      @userids = UseridDetail.get_userids_for_display('all')
      @syndicate = 'all'
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

  def show
    session[:return_to] = request.fullpath
    @syndicate = session[:syndicate]
    get_user_info_from_userid
    load(params[:id])
  end

  def technical_registration
    if Rails.application.config.member_open
      cookies.signed[:Administrator] = Rails.application.config.github_issues_password
      session[:return_to] = request.fullpath
      session[:first_name] = 'New Registrant'
      session[:type] = "technical_registration"
      @userid = UseridDetail.new
    else
      #we set the mongo_config.yml member open flag. true is open. false is closed We do allow technical people in
      flash[:notice] = "The system is presently undergoing maintenance and is unavailable for registration"
      redirect_to :back
      return
    end
  end

  def transcriber_registration
    if Rails.application.config.member_open
      #we set the mongo_config.yml member open flag. true is open. false is closed We do allow technical people in
      cookies.signed[:Administrator] = Rails.application.config.github_issues_password
      session[:return_to] = request.fullpath
      session[:first_name] = 'New Registrant'
      session[:type] = "transcriber_registration"
      @userid = UseridDetail.new
      @syndicates = Syndicate.get_syndicates_open_for_transcription
      @transcription_agreement = [true,false]
      @first_name = session[:first_name]
    else
      #we set the mongo_config.yml member open flag. true is open. false is closed We do allow technical people in
      flash[:notice] = "The system is presently undergoing maintenance and is unavailable for registration"
      redirect_to :back
      return
    end
  end

  def update
    load(params[:id])
    changed_syndicate = @userid.changed_syndicate?(params[:userid_detail][:syndicate])
    success = Array.new
    success[0] = true
    case
    when params[:commit] == "Disable"
      params[:userid_detail][:disabled_date]  = DateTime.now if  @userid.disabled_date.nil?
      params[:userid_detail][:active]  = false
      params[:userid_detail][:person_role] = params[:userid_detail][:person_role] unless params[:userid_detail][:person_role].nil?
    when params[:commit] == "Update"
      params[:userid_detail][:previous_syndicate] =  @userid.syndicate unless params[:userid_detail][:syndicate] == @userid.syndicate
    when params[:commit] == "Confirm"
      if params[:userid_detail][:email_address_valid] == 'true'
        @userid.update_attributes(email_address_valid: true, email_address_last_confirmned: Time.new)
        redirect_to '/manage_resources/new'
        return
      else
        session[:my_own] = true
        redirect_to :action => 'edit'
        return
      end
    end
    params[:userid_detail][:email_address_last_confirmned]  = Time.now
    params[:userid_detail][:email_address_valid]  = true
    @userid.update_attributes(userid_details_params)
    @userid.write_userid_file
    @userid.save_to_refinery
    if !@userid.errors.any? && success[0]
      UserMailer.send_change_of_syndicate_notification_to_sc(@userid).deliver_now if changed_syndicate
      flash[:notice] = 'The update of the profile was successful'
      redirect_to userid_detail_path(@userid)
      return
    else
      flash[:notice] = "The update of the profile was unsuccessful #{success[1]} #{@userid.errors.full_messages}"
      @syndicates = Syndicate.get_syndicates_open_for_transcription
      render :action => 'edit'
      return
    end
  end

  private

  def userid_details_params
    params.require(:userid_detail).permit!
  end

end
