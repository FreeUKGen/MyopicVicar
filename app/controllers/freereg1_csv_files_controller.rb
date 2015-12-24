class Freereg1CsvFilesController < ApplicationController
  require 'chapman_code'
  require 'freereg_options_constants'
  def index
    #the common listing entry by syndicates
    @register = session[:register_id]
    get_user_info_from_userid
    @county =  session[:county] unless session[:county].nil?
    @syndicate =  session[:syndicate] unless session[:syndicate].nil?
    @role = session[:role]
    @sorted_by = session[:sorted_by]
    case
      when session[:my_own]
        @who =  @first_name
        @freereg1_csv_files = Freereg1CsvFile.userid(session[:userid]).order_by(session[:sort]).all.page(params[:page]).per(FreeregOptionsConstants::FILES_PER_PAGE)
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
        @freereg1_csv_files = Freereg1CsvFile.in(userid: userids).order_by(session[:sort]).all.page(params[:page]).per(FreeregOptionsConstants::FILES_PER_PAGE)
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
        @freereg1_csv_files = Freereg1CsvFile.county(session[:chapman_code]).no_timeout.order_by(session[:sort]).all.page(params[:page]).per(FreeregOptionsConstants::FILES_PER_PAGE)
    end
    session[:current_page] = @freereg1_csv_files.current_page unless @freereg1_csv_files.nil?
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

  def relocate
   @freereg1_csv_file = Freereg1CsvFile.id(params[:id]).first
    if @freereg1_csv_file.present?
      set_controls(@freereg1_csv_file)
      session[:selectcountry] = nil
      session[:selectcounty] = nil
      @records = @freereg1_csv_file.freereg1_csv_entries.count
      max_records = 4000
      max_records = 15000 if @user.person_role == "data_manager"
      max_records = 30000 if  @user.person_role == "system_administrator"
      if @records.to_i >= max_records
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
        @countries = ['Select Country','England', 'Islands', 'Scotland', 'Wales']
        @counties = Array.new
        @placenames = Array.new
        @churches = Array.new
      end
    else
      go_back("batch",params[:id])
    end
  end


  def update_counties
    get_user_info_from_userid
    set_locations
    @freereg1_csv_file = Freereg1CsvFile.find(session[:freereg1_csv_file_id])
    @countries = [params[:country]]
    session[:selectcountry] = params[:country]
    @counties = ChapmanCode::CODES[params[:country]].keys.insert(0, "Select County")
    @placenames = Array.new
    @churches = Array.new
    display_info
  end

  def change_userid
    @freereg1_csv_file = Freereg1CsvFile.id(params[:id]).first
    if @freereg1_csv_file.present?
      set_controls(@freereg1_csv_file)
      set_locations
      @records = @freereg1_csv_file.freereg1_csv_entries.count
      userids = UseridDetail.all.order_by(userid_lower_case: 1)
      @userids = Array.new
      userids.each do |userid|
        @userids << userid.userid
      end
    else
      go_back("batch",params[:id])
    end
  end

  def update_places
    get_user_info_from_userid
    set_locations
    @freereg1_csv_file = Freereg1CsvFile.find(session[:freereg1_csv_file_id])
    @countries = [session[:selectcountry]]
    if session[:selectcounty].nil?
      #means we are a DM selecting the county
      session[:selectcounty] = ChapmanCode::CODES[session[:selectcountry]][params[:county]]
      places = Place.chapman_code(session[:selectcounty]).approved.not_disabled.all.order_by(place_name: 1)
    else
      #we are a CC
      places = Place.chapman_code(session[:selectcounty]).approved.not_disabled.all.order_by(place_name: 1)
    end
    @counties = Array.new
    @counties << session[:selectcounty]
    @placenames = places.map{|a| [a.place_name, a.id]}.insert(0, "Select Place")
    @churches = []
    display_info
  end

  def update_churches
    get_user_info_from_userid
    set_locations
    @freereg1_csv_file = Freereg1CsvFile.find(session[:freereg1_csv_file_id])
    @countries = [session[:selectcountry]]
    @counties = [session[:selectcounty]]
    place = Place.find(params[:place])
    @placenames = Array.new
    @placenames  << place.place_name
    @churches = place.churches.map{|a| [a.church_name, a.id]}.insert(0, "Select Church")
    display_info
  end

  def update_registers
    get_user_info_from_userid
    set_locations
    @freereg1_csv_file = Freereg1CsvFile.find(session[:freereg1_csv_file_id])
    @countries = [session[:selectcountry]]
    @counties = [session[:selectcounty]]
    church = Church.find(params[:church])
    place = church.place
    @placenames = Array.new
    @placenames  << place.place_name
    @churches = Array.new
    @churches << church.church_name
    display_info
  end

  def edit
    #edit the headers for a batch
    @freereg1_csv_file = Freereg1CsvFile.id(params[:id]).first
    if @freereg1_csv_file.present?
      set_controls(@freereg1_csv_file)
      unless session[:error_line].nil?
        #we are dealing with the edit of errors
        @error_message = Array.new
        @content = Array.new
        session[:error_id] = Array.new
        #this need clean up
        @n = 0
        @freereg1_csv_file.batch_errors.where(:freereg1_csv_file_id => params[:id], :error_type => 'Header_Error' ).all.each do |error|
          @error_message[@n] = error.error_message
          @content[@n] = error.data_line
          session[:error_id][@n] = error
          @n = @n + 1
          session[:header_errors] = @n
        end
      end
      #we are correcting the header
      #session role is used to control return navigation options
      @role = session[:role]
      get_places_for_menu_selection
    else
      go_back("batch",params[:id])
    end
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
          success = @freereg1_csv_file.move_file_between_userids(params[:freereg1_csv_file][:userid])
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
          @freereg1_csv_file.update_attributes(params[:freereg1_csv_file])
          @freereg1_csv_file.update_attributes(:modification_date => Time.now.strftime("%d %b %Y"))
          if @freereg1_csv_file.errors.any?  then
            flash[:notice] = 'The update of the batch was unsuccessful'
            render :action => 'edit'
            return
          end
          unless session[:error_line].nil?
            #lets remove the header errors
            @freereg1_csv_file.error =  @freereg1_csv_file.error - session[:header_errors]
            session[:error_id].each do |id|
              @freereg1_csv_file.batch_errors.delete( id)
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
          @freereg1_csv_file
          errors =  Freereg1CsvFile.update_location(@freereg1_csv_file,params[:freereg1_csv_file],session[:my_own])
          if errors[0]
            flash[:notice] = errors[1]
            redirect_to :action => "relocate"
            return
          else
            flash[:notice] = 'The relocation of the batch was successful'
          end
      end
      redirect_to :action => 'show'
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
    redirect_to freereg1_csv_files_path
  end

  def display_my_own_files
    get_user_info_from_userid
    @who =  @first_name
    @sorted_by = 'Alphabetical by file name'
    session[:sort] = "file_name ASC"
    session[:sorted_by] = @sorted_by
    redirect_to freereg1_csv_files_path
  end

  def display_my_error_files
    get_user_info_from_userid
    @who =  @first_name
    @sorted_by = 'Ordered by number of errors'
    session[:sorted_by] = @sorted_by
    session[:sort] = "error DESC, file_name ASC"
     redirect_to freereg1_csv_files_path
  end

  def display_my_own_files_by_descending_uploaded_date
    get_user_info_from_userid
    @who =  @first_name
    @sorted_by = 'Ordered by most recent'
    session[:sorted_by] = @sorted_by
    session[:sort] = "uploaded_date DESC"
     redirect_to freereg1_csv_files_path
  end

  def display_my_own_files_by_ascending_uploaded_date
    get_user_info_from_userid
    @who =  @first_name
    @sorted_by = 'Ordered by oldest'
    session[:sort] = "uploaded_date ASC"
    session[:sorted_by] = @sorted_by
     redirect_to freereg1_csv_files_path
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
    render :index
  end

  def create

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

  def remove
    #this just removes a batch of records
    @freereg1_csv_file = Freereg1CsvFile.id(params[:id]).first
    if @freereg1_csv_file.present?
      set_controls(@freereg1_csv_file) 
      if @freereg1_csv_file.locked_by_transcriber  ||  @freereg1_csv_file.locked_by_coordinator
        flash[:notice] = 'The removal of the batch was unsuccessful; the batch is locked'
        redirect_to :back
        return
      end
      @freereg1_csv_file.add_to_rake_delete_list
      @physical_file.update_attributes(:file_processed =>false, :file_processed_date => nil) if Freereg1CsvFile.where(:file_name => @freereg1_csv_file.file_name, :userid => @freereg1_csv_file.userid).count >= 1
      @freereg1_csv_file.save_to_attic
      @freereg1_csv_file.delete
      flash[:notice] = 'The removal of the batch entry was successful'
      if session[:my_own]
        redirect_to my_own_freereg1_csv_file_path
        return
      else
        redirect_to register_path(@return_location)
        return
      end
    else
      go_back("batch",params[:id])
    end
  end

  def destroy
    # this removes all batches and the file
     @freereg1_csv_file = Freereg1CsvFile.id(params[:id]).first
     if @freereg1_csv_file.present?
      set_controls(@freereg1_csv_file) 
      if @freereg1_csv_file.locked_by_transcriber ||  @freereg1_csv_file.locked_by_coordinator
        flash[:notice] = 'The deletion of the batch was unsuccessful; the batch is locked'
        redirect_to :back
        return
      end
      #save a copy to attic and delete all batches
      @physical_file.file_delete
      @physical_file.delete
      session[:type] = "edit"
      flash[:notice] = 'The deletion of the batches was successful'
      if session[:my_own]
        redirect_to my_own_freereg1_csv_file_path
        return
      else
        redirect_to register_path(@return_location)
        return
      end
    else
       go_back("batch",params[:id])
    end
  end

  def set_controls(file)
    display_info
    get_user_info_from_userid
    @physical_file = PhysicalFile.userid(file.userid).file_name(file.file_name).first
    @role = session[:role]
    @freereg1_csv_file_name = file.file_name
    session[:freereg1_csv_file_id] =  file._id
    @return_location  = file.register.id
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

  def display_info
    @freereg1_csv_file_id =   @freereg1_csv_file._id
    @freereg1_csv_file_name = @freereg1_csv_file.file_name
    @register = @freereg1_csv_file.register
    if @register.blank?
      go_back("register",@freereg1_csv_file)
    end
    @file_owner = @freereg1_csv_file.userid
    @register_name = RegisterType.display_name(@register.register_type)
    @church = @register.church
    if @church.blank?
      go_back("church",@register)
    end
    @church_name = @church.church_name
    @place = @church.place
    if @place.blank?
      go_back("place", @church)
    end
    @county =  @place.county
    @place_name = @place.place_name
  end

  def set_locations
    @update_counties_location = 'location.href= "/freereg1_csv_files/update_counties?country=" + this.value'
    @update_places_location = 'location.href= "/freereg1_csv_files/update_places?county=" + this.value'
    @update_churches_location = 'location.href= "/freereg1_csv_files/update_churches?place=" + this.value'
    @update_registers_location = 'location.href= "/freereg1_csv_files/update_registers?church=" + this.value'
  end

  def download
   @freereg1_csv_file = Freereg1CsvFile.id(params[:id]).first
    if  @freereg1_csv_file.present?
      ok_to_proceed = @freereg1_csv_file.check_file
      if !ok_to_proceed[0] 
        flash[:notice] =  "There is a problem with the file you are attempting to download; #{ok_to_proceed[1]}. Contact a system administrator if you are concerned."
        redirect_to freereg1_csv_files_path
        return
      else
        @freereg1_csv_file.backup_file
        my_file =  File.join(Rails.application.config.datafiles, @freereg1_csv_file.userid,@freereg1_csv_file.file_name)   
        if File.file?(my_file)
          @freereg1_csv_file.update_attributes(:digest => Digest::MD5.file(my_file).hexdigest)
          @freereg1_csv_file.force_unlock
          send_file( my_file, :filename => @freereg1_csv_file.file_name,:x_sendfile=>true )    
          flash[:notice] =  "The file has been downloaded to your computer"
        end
      end      
    else
       flash[:notice] =  "The file has you are attempting to download does not exist"
       redirect_to freereg1_csv_files_path
       return
    end  
  end

end
