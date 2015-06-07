class Freereg1CsvFilesController < ApplicationController

  def index
    #the common listing entry by syndicatep
    @register = session[:register_id]
    get_user_info_from_userid
    @county =  session[:county]
    @role = session[:role]
    @sorted_by = session[:sorted_by]
    case 
    when session[:my_own]
       @freereg1_csv_files = Freereg1CsvFile.userid(session[:userid]).order_by(session[:sort]).page(params[:page])
    when session[:role] == 'syndicate_coordinator' || session[:role] == 'system_administrator'
        @freereg1_csv_files = Freereg1CsvFile.syndicate(session[:syndicate]).order_by(session[:sort]).page(params[:page])
    when session[:role] == 'county_coordinator' || session[:role] == 'data_manager'
      @freereg1_csv_files = Freereg1CsvFile.county(session[:chapman_code]).order_by(session[:sort]).page(params[:page]) 
    end
  end
    
  def show
    #show an individual batch
    get_user_info_from_userid
    load(params[:id])
    #TODO check on need for these
    @county =  session[:county]
    set_controls
    display_info
    @role = session[:role]
    
  end

  def relocate
    load(params[:id])
    records = @freereg1_csv_file.freereg1_csv_entries.count
    time = records * Rails.application.config.sleep.to_f
    if time >= 180
      flash[:notice] = "There are too many records (#{records}) for an on_line update. Please change the file and reload."
      redirect_to :back
      return
    end
    set_controls
    display_info
    get_user_info_from_userid
    @county =  session[:county]
    @role = session[:role]
    get_places_for_menu_selection

  end

  def edit
    #edit the headers for a batch
    load(params[:id])
    set_controls
    get_user_info_from_userid
    display_info
    @county =  session[:county]
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

  end


  def update
    #update the headers
    load(params[:id])
    set_controls
    get_user_info_from_userid
    @county =  session[:county]
    @role = session[:role]
   if params[:commit] == 'Submit' 
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
    end
    session[:type] = "edit"
    flash[:notice] = 'The update of the batch was successful'
    @current_page = session[:page]
    session[:page] = session[:initial_page]
    redirect_to :action => 'show'
   end
   if params[:commit] == 'Relocate'
     @freereg1_csv_file =  Freereg1CsvFile.update_location(@freereg1_csv_file,params[:freereg1_csv_file])
     flash[:notice] = 'The relocation of the batch was successful'
     redirect_to :action => 'show'
   end 
  end
  def my_own
    session[:sorted_by] = nil
    session[:sort] = nil
    get_user_info_from_userid
    session[:my_own] = true
    @freereg1_csv_file = Freereg1CsvFile.new
    @who =  @first_name
    if session[:userid].nil?
      redirect_to '/', notice: "You are not authorised to use these facilities"
      return
    end
    @options= UseridRole::FILE_MANAGEMENT_OPTIONS
  end

  def display_my_own_files
    get_user_info_from_userid
    @who = @user.userid
    @sorted_by = '(Sorted alphabetically by file name)'
    session[:sort] = "file_name ASC"
    session[:sorted_by] = @sorted_by
    @freereg1_csv_files = Freereg1CsvFile.userid(@user.userid).order_by("file_name ASC").page(params[:page])
    render :index
  end
  def display_my_error_files
    get_user_info_from_userid
    @who = @user.userid
    @sorted_by = '(Sorted by number of errors)'
     session[:sorted_by] = @sorted_by
    session[:sort] = "error DESC, file_name ASC"
    @freereg1_csv_files = Freereg1CsvFile.userid(@user.userid).order_by("error DESC, file_name ASC").page(params[:page])
    render :index
  end
  def display_my_own_files_by_descending_uploaded_date
    get_user_info_from_userid
    @who = @user.userid
    @sorted_by = '(Sorted by descending date of uploading)'
    session[:sorted_by] = @sorted_by
    session[:sort] = "uploaded_date DESC"
    @freereg1_csv_files = Freereg1CsvFile.userid(@user.userid).order_by("uploaded_date DESC").page(params[:page])
    render :index
  end
  def display_my_own_files_by_ascending_uploaded_date
    get_user_info_from_userid
    @who = @user.userid
    @sorted_by = '(Sorted by ascending date of uploading)'
    session[:sort] = "uploaded_date ASC"
     session[:sorted_by] = @sorted_by
    @freereg1_csv_files = Freereg1CsvFile.userid(@user.userid).order_by("uploaded_date ASC").page(params[:page])
    render :index
  end
  def display_my_own_files_by_selection
    get_user_info_from_userid
    @who = @user.userid
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

  def error
    #display the errors in a batch
    load(params[:id])
    display_info
    set_controls
    get_user_info_from_userid
    @county =  session[:county]
    @role = session[:role]
    get_errors_for_error_display
  end

  def by_userid
    #entry by userid
    session[:page] = request.original_url
    session[:my_own] = false
    get_user_info_from_userid
    @county =  session[:county]
    @role = session[:role]
    user = UseridDetail.find(params[:id])
    @who = user.userid
    @role = session[:role]
    @freereg1_csv_files = Freereg1CsvFile.userid(user.userid).order_by("file_name ASC", "userid_lower_case ASC").page(params[:page])  unless user.nil?
    render :index
  end

  def create

  end

  def lock
    #lock/unlock a file
    load(params[:id])
    set_controls
    get_user_info_from_userid
    @county =  session[:county]
    @role = session[:role]
    @freereg1_csv_file.lock(session[:my_own])
    flash[:notice] = 'The update of the batch was successful'
    #determine how to return
    redirect_to :back
  end
  def remove
    load(params[:id])
    return_location  = @freereg1_csv_file.register
    @freereg1_csv_file.delete
    flash[:notice] = 'The removal of the batch entry was successful'
    redirect_to register_path(return_location)
  end

  def destroy
    load(params[:id])
    set_controls
    get_user_info_from_userid
    @county =  session[:county]
    return_location  = @freereg1_csv_file.register
    @role = session[:role]
    if @freereg1_csv_file.locked_by_transcriber == 'true' ||  @freereg1_csv_file.locked_by_coordinator == 'true'
      flash[:notice] = 'The deletion of the batch was unsuccessful; the batch is locked'
      redirect_to :back
      return
    end
    #there can actually be multiple files that are split into seperate counties/places/churches
    Freereg1CsvFile.where(:userid => @freereg1_csv_file.userid, :file_name => @freereg1_csv_file.file_name).all.each do |file|
      file.destroy
    end
    session[:type] = "edit"
    flash[:notice] = 'The deletion of the batch was successful'
    redirect_to register_path(return_location)

  end

  def load(file_id)
    @freereg1_csv_file = Freereg1CsvFile.find(file_id)
  end

  def display_info
    
    @freereg1_csv_file_id =   @freereg1_csv_file._id
    @freereg1_csv_file_name =  @freereg1_csv_file.file_name
    @register = @freereg1_csv_file.register
    #@register_name = @register.register_name
    #@register_name = @register.alternate_register_name if @register_name.nil?
    @register_name = RegisterType.display_name(@register.register_type)
    @church = session[:church_id]
    @church_name = session[:church_name]
    @place = session[:place_id]
    @county =  session[:county]
    @place_name = session[:place_name]
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
  end


  def set_controls
    @freereg1_csv_file_name = @freereg1_csv_file.file_name
    session[:freereg1_csv_file_id] =  @freereg1_csv_file._id
    session[:freereg1_csv_file_name] = @freereg1_csv_file_name
    session[:county] = ChapmanCode.has_key(@freereg1_csv_file.county)
    session[:place_name] = @freereg1_csv_file.place
    session[:church_name] = @freereg1_csv_file.church_name
    session[:chapman_code] = @freereg1_csv_file.county
  end

  def get_places_for_menu_selection
    placenames =  Place.where(:chapman_code => session[:chapman_code],:disabled => 'false',:error_flag.ne => "Place name is not approved").all.order_by(place_name: 1)
    @placenames = Array.new
    placenames.each do |placename|
      @placenames << placename.place_name
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
end
