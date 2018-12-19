class UseridDetailsController < ApplicationController
  include ActiveModel::Dirty
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
      redirect_to userid_detail_path(@userid, page_name: params[:page_name]) and return
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
    if spam_check
      @userid = UseridDetail.new(userid_details_params)
      @userid.add_fields(params[:commit], session[:syndicate])
      @userid.save
      if @userid.save
        refinery_user = Refinery::Authentication::Devise::User.where(:username => @userid.userid).first
        refinery_user.send_reset_password_instructions
        flash[:notice] = 'The initial registration was successful; an email has been sent to you to complete the process.'
        @userid.write_userid_file
        next_place_to_go_successful_create
      else
        flash[:notice] = 'The registration was unsuccessful'
        @syndicates = Syndicate.get_syndicates_open_for_transcription
        next_place_to_go_unsuccessful_create
      end
    else
      render :status => 404
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
    @current_user = get_user
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
    @user = get_user
    @first_name = @user.person_forename unless @user.blank?
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
    if @user.person_role == "syndicate_coordinator"
      @syndicates = Array.new
      @syndicates[0] = session[:syndicate]
    elsif ['system_administrator', 'executive_director', 'project_manager', 'volunteer_coordinator'].include?(@user.person_role)
      @syndicates = Syndicate.get_syndicates
    else
      @syndicates = Syndicate.get_syndicates_open_for_transcription
    end
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
    respond_to do |format|
      format.html
      format.json do
        json_of_my_profile = @userid.json_of_my_profile
        send_data json_of_my_profile, :type => 'application/txt; header=present', :disposition => "attachment; filename=my_profile.txt"
      end
    end
  end

  def next_place_to_go_successful_create
    @userid.finish_creation_setup if params[:commit] == 'Register as Transcriber'
    @userid.finish_researcher_creation_setup if params[:commit] == 'Register Researcher'
    @userid.finish_technical_creation_setup if params[:commit] == 'Technical Registration'
    case
    when  params[:commit] == 'Register as Transcriber'
      redirect_to transcriber_registration_userid_detail_path and return
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
      @user = get_user
      @first_name = @user.person_forename unless @user.blank?
      render :action => 'new' and return
    when params[:commit] == 'Register Researcher'
      render :action => 'researcher_registration' and return
    when params[:commit] == 'Register as Transcriber'
      @syndicates = Syndicate.get_syndicates_open_for_transcription
      @userid[:honeypot] = session[:honeypot]
      #@new_transcription_agreement = ["Unknown","Accepted","Declined","Requested"]
      render :action => 'transcriber_registration' and return
    when params[:commit] == 'Technical Registration'
      render :action => 'technical_registration' and return
    else
      @user = get_user
      @first_name = @user.person_forename unless @user.blank?
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

  def secondary_roles
    session[:return_to] = request.fullpath
    get_user_info_from_userid
    @userid = UseridDetail.new
    @options = UseridRole::VALUES
    @prompt = 'Select Secondary Role?'
    @location = 'location.href= "secondary?role=" + this.value'
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
      redirect_to new_search_query_path
      return
    end
  end

  def role
    @userids = UseridDetail.role(params[:role]).all.order_by(userid_lower_case: 1)
    @syndicate = " #{params[:role]}"
    @sorted_by = " lower case userid"
  end

  def secondary
    @userids = UseridDetail.secondary(params[:role]).all.order_by(userid_lower_case: 1)
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
        redirect_to userid_detail_path(userid, option: params[:option])
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
        redirect_to userid_detail_path(userid, option: params[:option])
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
          redirect_to userid_detail_path(userid, option: params[:option])
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
      params[:syndicate].present? ? @syndicate = params[:syndicate] : @syndicate = 'all'
      @userids = UseridDetail.get_emails_for_selection(@syndicate)
      @location = 'location.href= "select?email=" + this.value'
      @prompt = "Please select an email address from the following list for #{session[:syndicate]}"
    when params[:option] == "Select specific userid"
      params[:syndicate].present? ? @syndicate = params[:syndicate] : @syndicate = 'all'
      @userids = UseridDetail.get_userids_for_selection(@syndicate)
      @location = 'location.href= "select?userid=" + this.value'
      @prompt = "Select userid for #{session[:syndicate]}"
    when params[:option] == "Select specific surname/forename"
      params[:syndicate].present? ? @syndicate = params[:syndicate] : @syndicate = 'all'
      @userids = UseridDetail.get_names_for_selection(@syndicate)
      @location = 'location.href= "select?name=" + this.value'
      @prompt = "Select surname/forename for #{session[:syndicate]}"
    else
      flash[:notice] = 'Invalid option'
      params[:option] = nil
      redirect_to :back
      return
    end
    @location = get_option_parameter(params[:option], @location)
    params[:option] = nil
    @manage_syndicate = session[:syndicate]
  end

  def show
    session[:return_to] = request.fullpath
    @syndicate = session[:syndicate]
    get_user_info_from_userid
    load(params[:id])
    @page_name = params[:page_name]
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
      redirect_to new_search_query_path
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
      honeypot = "agreement_" + rand.to_s[2..11]
      session[:honeypot] = honeypot

      @userid = UseridDetail.new
      @userid[:honeypot] = session[:honeypot]
      @syndicates = Syndicate.get_syndicates_open_for_transcription
      @new_transcription_agreement = ["Unknown","Accepted","Declined","Requested"]
      @first_name = session[:first_name]
    else
      #we set the mongo_config.yml member open flag. true is open. false is closed We do allow technical people in
      flash[:notice] = "The system is presently undergoing maintenance and is unavailable for registration"
      redirect_to new_search_query_path
      return
    end
  end

  def update
    load(params[:id])
    changed_syndicate = @userid.changed_syndicate?(params[:userid_detail][:syndicate])
    changed_email_address = @userid.changed_email?(params[:userid_detail][:email_address])
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
        @userid.update_attributes(email_address_valid: true, email_address_last_confirmned: Time.new, email_address_validity_change_message: Array.new)
        redirect_to '/manage_resources/new'
        return
      else
        session[:my_own] = true
        redirect_to edit_userid_detail_path(@userid)
        return
      end
    end
    email_valid_change_message
    params[:userid_detail][:email_address_last_confirmned] = ['1', 'true'].include?(params[:userid_detail][:email_address_valid]) ? Time.now : ''
    #    params[:userid_detail][:email_address_valid]  = true
    @userid.update_attributes(userid_details_params)
    @userid.write_userid_file
    @userid.save_to_refinery
    if !@userid.errors.any? && success[0]
      UserMailer.send_change_of_syndicate_notification_to_sc(@userid).deliver_now if changed_syndicate
      UserMailer.send_change_of_email_notification_to_sc(@userid).deliver_now if changed_email_address
      flash[:notice] = 'The update of the profile was successful'
      redirect_to userid_detail_path(@userid, page_name: params[:page_name])
      return
    else
      flash[:notice] = "The update of the profile was unsuccessful #{success[1]} #{@userid.errors.full_messages}"
      @syndicates = Syndicate.get_syndicates_open_for_transcription
      redirect_to edit_userid_detail_path(@userid)
      return
    end
  end

  def incomplete_registrations
    @current_syndicate = session[:syndicate]
    @current_user = get_user
    session[:edit_userid] = true
    user = UseridDetail.new

    if permitted_users?
      @incomplete_registrations = user.list_incomplete_registrations(@current_user, @current_syndicate)
      render :template => 'shared/incomplete_registrations'
    else
      flash[:notice] = 'Sorry, You are not authorized for this action'
      redirect_to '/manage_resources/new'
    end
  end

  def return_total_transcriber_records
    total_records = 0
    UseridDetail.where(person_role: "transcriber", new_transcription_agreement: "Accepted", number_of_records: {'$ne': 0}).each do |count|
      total_records += count.number_of_records
    end
    return total_records
  end

  def return_total_records
    total_records = 0
    UseridDetail.where(number_of_records: {'$ne': 0}).each do |count|
      total_records += count.number_of_records
    end
    return total_records
  end

  def return_percentage_total_records_by_transcribers
    total_records_all = return_total_records.to_f
    total_records_open_transcribers = return_total_transcriber_records.to_f
    if total_records_all == 0 || total_records_open_transcribers == 0
      return 0
    else
      return ((total_records_open_transcribers / total_records_all) * 100).round(2)
    end
  end

  def return_percentage_all_users_accepted_transcriber_agreement
    total_users = UseridDetail.count.to_f
    total_users_accepted = UseridDetail.where(new_transcription_agreement: "Accepted").count.to_f
    if total_users == 0 || total_users_accepted == 0
      return 0
    else
      return ((total_users_accepted / total_users) * 100).round(2)
    end
  end

  def return_percentage_all_existing_users_accepted_transcriber_agreement
    total_existing_users = UseridDetail.where(sign_up_date: {'$lt': DateTime.new(2017, 10, 17)}).count.to_f
    total_existing_users_accepted = UseridDetail.where(new_transcription_agreement: "Accepted", sign_up_date: {'$lt': DateTime.new(2017, 10, 17)}).count.to_f
    if total_existing_users == 0 || total_existing_users_accepted == 0
      return 0
    else
      return ((total_existing_users_accepted / total_existing_users) * 100).round(2)
    end
  end

  def return_percentage_all_existing_active_users_accepted_transcriber_agreement
    total_existing_active_users = UseridDetail.where(active: true, sign_up_date: {'$lt': DateTime.new(2017, 10, 17)}).count.to_f
    total_existing_active_users_accepted = UseridDetail.where(active: true, new_transcription_agreement: "Accepted", sign_up_date: {'$lt': DateTime.new(2017, 10, 17)}).count.to_f
    if total_existing_active_users == 0 || total_existing_active_users_accepted == 0
      return 0
    else
      return ((total_existing_active_users_accepted / total_existing_active_users) * 100).round(2)
    end
  end


  def transcriber_statistics
    @current_user = get_user
    if stats_permitted_users?
      @total_users = UseridDetail.count
      @total_transcribers = UseridDetail.where(person_role: "transcriber").count
      @total_transcribers_accepted_agreement = UseridDetail.where(person_role: "transcriber", new_transcription_agreement: "Accepted").count
      @total_active_transcribers = UseridDetail.where(person_role: "transcriber", active: true).count
      @users_never_uploaded_file = UseridDetail.where(number_of_files: 0).count
      @users_uploaded_file = UseridDetail.where(number_of_files: {'$ne': 0}).count
      @transcribers_never_uploaded_file = UseridDetail.where(person_role: "transcriber",number_of_files: 0).count
      @transcriber_uploaded_file = UseridDetail.where(person_role: "transcriber",number_of_files: {'$ne': 0}).count
      @incomplete_registrations = UseridDetail.new.incomplete_user_registrations_count
      @incomplete_transcriber_registrations = UseridDetail.new.incomplete_transcribers_registrations_count
      # New statistics
      @total_records_transcribers = return_total_transcriber_records
      @percentage_total_records_by_transcribers = return_percentage_total_records_by_transcribers
      @total_transcribers_accepted_agreement_no_records = UseridDetail.where(person_role: "transcriber", new_transcription_agreement: "Accepted", number_of_records: 0).count
      @percentage_all_users_who_accepted_transcription_agreement = return_percentage_all_users_accepted_transcriber_agreement
      @percentage_existing_users_who_accepted_transcription_agreement = return_percentage_all_existing_users_accepted_transcriber_agreement
      @percentage_active_existing_users_who_accepted_transcription_agreement = return_percentage_all_existing_active_users_accepted_transcriber_agreement
      @new_users_last_30_days = UseridDetail.where(sign_up_date: {'$gt': DateTime.now - 30.days }).count
      @new_users_last_90_days = UseridDetail.where(sign_up_date: {'$gt': DateTime.now - 90.days }).count
    else
      flash[:notice] = 'Sorry, You are not authorized for this action'
      redirect_to '/manage_resources/new'
    end
  end

  private

  def userid_details_params
    params.require(:userid_detail).permit!
  end

  def spam_check
    user = get_user
    return true if user.present?
    honeypot_error = true
    diff = Time.now - Time.parse(params[:__TIME])

    params.each do |k,x|
      if k.include? session[:honeypot]
        honeypot_error = false if x == ''
      end
    end

    if honeypot_error || diff <= 5
      error_file = "log/spam_check_error_messages.log"
      f = File.exists?(error_file) ? File.open(error_file, "a+") : File.new(error_file, "w")
      error_text = "===========SPAM caught at " + Time.now.to_s

      if honeypot_error
        error_text = error_text+" honeypot error detected"
      end
      if diff <= 5
        error_text = error_text+" submission time is "+diff.to_s+" seconds"
      end

      error_text = error_text+"\r\nEMAIL: "+params[:userid_detail][:email_address]+"\r\n"
      error_text = error_text+"USERID: "+params[:userid_detail][:userid]+"\r\n"
      error_text = error_text+"FORENAME: "+params[:userid_detail][:person_forename]+"\r\n"
      error_text = error_text+"SURNAME: "+params[:userid_detail][:person_surname] + "\r\n"
      error_text = error_text+"REMOE ADDR: "+request.remote_addr + "\r\n" if request.present? && request.remote_addr.present?
      error_text = error_text+"REMOE ADDR: Unknown \r\n" unless request.present? && request.remote_addr.present?
      error_text = error_text+"REMOTE IP: "+request.remote_ip + "\r\n" if request.present? && request.remote_ip.present?
      error_text = error_text+"REMOE IP: Unknown \r\n" unless request.present? && request.remote_ip.present?
      error_text = error_text+"REMOTE HOST: "+request.remote_host+"\r\n\r\n\r\n" if request.present? && request.remote_host.present?
      error_text = error_text+"REMOE HOST: Unknown \r\n" unless request.present? && request.remote_host.present?
      f.puts error_text
      f.close
      return false
    end
    return true
  end

  def permitted_users?
    ['system_administrator', 'syndicate_coordinator', 'county_coordinator', 'country_coordinator'].include? @current_user.person_role
  end

  def stats_permitted_users?
    ['system_administrator', 'executive_director', 'project_manager'].include? @current_user.person_role
  end

  def get_option_parameter(option, location)
    location += '+"&option=' + option +'"'
  end

  def email_value_changed
    @userid.email_address_valid.to_s != userid_details_params[:email_address_valid]
  end

  def email_valid_change_message
    if email_value_changed
      message = @userid.email_address_validity_change_message
      case userid_details_params[:email_address_valid]
      when "true"
        raise "hello"
        message << "VALID on #{Time.now.utc.strftime("%B %d, %Y")} at #{Time.now.utc.strftime("%H:%M:%S")}"
      else
        message << "INVALID on #{Time.now.utc.strftime("%B %d, %Y")} at #{Time.now.utc.strftime("%H:%M:%S")}"
      end
      @userid.update_attribute(:email_address_validity_change_message, message)
    end
  end

  def email_valid_change
    @userid.email_address_valid == true ? "Valid" : "Invalid"
  end
end
