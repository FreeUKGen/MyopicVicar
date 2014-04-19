class Freereg1CsvFilesController < InheritedResources::Base
 require 'chapman_code'

  def index
   #the common listing entry by syndicate
    @register = session[:register_id]
    @user = UseridDetail.where(:userid => session[:userid]).first
    @first_name = session[:first_name]
    @role = session[:role]
    session[:my_own] = 'no'
    @freereg1_csv_files = Freereg1CsvFile.syndicate(session[:syndicate]).order_by(session[:sort]).page(params[:page])
 
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
    if @freereg1_csv_file.errors.any?
    
      flash[:notice] = 'The update of the file was unsuccsessful'
      render :action => 'edit'
     else
      session[:type] = "edit"
      flash[:notice] = 'The update of the file was successful'
      redirect_to :back
     end
  end

  def error
    #display the nerrors in a batch
    load(params[:id])
    lines = @freereg1_csv_file.batch_errors.all
    @role = session[:role]
    @no_errors = 'no' if lines.nil?
    @lines = Array.new
    @system = Array.new
    @header = Array.new
    @owner = @freereg1_csv_file.userid
    lines.each do |line|
      p line
         entry = Freereg1CsvEntry.where(freereg1_csv_file_id:  session[:freereg1_csv_file_id]).first
         @lines << line if line.error_type == 'Data_Error' 
         @system << line if line.error_type == 'System_Error' 
         @header << line if line.error_type == 'Header_Error'
    end
  end

  def by_userid
    #entry by userid
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
      session[:my_own] = 'no'
   @first_name = session[:first_name]
   @user = UseridDetail.where(:userid => session[:userid]).first
   session[:sort] =  "file_name ASC"
   @freereg1_csv_files = Freereg1CsvFile.all.order_by(session[:sort]).page(params[:page])  
   render :index
end
  
def my_own
    #entry for an individual
   unless  session[:my_own].nil?
    #when we know you we are then get the files
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
    @who = @user.userid 
    @role = session[:role]
    @freereg1_csv_files = Freereg1CsvFile.userid(@user.userid).order_by(session[:sort]).page(params[:page])  unless @user.nil?
    render :index
    return
  else
    #on an initial entry we need to find out what to do
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
    @freereg1_csv_file = Freereg1CsvFile.new
    @role = session[:role]
    @who =  @first_name
    session[:my_own] = 'my_own'
  end
end

def create
  #creation of the options for the individual entry
  if session[:my_own] == 'my_own'
    case 
     when params[:freereg1_csv_file][:action] == 'By filename'
      session[:sort] =  "file_name ASC"
     when params[:freereg1_csv_file][:action] == 'By number of errors then filename'
      session[:sort] =   "error DESC, file_name ASC"
     when params[:freereg1_csv_file][:action] == 'By uploaded date (descending)'
      session[:sort] =  "uploaded_date DESC, userid ASC"
     when params[:freereg1_csv_file][:action] == 'By uploaded date (ascending)'
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
    if  @freereg1_csv_file.locked == 'false'
     @freereg1_csv_file.locked = 'true'
     @freereg1_csv_file.save
   else
     @freereg1_csv_file.locked = 'false'
     @freereg1_csv_file.save
    end
    flash[:notice] = 'The update of the file was succsessful'
   #determine how to return
    if session[:my_own] == 'my_own'
       @freereg1_csv_files = Freereg1CsvFile.userid(session[:userid]).order_by(file_name: 1).page(params[:page])
       render 'index'
     else 
      redirect_to  freereg1_csv_files_path(:anchor => "#{params[:id]}")
     end
  end

  def destroy
    load(params[:id])
    @csvfile = Csvfile.new
    @csvfile.file_name = @freereg1_csv_file_name
     @csvfile.userid = @freereg1_csv_file.userid
     #places a copy of the file in the attic before deleting
     @csvfile.save_to_attic
     #call to delete file also deleted any entries and search records
     @freereg1_csv_file = Freereg1CsvFile.delete_file(@freereg1_csv_file)
      session[:type] = "edit"
      flash[:notice] = 'The deletion of the file was succsessful'
       if session[:my_own] == 'my_own'
         @freereg1_csv_files = Freereg1CsvFile.userid(session[:userid] ).order_by(file_name: 1).page(params[:page])
       render 'index'
       else 
        redirect_to  freereg1_csv_files_path(:anchor => "#{params[:id]}")
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
