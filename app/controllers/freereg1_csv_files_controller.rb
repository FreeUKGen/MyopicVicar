class Freereg1CsvFilesController < ApplicationController
 
  def index
     #the common listing entry by syndicate
    @register = session[:register_id]
    display_info
    @role = session[:role]
    session[:my_own] = 'no'
    @freereg1_csv_files = Freereg1CsvFile.syndicate(session[:syndicate]).order_by(session[:sort]).page(params[:page]) if session[:role] == 'syndicate'
    @freereg1_csv_files = Freereg1CsvFile.county(session[:chapman_code]).order_by(session[:sort]).page(params[:page]) if session[:role] == 'counties'
    session[:page] = request.original_url
   end

  def show
    #show an individual batch
    load(params[:id])
    display_info
    set_controls
    @role = session[:role]
  end

  def edit
    #edit the headers for a batch
    load(params[:id])
    set_controls
    display_info
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
    display_info
    #lets see if we are moving the file
    @freereg1_csv_file.date_change(params[:freereg1_csv_file][:transcription_date],params[:freereg1_csv_file][:modification_date])
    if @freereg1_csv_file.are_we_changing_location?(params[:freereg1_csv_file])
     #update the file attributes
         @freereg1_csv_file =  Freereg1CsvFile.update_location(@freereg1_csv_file,params[:freereg1_csv_file])
    end
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
      redirect_to @current_page
  end

  def error
    #display the errors in a batch
    load(params[:id])
    set_controls
    display_info
    session[:role] = 'errors'
    get_errors_for_error_display
  end

  def by_userid
    #entry by userid
    session[:page] = request.original_url
    session[:my_own] = 'no'
    display_info
    user = UseridDetail.find(params[:id])
    @who = user.userid 
    @role = session[:role]
    @freereg1_csv_files = Freereg1CsvFile.userid(user.userid).order_by("file_name ASC", "userid_lower_case ASC").page(params[:page])  unless user.nil?
    render :index
  end


  def my_own
    #entry for an individual
    session[:page] = request.original_url
    display_info
    @role = session[:role]
   unless  session[:my_own].nil?
    #when we know you we are then get the files
    @who = @user.userid 
    @freereg1_csv_files = Freereg1CsvFile.userid(@user.userid).order_by(session[:sort]).page(params[:page])  unless @user.nil?
    render :my_own_index
    return
   else
    #on an initial entry we need to find out what to do
    @freereg1_csv_file = Freereg1CsvFile.new
    @who =  @first_name
    session[:my_own] = 'my_own'
   end
  end

 def create
  #creation of the options for the individual entry
  if session[:my_own] == 'my_own'
    display_info
    my_own_options
    @freereg1_csv_files = Freereg1CsvFile.userid(session[:userid]).order_by(session[:sort] ).page(params[:page])
    render "index"
    return
  end #end if
 end

  def lock
    #lock/unlock a file
    load(params[:id])
    set_controls
    display_info
    @freereg1_csv_file.lock(session[:my_own])
    flash[:notice] = 'The update of the file was successful'
   #determine how to return
    return_decision
  end

  def destroy
    load(params[:id])
    set_controls
    display_info
    if @freereg1_csv_file.locked_by_transcriber == 'true' ||  @freereg1_csv_file.locked_by_coordinator == 'true'
        flash[:notice] = 'The deletion of the file was unsuccessful; the file is locked' 
        @current_page = session[:page]
        session[:page] = session[:initial_page]    
        redirect_to @current_page 
        return
    end
     #there can actually be multiple files that are split into seperate counties/places/churches
     Freereg1CsvFile.where(:userid => @freereg1_csv_file.userid, :file_name => @freereg1_csv_file.file_name).all.each do |file|
      file.destroy
     end
      session[:type] = "edit"
      flash[:notice] = 'The deletion of the file was successful'
      return_decision
     
  end

  def load(file_id)
    @freereg1_csv_file = Freereg1CsvFile.find(file_id)
 end

  def display_info
    @county =  session[:county]   
    @user = UseridDetail.where(:userid => session[:userid]).first
    @first_name = session[:first_name] 
  end

def set_controls
    @freereg1_csv_file_name = @freereg1_csv_file.file_name
    session[:freereg1_csv_file_id] =  @freereg1_csv_file._id
    session[:freereg1_csv_file_name] = @freereg1_csv_file_name
    session[:county] = @freereg1_csv_file.county
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
         entry = Freereg1CsvEntry.where(freereg1_csv_file_id:  @freereg1_csv_file._id).first
         @lines << line if line.error_type == 'Data_Error' 
         @system << line if line.error_type == 'System_Error' 
         @header << line if line.error_type == 'Header_Error'
    end
  end
end

def my_own_options
  case 
     when params[:freereg1_csv_file][:action] == 'Upload New Batch'
      redirect_to new_csvfile_path
      return
     when params[:freereg1_csv_file][:action] == 'List by name'
      session[:sort] =  "file_name ASC"
     when params[:freereg1_csv_file][:action] == 'List by number of errors then name'
      session[:sort] =   "error DESC, file_name ASC"
     when params[:freereg1_csv_file][:action] == 'List by uploaded date (descending)'
      session[:sort] =  "uploaded_date DESC, userid ASC"
     when params[:freereg1_csv_file][:action] == 'List by uploaded date (ascending)'
      session[:sort] =  "uploaded_date ASC, userid ASC"
  end #end case
end

def return_decision
   if session[:my_own] == 'my_own'
       @freereg1_csv_files = Freereg1CsvFile.userid(session[:userid]).order_by(file_name: 1).page(params[:page])
       render 'index'
    else 
        @current_page = session[:page]
        session[:page] = session[:initial_page]    
        redirect_to @current_page
    end
end

end
