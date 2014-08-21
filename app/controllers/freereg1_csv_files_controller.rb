class Freereg1CsvFilesController < ApplicationController
 require 'chapman_code'

  def index
    if session[:userid].nil?
      redirect_to '/', notice: "You are not authorised to use these facilities"
    end
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
    @role = session[:role]
   
    
  end

  def edit
    #edit the headers for a batch

    load(params[:id])
    unless session[:error_line].nil?
     #we are correcting the header
      @error_message = Array.new
      @content = Array.new
      session[:error_id] = Array.new
      @n = 0
      @freereg1_csv_file.batch_errors.where(:freereg1_csv_file_id => params[:id], :error_type => 'Header_Error' ).all.each do |error|
         @error_message[@n] = error.error_message
         @content[@n] = error.data_line
         session[:error_id][@n] = error
         @n = @n + 1
         session[:header_errors] = @n
      end
    end
    #session role is used to control return navigation options
    @role = session[:role]
    @freereg1_csv_file_name = session[:freereg1_csv_file_name] 
    placenames = Place.where(:chapman_code => @freereg1_csv_file.county,:disabled.ne => "true" ).all.order_by(place_name: 1)
      @placenames = Array.new
        placenames.each do |placename|
          @placenames << placename.place_name
        end
  end


  def update
    #the following variable is used in file processing
    @@result = nil
    #update the headers
    load(params[:id])
    #keep a copy
    old_freereg1_csv_file = @freereg1_csv_file.clone
    #lets see if we are moving the file
    change = nil
    change = @freereg1_csv_file.register_type unless params[:freereg1_csv_file][:register_type] == @freereg1_csv_file.register_type
    change = @freereg1_csv_file.church_name unless params[:freereg1_csv_file][:church_name] == @freereg1_csv_file.church_name
    change = @freereg1_csv_file.place unless params[:freereg1_csv_file][:place] == @freereg1_csv_file.place
    change = @freereg1_csv_file.county unless params[:freereg1_csv_file][:county] == @freereg1_csv_file.county

   Freereg1CsvFile.date_change(@freereg1_csv_file,params[:freereg1_csv_file][:transcription_date],params[:freereg1_csv_file][:transcription_date])
    # We avoid resetting the lock flags on an unlock
    unlocking = "false"
    unlocking = "true"   if ((@freereg1_csv_file.locked_by_transcriber == "true" && params[:freereg1_csv_file][:locked_by_transcriber] == "false") ||  (@freereg1_csv_file.locked_by_coordinator == "true"  &&  params[:freereg1_csv_file][:locked_by_coordinator]  == "false"))
    #update the file attributes
    @freereg1_csv_file.update_attributes(:alternate_register_name => (params[:freereg1_csv_file][:church_name].to_s + ' ' + params[:freereg1_csv_file][:register_type].to_s ))
    @freereg1_csv_file.update_attributes(params[:freereg1_csv_file])
      # We avoid resetting the lock flags on an unlock
    if unlocking == "false" then
      @freereg1_csv_file.update_attributes(:locked_by_transcriber => "true") if session[:my_own] == 'my_own' 
      @freereg1_csv_file.update_attributes(:locked_by_coordinator => "true") unless session[:my_own] == 'my_own'
    end 

    @freereg1_csv_file.update_attributes(:modification_date => Time.now.strftime("%d %b %Y"))
    
    if @freereg1_csv_file.errors.any?
      flash[:notice] = 'The update of the batch was unsuccessful'
      render :action => 'edit'
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
   
      if  change.nil?
        #lets make a backup copy
        Freereg1CsvFile.backup_file(@freereg1_csv_file)
      else
        #need to change location of file
        new_freereg1_csv_file = @freereg1_csv_file.clone
        new_freereg1_csv_file.register_id = nil
        Register.update_or_create_register(new_freereg1_csv_file)
        new_freereg1_csv_file.save

       if  new_freereg1_csv_file.errors.any? || !@@result.nil?
         flash[:notice] = 'The update of the batch was unsuccessful'
         render :action => 'edit'
          return
       else
        #do final clean up
        Freereg1CsvEntry.change_file(@freereg1_csv_file._id,new_freereg1_csv_file._id)
        @freereg1_csv_file.delete
        Register.clean_empty_registers(old_freereg1_csv_file)
        Freereg1CsvFile.backup_file(new_freereg1_csv_file)
        end
      end #end type
      session[:type] = "edit"
      flash[:notice] = 'The update of the batch was successful' 
      @current_page = session[:page]
      session[:page] = session[:initial_page]    
      redirect_to @current_page
   
  end

  def error
    #display the nerrors in a batch
    load(params[:id])
    @errors = @freereg1_csv_file.batch_errors.count
    @owner = @freereg1_csv_file.userid
    unless @errors == 0
    lines = @freereg1_csv_file.batch_errors.all
    @role = session[:role]
    @lines = Array.new
    @system = Array.new
    @header = Array.new
    lines.each do |line|
    
         entry = Freereg1CsvEntry.where(freereg1_csv_file_id:  session[:freereg1_csv_file_id]).first
         @lines << line if line.error_type == 'Data_Error' 
         @system << line if line.error_type == 'System_Error' 
         @header << line if line.error_type == 'Header_Error'
    end
  end
  end

  def by_userid
    #entry by userid
     session[:page] = request.original_url
      session[:my_own] = 'no'
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
    user = UseridDetail.find(params[:id])
    @who = user.userid 
    @role = session[:role]
    @freereg1_csv_files = Freereg1CsvFile.userid(user.userid).order_by("file_name ASC", "userid_lower_case ASC").page(params[:page])  unless user.nil?
    render :index
  end


def my_own
    #entry for an individual
    session[:page] = request.original_url
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
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
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
    @freereg1_csv_files = Freereg1CsvFile.userid(session[:userid]).order_by(session[:sort] ).page(params[:page])
    render "index"
  end #end if
end

  def lock

    #lock/unlock a file
    load(params[:id])
    if  session[:my_own] == 'my_own'
    if  @freereg1_csv_file.locked_by_transcriber == 'false'
     @freereg1_csv_file.locked_by_transcriber = 'true'
     @freereg1_csv_file.save
      else
     @freereg1_csv_file.locked_by_transcriber = 'false'
     @freereg1_csv_file.save
    end
  else 
    if  @freereg1_csv_file.locked_by_coordinator == 'false'
     @freereg1_csv_file.locked_by_coordinator = 'true'
     @freereg1_csv_file.save
      else
     @freereg1_csv_file.locked_by_coordinator = 'false'
     @freereg1_csv_file.save
    end



  end
    flash[:notice] = 'The update of the file was successful'
   #determine how to return
    if session[:my_own] == 'my_own'
       @freereg1_csv_files = Freereg1CsvFile.userid(session[:userid]).order_by(file_name: 1).page(params[:page])
       render 'index'
     else 
        @current_page = session[:page]
        session[:page] = session[:initial_page]    
        redirect_to @current_page
     end
  end

  def destroy
    load(params[:id])
    if @freereg1_csv_file.locked_by_transcriber == 'true' ||  @freereg1_csv_file.locked_by_coordinator == 'true'
        flash[:notice] = 'The deletion of the file was unsuccessful; the file is locked' 
        @current_page = session[:page]
        session[:page] = session[:initial_page]    
        redirect_to @current_page 
        return
    end
    Freereg1CsvFile.where(:userid => @freereg1_csv_file.userid, :file_name => @freereg1_csv_file.file_name).all.each do |file|
     file.destroy
    end
     session[:type] = "edit"
      flash[:notice] = 'The deletion of the file was successful'
       if session[:my_own] == 'my_own'
         @freereg1_csv_files = Freereg1CsvFile.userid(session[:userid] ).order_by(file_name: 1).page(params[:page])
       render 'index'
       else 
        @current_page = session[:page]
        session[:page] = session[:initial_page] 
        redirect_to @current_page
       end
     
  end

  def load(file_id)
    @freereg1_csv_file = Freereg1CsvFile.find(file_id)
    @freereg1_csv_file_name = @freereg1_csv_file.file_name
    session[:freereg1_csv_file_id] = file_id
    session[:freereg1_csv_file_name] = @freereg1_csv_file_name
    session[:county] = @freereg1_csv_file.county
    session[:place_name] = @freereg1_csv_file.place
    session[:church_name] = @freereg1_csv_file.church_name
    display_info
  end

  def display_info
    @county =  session[:county]   
    @user = UseridDetail.where(:userid => session[:userid]).first
    @first_name = session[:first_name] 
  end

end
