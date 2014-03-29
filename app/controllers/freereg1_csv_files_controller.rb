class Freereg1CsvFilesController < InheritedResources::Base
 require 'chapman_code'
  def index
 
    @register = session[:register_id]
    @user = UseridDetail.where(:userid => session[:userid]).first
    @first_name = session[:first_name]
    @role = session[:role]
    session[:my_own] = 'no'
    
    @freereg1_csv_files = Freereg1CsvFile.where(:transcriber_syndicate => session[:syndicate] ).all.order_by(session[:sort]) 
      
   end

  def show
    load(params[:id])
   @role = session[:role]
    
  end

  def edit
    load(params[:id])
    @role = session[:role]
    
    @freereg1_csv_file_name = session[:freereg1_csv_file_name] 
  end


  def update
      load(params[:id])
     
    @freereg1_csv_file.update_attributes(params[:freereg1_csv_file])
    
    flash[:notice] = 'The change in file contents was succsessful'
     if @freereg1_csv_file.errors.any?
    session[:errors] = @freereg1_csv_file.errors.messages
      flash[:notice] = 'The update of the file was unsuccsessful'
    render :action => 'edit'
     
    else
      session[:type] = "edit"
      flash[:notice] = 'The update of the file was succsessful'

     redirect_to :back
     
    end
   
  end

  def error
    load(params[:id])
    lines = @freereg1_csv_file.batch_errors.all
     @role = session[:role]
    
    @no_errors = 'no' if lines.nil?
    @lines = Array.new
    @system = Array.new
    lines.each do |line|
   
      entry = Freereg1CsvEntry.where(freereg1_csv_file_id:  session[:freereg1_csv_file_id]).first
   
     #line.entry_id = entry._id
     @lines << line if line.error_type == 'Data_Error' 
     @system << line if line.error_type == 'System_Error' 
     @header << line if line.error_type == 'Header_Error'
    end
  end

  def by_userid
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
    user = UseridDetail.find(params[:id])
   @type = user.userid 
    @role = session[:role]
    
    @freereg1_csv_files = Freereg1CsvFile.where(:userid => user.userid ).all.order_by("file_name ASC")  unless user.nil?
    render :index
  end
  
  def my_own
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
    @freereg1_csv_file = Freereg1CsvFile.new
     @role = session[:role]
    
    @type =  @first_name
    session[:my_own] = 'my_own'
  end

def create
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
    @freereg1_csv_files = Freereg1CsvFile.where(:userid => session[:userid]).all.order_by(session[:sort]) 
    render "index"
  end #end if
end

  def lock
    load(params[:id])
 
    if  @freereg1_csv_file.locked == 'false'
     
      @freereg1_csv_file.locked = 'true'
     @freereg1_csv_file.save
   else
   
    @freereg1_csv_file.locked = 'false'
     @freereg1_csv_file.save
    end
    flash[:notice] = 'The update of the file was succsessful'
   
    if session[:my_own] == 'my_own'
       @freereg1_csv_files = Freereg1CsvFile.where(:userid => session[:userid] ).all.order_by(file_name: 1)
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
         @freereg1_csv_files = Freereg1CsvFile.where(:userid => session[:userid] ).all.order_by(file_name: 1)
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
    @user = UseridDetail.where(:userid => session[:userid]).first
    @first_name = session[:first_name] 
    session[:county] = @freereg1_csv_file.county
    session[:place_name] = @freereg1_csv_file.place
    session[:church_name] = @freereg1_csv_file.church_name


  end
 
end
