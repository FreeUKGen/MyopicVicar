class UseridDetailsController < ApplicationController
  require 'userid_role'
  skip_before_filter :require_login, only: [:general, :create,:researcher_registration, :transcriber_registration,:technical_registration]
  rescue_from ActiveRecord::RecordInvalid, :with => :record_validation_errors
  def index
    if params[:page]
     session[:user_index_page] = params[:page]
    end
    session[:return_to] = request.fullpath
    get_user_info_from_userid
    session[:my_own] = false
    @role = session[:role]
    if session[:active] ==  'All Members'
      @userids = UseridDetail.get_userids_for_display(session[:syndicate],params[:page])
    else
      @userids = UseridDetail.get_active_userids_for_display(session[:syndicate],params[:page])
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
    @syndicates = session[:syndicate] if @user.person_role == "syndicate_coordinator" || @user.person_role == "volunteer_coordinator" ||
    @user.person_role == "data_manager" 
    @userid = UseridDetail.new
  end

  def show
    session[:return_to] = request.fullpath
    @syndicate = session[:syndicate]
    get_user_info_from_userid
    load(params[:id])
  end

  def all
    if params[:page]
     session[:user_index_page] = params[:page]
    end
    session[:return_to] = request.fullpath
    get_user_info_from_userid
    @userids = UseridDetail.get_userids_for_display('all',params[:page])
    render "index"
  end

  def my_own
    clean_session
    clean_session_for_county
    clean_session_for_syndicate
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
    cookies.signed[:Administrator] = Rails.application.config.github_password
    session[:return_to] = request.fullpath
    session[:first_name] = 'New Registrant'
    session[:type] = "researcher_registration"
    @userid = UseridDetail.new
    @first_name = session[:first_name]
  end

  def transcriber_registration
    cookies.signed[:Administrator] = Rails.application.config.github_password
    session[:return_to] = request.fullpath
    session[:first_name] = 'New Registrant'
    session[:type] = "transcriber_registration"
    @userid = UseridDetail.new
    @syndicates = Syndicate.get_syndicates_open_for_transcription
    @transcription_agreement = [true,false]
    @first_name = session[:first_name]
  end

  def technical_registration
    cookies.signed[:Administrator] = Rails.application.config.github_password
    session[:return_to] = request.fullpath
    session[:first_name] = 'New Registrant'
    session[:type] = "technical_registration"
    @userid = UseridDetail.new
  end

  def options
    clean_session
    clean_session_for_county
    clean_session_for_syndicate
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
          if params[:page]
            session[:user_index_page] = params[:page]
          end
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
    session[:refinery] = current_refinery_user
    @userid = UseridDetail.new(params[:userid_detail])
    @userid.add_fields(params[:commit],session[:syndicate])
    @userid.save
    if @userid.save
      @userid.send_invitation_to_create_password
      flash[:notice] = 'The initial registration was successful; an email has been sent to the new person to complete the process.'
      @userid.write_userid_file
      next_place_to_go_successful_create
    else
      flash[:notice] = 'The registration was unsuccessful'
      @syndicates = Syndicate.get_syndicates_open_for_transcription
      next_place_to_go_unsuccessful_create
    end
  end

  def update
    load(params[:id])
    success = true
    case 
      when params[:commit] == "Rename" 
        success = false if UseridDetail.where(:userid => params[:userid_detail][:userid]).exists?
        success = Freereg1CsvFile.change_userid(params[:id], @userid.userid, params[:userid_detail][:userid]) if success
      when params[:commit] == "Disable"
        params[:userid_detail][:disabled_date]  = DateTime.now if  @userid.disabled_date.nil?
        params[:userid_detail][:active]  = false
        params[:userid_detail][:person_role] = params[:userid_detail][:person_role] unless params[:userid_detail][:person_role].nil?
     when params[:commit] == "Update"
      params[:userid_detail][:previous_syndicate] =  @userid.syndicate unless params[:userid_detail][:syndicate] == @userid.syndicate
      note_to_send_email_to_sc = false
      note_to_send_email_to_sc = true if params[:userid_detail][:syndicate] != @userid.syndicate
    end
    @userid.update_attributes(params[:userid_detail])
    @userid.write_userid_file
    @userid.save_to_refinery
    if !@userid.errors.any? || success[0]
     UserMailer.send_change_of_syndicate_notification_to_sc(@userid).deliver if note_to_send_email_to_sc
     flash[:notice] = 'The update of the profile was successful'
     redirect_to userid_detail_path(@userid)
     return
    else
      flash[:notice] = "The update of the profile was unsuccessful #{success[1]}"
      @syndicates = Syndicate.get_syndicates_open_for_transcription
      render :action => 'edit'
      return
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
      @userid.destroy
      flash[:notice] = 'The destruction of the profile was successful'
      redirect_to :action => 'options'
    end
  end

  def disable
    session[:return_to] = request.fullpath
    load(params[:id])
    unless @userid.active 
      @userid.update_attributes(:active => true, :disabled_reason => nil, :disabled_date => nil)
      flash[:notice] = "Userid re-activated"
       redirect_to userid_details_path(:anchor => "#{ @userid.id}", :page => "#{session[:user_index_page]}") and return
    end
    session[:type] = "disable"
  end

  def load(userid_id)
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
    @userid = UseridDetail.find(userid_id)
    session[:userid_id] = userid_id
    @syndicate = session[:syndicate]
    @role = session[:role]
  end

  def next_place_to_go_unsuccessful_create
    case
    when  params[:commit] == "Submit"
      @user = UseridDetail.where(userid:  session[:userid]).first
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
      @user = UseridDetail.where(userid:  session[:userid]).first
      render :action => 'new' and return
    end
  end
  
  def next_place_to_go_successful_create
    @userid.finish_creation_setup if params[:commit] == 'Submit'
    @userid.finish_researcher_creation_setup if params[:commit] == 'Register Researcher'
    @userid.finish_transcriber_creation_setup if params[:commit] == 'Register Transcriber'
    @userid.finish_technical_creation_setup if params[:commit] == 'Technical Registration'
    #sending out the password reset destroys the current_user
    current_refinery_user = session[:refinery]
    session.delete(:refinery)
    case
   
    when params[:commit] == "Submit"
      redirect_to userid_details_path(:anchor => "#{ @userid.id}", :page => "#{session[:user_index_page]}") and return
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
