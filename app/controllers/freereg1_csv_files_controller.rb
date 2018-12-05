class Freereg1CsvFilesController < ApplicationController
  require 'chapman_code'
  require 'freereg_options_constants'

  def by_userid
    #entry by userid
    session[:page] = request.original_url
    session[:my_own] = false
    session[:userid_id] = params[:id]
    get_user_info_from_userid
    @county =  session[:county]
    @role = session[:role]
    user = UseridDetail.find(params[:id])
    @who = user.userid
    @role = session[:role]
    @freereg1_csv_files = Freereg1CsvFile.userid(user.userid).all.order_by("file_name ASC", "userid_lower_case ASC").page(params[:page]).per(FreeregOptionsConstants::FILES_PER_PAGE)  unless user.nil?
    render "index"
    return
  end

  def change_userid
    @freereg1_csv_file = Freereg1CsvFile.id(params[:id]).first
    if @freereg1_csv_file.present?
      session[:return_to] = request.original_url
      set_controls(@freereg1_csv_file)
      set_locations
      @records = @freereg1_csv_file.freereg1_csv_entries.count
      @userids = UseridDetail.get_userids_for_selection("all")
    else
      go_back("batch",params[:id])
    end
  end

  def create

  end

  def destroy
    # this removes all batches and the file
    @freereg1_csv_file = Freereg1CsvFile.id(params[:id]).first
    if @freereg1_csv_file.present?
      set_controls(@freereg1_csv_file)
      if @freereg1_csv_file.locked_by_transcriber || @freereg1_csv_file.locked_by_coordinator
        flash[:notice] = 'The deletion of the batch was unsuccessful; the batch is locked'
        redirect_to :back
        return
      end
      if @physical_file.blank?
        flash[:notice] = 'The physical file entry no longer exists. Perhaps you have already deleted it.'
        redirect_to :back
        return
      end
      # save a copy to attic and delete all batches
      @physical_file.file_and_entries_delete
      @freereg1_csv_file.update_freereg_contents_after_processing
      @physical_file.delete
      session[:type] = 'edit'
      flash[:notice] = 'The deletion of the batches was successful'
      if session[:my_own]
        redirect_to my_own_freereg1_csv_file_path
      else
        redirect_to register_path(@return_location)
      end
      return
    else
      go_back('batch', params[:id])
    end
  end

  def display_my_own_files
    get_user_info_from_userid
    @who =  @first_name
    @sorted_by = 'Alphabetical by file name'
    session[:sort] = "file_name ASC"
    session[:sorted_by] = @sorted_by
    @freereg1_csv_files = Freereg1CsvFile.userid(session[:userid]).order_by(session[:sort]).all.page(params[:page]).per(FreeregOptionsConstants::FILES_PER_PAGE)
    render "index"
    return
  end

  def display_my_error_files
    get_user_info_from_userid
    @who =  @first_name
    @sorted_by = 'Ordered by number of errors'
    session[:sorted_by] = @sorted_by
    session[:sort] = "error DESC, file_name ASC"
    @freereg1_csv_files = Freereg1CsvFile.userid(session[:userid]).errors.order_by(session[:sort]).all.page(params[:page]).per(FreeregOptionsConstants::FILES_PER_PAGE)
    render "index"
  end

  def display_my_own_files_by_descending_uploaded_date
    get_user_info_from_userid
    @who =  @first_name
    @sorted_by = 'Ordered by most recent'
    session[:sorted_by] = @sorted_by
    session[:sort] = "uploaded_date DESC"
    @freereg1_csv_files = Freereg1CsvFile.userid(session[:userid]).order_by(session[:sort]).all.page(params[:page]).per(FreeregOptionsConstants::FILES_PER_PAGE)
    render "index"
  end

  def display_my_own_files_by_ascending_uploaded_date
    get_user_info_from_userid
    @who =  @first_name
    @sorted_by = 'Ordered by oldest'
    session[:sort] = "uploaded_date ASC"
    session[:sorted_by] = @sorted_by
    @freereg1_csv_files = Freereg1CsvFile.userid(session[:userid]).order_by(session[:sort]).all.page(params[:page]).per(FreeregOptionsConstants::FILES_PER_PAGE)
    render "index"
  end

  def display_my_own_files_by_selection
    get_user_info_from_userid
    @who =  @first_name
    @freereg1_csv_file = Freereg1CsvFile.new
    @freereg1_csv_files = Freereg1CsvFile.userid(@user.userid).order_by("file_name ASC").all
    @files = Hash.new
    @freereg1_csv_files.each do |file|
      @files[":#{file.file_name}"] = file._id unless file.file_name.nil?
    end
    @options = @files
    @location = 'location.href= "/freereg1_csv_files/" + this.value'
    @prompt = 'Select batch'
    render '_form_for_selection'
  end

  def display_my_own_files_waiting_to_be_processed
    get_user_info_from_userid
    @who =  @first_name
    @batches = PhysicalFile.userid(@user.userid).waiting.all.order_by("waiting_date DESC")
  end

  def download
    @freereg1_csv_file = Freereg1CsvFile.id(params[:id]).first
    if  @freereg1_csv_file.present?
      ok_to_proceed = @freereg1_csv_file.check_file
      if !ok_to_proceed[0]
        flash[:notice] =  "There is a problem with the file you are attempting to download; #{ok_to_proceed[1]}. Contact a system administrator if you are concerned."
      else
        success = @freereg1_csv_file.backup_file
        if success
          my_file =  File.join(Rails.application.config.datafiles, @freereg1_csv_file.userid,@freereg1_csv_file.file_name)
          if File.file?(my_file)
            @freereg1_csv_file.update_attributes(:digest => Digest::MD5.file(my_file).hexdigest)
            @freereg1_csv_file.force_unlock
            flash[:notice] =  "The file has been downloaded to your computer"
            send_file( my_file, :filename =>  @freereg1_csv_file.file_name,:x_sendfile=>true ) and return
          end
        else
          flash[:notice] =  "There was a problem saving the file prior to download. Please take this message to your coordinator"
        end
      end
    else
      flash[:notice] =  "The file has you are attempting to download does not exist"
    end
    redirect_to :back
    return
  end

  def edit
    #edit the headers for a batch
    @freereg1_csv_file = Freereg1CsvFile.id(params[:id]).first
    if @freereg1_csv_file.present?
      session[:return_to] = request.original_url
      set_controls(@freereg1_csv_file)
      unless session[:error_line].nil?
        flash[:notice] = "Header and Place name errors can only be corrected by correcting the file and either replacing or uploading a new file"
        #we are dealing with the edit of errors
        redirect_to :action => 'show'
        return
      end
      #we are correcting the header
      #session role is used to control return navigation options
      @role = session[:role]
      get_places_for_menu_selection
    else
      go_back("batch",params[:id])
    end
  end

  def error
    #display the errors in a batch
    @freereg1_csv_file = Freereg1CsvFile.id(params[:id]).first
    if @freereg1_csv_file.present?
      set_controls(@freereg1_csv_file)
      get_errors_for_error_display
    else
      go_back("batch",params[:id])
    end
  end

  def get_errors_for_error_display
    @errors = @freereg1_csv_file.batch_errors.count
    @owner = @freereg1_csv_file.userid
    unless @errors == 0
      lines = @freereg1_csv_file.batch_errors.all
      @role = session[:role]
      @lines = Array.new
      @system = Array.new
      @header = Array.new
      lines.each do |line|
        #need to check this
        #entry = Freereg1CsvEntry.where(freereg1_csv_file_id:  @freereg1_csv_file._id).first
        @lines << line if line.error_type == 'Data_Error'
        @system << line if line.error_type == 'System_Error'
        @header << line if line.error_type == 'Header_Error'
      end
    end
  end

  def index
    #the common listing entry by syndicates
    @register = session[:register_id]
    get_user_info_from_userid
    @county =  session[:county] unless session[:county].nil?
    @syndicate =  session[:syndicate] unless session[:syndicate].nil?
    @role = session[:role]
    @sorted_by = session[:sorted_by]
    case
    when session[:syndicate].present? && session[:userid_id].blank? &&
        (session[:role] == "county_coordinator" || session[:role] == "system_administrator" || session[:role] == "technical" || session[:role] == "country_coordinator" ||
         session[:role] == "volunteer_coordinator" || session[:role] == "syndicate_coordinator" || session[:role] == 'data_manager' || session[:role] == "documentation_coordinator") &&
        session[:sorted_by] == '; sorted by descending number of errors and then file name'
      userids = Syndicate.get_userids_for_syndicate(session[:syndicate])
      @freereg1_csv_files = Freereg1CsvFile.in(userid: userids).gt(error: 0).order_by(session[:sort]).all.page(params[:page]).per(FreeregOptionsConstants::FILES_PER_PAGE)
    when session[:syndicate].present? && session[:userid_id].blank? &&
        (session[:role] == "county_coordinator" || session[:role] == "system_administrator" || session[:role] == "technical" || session[:role] == "country_coordinator" ||
         session[:role] == "volunteer_coordinator" || session[:role] == "syndicate_coordinator" || session[:role] == 'data_manager' || session[:role] == "documentation_coordinator")
        userids = Syndicate.get_userids_for_syndicate(session[:syndicate])
      @freereg1_csv_files = Freereg1CsvFile.in(userid: userids).order_by(session[:sort]).all.page(params[:page]).per(FreeregOptionsConstants::FILES_PER_PAGE).includes(:freereg1_csv_entries)
    when session[:syndicate].present? && session[:userid_id].present? &&
        (session[:role] == "county_coordinator" || session[:role] == "system_administrator" || session[:role] == "technical" || session[:role] == "country_coordinator" ||
         session[:role] == "volunteer_coordinator" || session[:role] == "syndicate_coordinator" || session[:role] == 'data_manager' || session[:role] == "documentation_coordinator")
        @freereg1_csv_files = Freereg1CsvFile.userid(UseridDetail.find(session[:userid_id]).userid).no_timeout.order_by(session[:sort]).all.page(params[:page]).per(FreeregOptionsConstants::FILES_PER_PAGE)
    when session[:county].present? &&
        (session[:role] == 'county_coordinator' || session[:role] == "system_administrator" || session[:role] == "country_coordinator" ||
         session[:role] == "technical" || session[:role] == 'data_manager' || session[:role] == "documentation_coordinator") && session[:sorted_by] == '; sorted by descending number of errors and then file name'
      @freereg1_csv_files = Freereg1CsvFile.county(session[:chapman_code]).gt(error: 0).order_by(session[:sort]).all.page(params[:page]).per(FreeregOptionsConstants::FILES_PER_PAGE)
    when session[:county].present? &&
        (session[:role] == 'county_coordinator' || session[:role] == "system_administrator" || session[:role] == "technical" || session[:role] == 'data_manager' ||
         session[:role] == "country_coordinator" || session[:role] == "documentation_coordinator")
        time_start = Time.now
      @freereg1_csv_files = Freereg1CsvFile.county(session[:chapman_code]).no_timeout.order_by(session[:sort]).all.page(params[:page]).per(FreeregOptionsConstants::FILES_PER_PAGE)
      time_to_process = Time.now - time_start
      logger.warn "FREEREG::FILES::INDEX time to retrieve #{time_to_process}  sort #{session[:sort]}"
    end
    session[:current_page] = @freereg1_csv_files.current_page unless @freereg1_csv_files.nil?
  end

  def lock
    #lock/unlock a file
    @freereg1_csv_file = Freereg1CsvFile.id(params[:id]).first
    if @freereg1_csv_file.present?
      set_controls(@freereg1_csv_file)
      @freereg1_csv_file.lock(session[:my_own])
      flash[:notice] = 'The lock change to all the batches in the file was successful'
      redirect_to :back
      return
    else
      go_back("batch",params[:id])
    end
  end

  def merge
    @freereg1_csv_file = Freereg1CsvFile.id(params[:id]).first
    if @freereg1_csv_file.present?
      set_controls(@freereg1_csv_file)
      errors = @freereg1_csv_file.merge_batches
      if errors[0]  then
        flash[:notice] = "Merge unsuccessful; #{errors[1]}"
        render :action => 'show'
        return
      end
      success = @freereg1_csv_file.calculate_distribution
      @freereg1_csv_file.update_freereg_contents_after_processing
      if success
        flash[:notice] = 'The merge of the batches was successful'
      else
        flash[:notice] = 'The recalculation of the number of records and distribution was unsuccessful'
      end
      redirect_to freereg1_csv_file_path(@freereg1_csv_file)
      return
    else
      go_back("batch",params[:id])
    end
  end

  def my_own
    clean_session
    clean_session_for_county
    clean_session_for_syndicate
    get_user_info_from_userid
    session[:my_own] = true
    @who =  @first_name
    @sorted_by = 'Ordered by most recent'
    session[:sorted_by] = @sorted_by
    session[:sort] = "uploaded_date DESC"
    @freereg1_csv_files = Freereg1CsvFile.userid(session[:userid]).order_by(session[:sort]).all.page(params[:page]).per(FreeregOptionsConstants::FILES_PER_PAGE)
    render "index"
  end

  def relocate
    @freereg1_csv_file = Freereg1CsvFile.id(params[:id]).first
    session[:return_to] = request.original_url
    if @freereg1_csv_file.present?
      set_controls(@freereg1_csv_file)
      session[:initial_page] = @return_location
      session[:selectcountry] = nil
      session[:selectcounty] = nil
      @records = @freereg1_csv_file.freereg1_csv_entries.count
      max_records = get_max_records(@user)
      if @records.present? && @records.to_i >= max_records
        flash[:notice] = 'There are too many records for an on-line relocation'
        redirect_to :action => 'show' and return
      end
      session[:records] = @records
      unless  @user.person_role == 'system_administrator' || @user.person_role == 'data_manager'
        # only senior managers can move between counties and countries; coordinators could loose files
        place = @freereg1_csv_file.register.church.place
        session[:selectcountry] = place.country
        session[:selectcounty] = place.chapman_code
        redirect_to :action => 'update_places' and return
      else
        @county =  session[:county]
        set_locations
        #setting these means that we are a DM
        session[:selectcountry] = nil
        session[:selectcounty] = nil
        session[:selectplace] = session[:selectchurch] = nil
        @countries = ['Select Country','England', 'Islands', 'Scotland', 'Wales']
        @counties = Array.new
        @placenames = Array.new
        @churches = Array.new
        @register_types = []
        @selected_place = @selected_church = @selected_register = ''
      end
    else
      go_back("batch",params[:id])
    end
  end



  def remove
    #this just removes a batch of records it leaves the entries and search records there to be removed by a rake task
    @freereg1_csv_file = Freereg1CsvFile.id(params[:id]).first
    if @freereg1_csv_file.present?
      set_controls(@freereg1_csv_file)
      success, message = @freereg1_csv_file.remove_batch
      if success
        flash[:notice] = 'The removal of the batch entry was successful'
      else
        flash[:notice] = message
      end
      if @return_location.nil?
        redirect_to manage_resource_path(@user)
        return
      else
        redirect_to register_path(@return_location)
        return
      end
    else
      #no id
      go_back("batch",params[:id])
    end
  end

  def set_controls(file)
    get_user_info_from_userid
    @physical_file = PhysicalFile.userid(file.userid).file_name(file.file_name).first
    @role = session[:role]
    @freereg1_csv_file_name = file.file_name
    session[:freereg1_csv_file_id] =  file._id
    @return_location  = file.register.id unless file.register.nil?
  end

  def set_locations
    @update_counties_location = 'location.href= "/freereg1_csv_files/update_counties?country=" + this.value'
    @update_places_location = 'location.href= "/freereg1_csv_files/update_places?county=" + this.value'
    @update_churches_location = 'location.href= "/freereg1_csv_files/update_churches?place=" + this.value'
    @update_registers_location = 'location.href= "/freereg1_csv_files/update_registers?church=" + this.value'
  end

  def show
    #show an individual batch
    @freereg1_csv_file = Freereg1CsvFile.id(params[:id]).first
    if @freereg1_csv_file.present?
      set_controls(@freereg1_csv_file)
    else
      go_back("batch",params[:id])
    end
  end



  def update_churches
    if update_churches_not_ok?(params[:place])
      flash[:notice] = "You made an incorrect place selection "
      redirect_to relocate_freereg1_csv_file_path(session[:freereg1_csv_file_id]) and return
    else
      get_user_info_from_userid
      set_locations
      @freereg1_csv_file = Freereg1CsvFile.find(session[:freereg1_csv_file_id])
      @countries = [session[:selectcountry]]
      @counties = [session[:selectcounty]]
      place = Place.id(params[:place]).first
      session[:selectplace] = params[:place]
      @placenames = Array.new
      @placenames  << place.place_name
      @churches = place.churches.map{|a| [a.church_name, a.id]}.insert(0, "Select Church")
      @churches[1] = "Has no churches" if place.churches.blank?
      @freereg1_csv_file.county == session[:selectcounty] && session[:selectplace] == @freereg1_csv_file.place ? @selected_church = @freereg1_csv_file.church_name : @selected_place = ""
      @selected_place = session[:selectplace]
      @register_types = RegisterType::APPROVED_OPTIONS
      @selected_register = ''
    end
  end

  def update_churches_not_ok?(param)
    result = false
    result = true if param.blank? || param == "Select Place" || session[:selectcountry].blank? || session[:selectcounty].blank? || session[:freereg1_csv_file_id].blank?
    result
  end


  def update_counties
    if update_counties_not_ok?(params[:country])
      flash[:notice] = "You made an incorrect country selection "
      redirect_to relocate_freereg1_csv_file_path(session[:freereg1_csv_file_id]) and return
    else
      get_user_info_from_userid
      set_locations
      @freereg1_csv_file = Freereg1CsvFile.find(session[:freereg1_csv_file_id])
      @countries = [params[:country]]
      session[:selectcountry] = params[:country]
      @counties = ChapmanCode::CODES[params[:country]].keys.insert(0, "Select County")
      @placenames = Array.new
      @churches = Array.new
      @register_types = RegisterType::APPROVED_OPTIONS
      @selected_county = @freereg1_csv_file.county
      @selected_place = @selected_church = @selected_register = ''
    end
  end

  def update_counties_not_ok?(param)
    result = false
    result = true if param.blank? || param == "Select Country"  || session[:freereg1_csv_file_id].blank?
    result
  end


  def update_places
    get_user_info_from_userid
    if  (@user.person_role == 'system_administrator' || @user.person_role == 'data_manager')
      if update_places_not_ok?(params[:county])
        flash[:notice] = "You made an incorrect county selection "
        redirect_to relocate_freereg1_csv_file_path(session[:freereg1_csv_file_id]) and return
      end
    end
    set_locations
    @freereg1_csv_file = Freereg1CsvFile.find(session[:freereg1_csv_file_id])
    @countries = [session[:selectcountry]]
    if session[:selectcounty].nil?
      #means we are a DM selecting the county
      session[:selectcounty] = ChapmanCode::CODES[session[:selectcountry]][params[:county]]
      places = Place.chapman_code(session[:selectcounty]).not_disabled.all.order_by(place_name: 1)
    else
      #we are a CC
      places = Place.chapman_code(session[:selectcounty]).not_disabled.all.order_by(place_name: 1)
    end
    @counties = Array.new
    if @freereg1_csv_file.county == session[:selectcounty]
      @selected_place = @freereg1_csv_file.place
      @selected_church = @freereg1_csv_file.church_name
    else
      @selected_place = @selected_church = ""
    end
    @counties << session[:selectcounty]
    @placenames = places.map{|a| [a.place_name, a.id]}.insert(0, "Select Place")
    @placechurches = Place.chapman_code(session[:selectcounty]).place(@freereg1_csv_file.place).not_disabled.first
    if @placechurches.present?
      @churches = @placechurches.churches.map{|a| [a.church_name, a.id]}
    else
      @churches = []
    end
    @register_types = RegisterType::APPROVED_OPTIONS
    @selected_register = ''

  end

  def update_places_not_ok?(param)
    result = false
    result = true if param.blank? || param == "Select County" || session[:selectcountry].blank?  || session[:freereg1_csv_file_id].blank?
    return result
  end


  def update_registers
    if update_registers_not_ok?(params[:church])
      flash[:notice] = "You made an incorrect church selection "
      redirect_to relocate_freereg1_csv_file_path(session[:freereg1_csv_file_id]) and return
    else
      get_user_info_from_userid
      set_locations
      @freereg1_csv_file = Freereg1CsvFile.find(session[:freereg1_csv_file_id])
      @countries = [session[:selectcountry]]
      @counties = [session[:selectcounty]]
      church = Church.id(params[:church]).first
      session[:selectchurch] = params[:church]
      place = church.place
      @placenames = Array.new
      @placenames  << place.place_name
      @churches = Array.new
      @churches << church.church_name
      @register_types = RegisterType::APPROVED_OPTIONS
      @selected_place = session[:selectplace]
      @selected_church = session[:selectchurch]
      @selected_register = ''
    end
  end

  def update_registers_not_ok?(param)
    result = false
    result = true if param.blank? || param == "Has no churches" || param == "Select Church" || session[:selectcountry].blank? || session[:selectcounty].blank? || session[:selectplace].blank? || session[:freereg1_csv_file_id].blank?
    result
  end

  def update
    #update the headers
    @freereg1_csv_file = Freereg1CsvFile.id(params[:id]).first
    if @freereg1_csv_file.present?
      set_controls(@freereg1_csv_file)
      case params[:commit]
      when 'Change Userid'
        flash[:notice] = "Cannot select a blank userid" if params[:freereg1_csv_file][:userid].blank?
        redirect_to :action => "change_userid" and return if params[:freereg1_csv_file][:userid].blank?
        success = @freereg1_csv_file.change_owner_of_file(params[:freereg1_csv_file][:userid])
        if !success[0]
          flash[:notice] = "The change of userid was unsuccessful: #{success[1]}"
          redirect_to change_userid_freereg1_csv_file_path(@freereg1_csv_file)
          return
        else
          flash[:notice] = "The change of userid was successful #{success[1]} "
        end
      when 'Submit'
        #lets see if we are moving the file
        @freereg1_csv_file.date_change(params[:freereg1_csv_file][:transcription_date],params[:freereg1_csv_file][:modification_date])
        @freereg1_csv_file.check_locking_and_set(params[:freereg1_csv_file],session)
        @freereg1_csv_file.update_attributes(:alternate_register_name => (params[:freereg1_csv_file][:church_name].to_s + ' ' + params[:freereg1_csv_file][:register_type].to_s ))
        @freereg1_csv_file.update_attributes(freereg1_csv_file_params)
        @freereg1_csv_file.update_attributes(:modification_date => Time.now.strftime("%d %b %Y"))
        @freereg1_csv_file.update_freereg_contents_after_processing
        if @freereg1_csv_file.errors.any?  then
          flash[:notice] = 'The update of the batch was unsuccessful'
          render :action => 'edit'
          return
        end
        unless session[:error_line].nil?
          #lets remove the header errors
          @freereg1_csv_file.error =  @freereg1_csv_file.error - session[:header_errors]
          session[:error_id].each do |id|
            error = BatchError.id(id).first
            @freereg1_csv_file.batch_errors.delete( error)
          end
          @freereg1_csv_file.save
          #clean out the session variables
          session[:error_id] = nil
          session[:header_errors] = nil
          session[:error_line] = nil
        else
          session[:type] = "edit"
          flash[:notice] = 'The update of the batch was successful'
          @current_page = session[:page]
          session[:page] = session[:initial_page]
        end
      when 'Relocate'
        errors =  Freereg1CsvFile.file_update_location(@freereg1_csv_file,params[:freereg1_csv_file],session)
        if errors[0]
          flash[:notice] = errors[1]
          redirect_to :action => "relocate"
          return
        else
          flash[:notice] = 'The relocation of the batch was successful'
        end
      end
      redirect_to session[:return_to]
      return
    else
      go_back("batch",params[:id])
    end
  end

  def unique_names
    @freereg1_csv_file = Freereg1CsvFile.id(params[:object]).first
    if @freereg1_csv_file.present?
      set_controls(@freereg1_csv_file)
    else
      go_back("batch",params[:id])
    end
    @freereg1_csv_entries = @freereg1_csv_file.get_unique_names
  end

  def zero_year




    #                    Not sure it is used

    # get the entries with a zero year
    @freereg1_csv_file = Freereg1CsvFile.id(params[:id]).first
    if @freereg1_csv_file.present?
      set_controls(@freereg1_csv_file)
    else
      go_back('batch', params[:id])
    end
    @freereg1_csv_entries = @freereg1_csv_file.zero_year_entries
    display_info
    @zero_year = true
    render 'freereg1_csv_entries/index'
  end

  def show_zero_startyear_entries
    file_id = params[:id]
    @freereg1_csv_file = Freereg1CsvFile.where(id: file_id).first
    @freereg1_csv_entries = @freereg1_csv_file.get_zero_year_records
    display_info
    @get_zero_year_records = true
    render 'freereg1_csv_entries/index'
  end

  private
  def freereg1_csv_file_params
    params.require(:freereg1_csv_file).permit!
  end

  def display_info
    @freereg1_csv_file_id =  @freereg1_csv_file.id
    @freereg1_csv_file_name =  @freereg1_csv_file.file_name
    @file_owner = @freereg1_csv_file.userid
    @register = @freereg1_csv_file.register
    @register_name = RegisterType.display_name(@register.register_type)
    @church = @register.church #id?
    @church_name = @church.church_name
    @place = @church.place #id?
    @county =  @place.county
    @place_name = @place.place_name
    @user = get_user
    @first_name = @user.person_forename unless @user.blank?
  end

end
