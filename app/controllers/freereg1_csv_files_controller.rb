class Freereg1CsvFilesController < InheritedResources::Base
 require 'chapman_code'

  def index
    if session[:userid].nil?
      redirect_to '/', notice: "You are not authorised to use these facilities"
    end
   #the common listing entry by syndicate
    @register = session[:register_id]
    @user = UseridDetail.where(:userid => session[:userid]).first
    @first_name = session[:first_name]
    @role = session[:role]
    session[:my_own] = 'no'
    @freereg1_csv_files = Freereg1CsvFile.syndicate(session[:syndicate]).order_by(session[:sort]).page(params[:page])
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
    #session role is used to control return navigation options
    @role = session[:role]
    @freereg1_csv_file_name = session[:freereg1_csv_file_name] 
  end


  def update
    #update the headers
    load(params[:id])
    @freereg1_csv_file.update_attributes(params[:freereg1_csv_file])
    @freereg1_csv_file.update_attributes(:locked_by_transcriber => "true") if session[:my_own] == 'my_own'
    @freereg1_csv_file.update_attributes(:locked_by_coordinator => "true") unless session[:my_own] == 'my_own'
    @freereg1_csv_file.update_attributes(:modification_date => Time.now.strftime("%d %b %Y"))
    
    if @freereg1_csv_file.errors.any?
    
      flash[:notice] = 'The update of the file was unsuccessful'
      render :action => 'edit'
     else
      session[:type] = "edit"
      flash[:notice] = 'The update of the file was successful' 
        Freereg1CsvFile.backup_file(@freereg1_csv_file)
        @current_page = session[:page]
        session[:page] = session[:initial_page]    
        redirect_to @current_page
     end
  end

  def error
    #display the nerrors in a batch
    load(params[:id])
    @errors = @freereg1_csv_file.batch_errors.count
    unless @errors == 0
    lines = @freereg1_csv_file.batch_errors.all
    @role = session[:role]
    @lines = Array.new
    @system = Array.new
    @header = Array.new
    @owner = @freereg1_csv_file.userid
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
    @freereg1_csv_files = Freereg1CsvFile.userid(user.userid).order_by("file_name ASC").page(params[:page])  unless user.nil?
    render :index
  end

 def all_files
    #entry for REGManager and DataManager
    session[:page] = request.original_url
    session[:my_own] = 'no'
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
    unless session[:role] == 'data_manager'
    #first time we select the county
      session[:role] = 'county_selection'
      @counties = Array.new
      counties = County.all.order_by(chapman_code: 1)
        counties.each do |county|
          @counties << county.chapman_code
        end
      @manage_county = ManageCounty.new
      @number_of_counties = @counties.length
      render "manage_counties/index"
    else
      #we know the county get the files
      @county = session[:county]
      who = County.where(:chapman_code => session[:chapman_code]).first
      @who = who.county_coordinator
      @email = UseridDetail.where(:userid => @who).first.email_address
      @freereg1_csv_files = Freereg1CsvFile.county(session[:chapman_code]).order_by( "error DESC, file_name ASC").page(params[:page])
    end
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
    @csvfile = Csvfile.new
    @csvfile.file_name = @freereg1_csv_file_name
     @csvfile.userid = @freereg1_csv_file.userid
     #places a copy of the file in the attic before deleting
     @csvfile.save_to_attic
     #call to delete file also deleted any entries and search records
     @freereg1_csv_file = Freereg1CsvFile.delete_file(@freereg1_csv_file)
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
    @user = UseridDetail.where(:userid => session[:userid]).first
    @first_name = session[:first_name] 

  end

end
