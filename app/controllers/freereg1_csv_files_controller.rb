class Freereg1CsvFilesController < InheritedResources::Base
 require 'chapman_code'
  def index

    @register = session[:register_id]
    @user = session[:user]
    @first_name = session[:first_name]
    @register = session[:register_id]
    @user = session[:user]
    @first_name = session[:first_name]
       
    userids = Array.new
    @freereg1_csv_files = Array.new
     case 
       when @user.person_role == "system_administrator" || @user.person_role == "volunteer_coordinator"
         @freereg1_csv_files = Freereg1CsvFile.all.order_by(file_name: 1) 
         
       when @user.person_role == "country_coordinator" 
          countries = Syndicate.where(:country_coordinator => @user.userid).all
          countries.each do |country|
          freereg1_csv_files = Freereg1CsvFile.where(:county => county).all.order_by(file_name: 1) 
            @freereg1_csv_files << freereg1_csv_files
          end

       when @user.person_role == "county_coordinator" 
          county = Syndicate.where(:county_coordinator => @user.userid)
          @freereg1_csv_files = Freereg1CsvFile.where(:chapman_code => county).all.order_by(file_name: 1) 
    
       when @user.person_role == "syndicate_coordinator"

         syndicates = Syndicate.where(:syndicate_coordinator => @user.userid)
         syndicates.each do |synd|
           user = UseridDetail.where(:syndicate => synd.syndicate_code)
           userids << user
         end
           userids.each do |userid|
           freereg1_csv_files = Freereg1CsvFile.where(:userid => userid.userid ).all
           @freereg1_csv_files << freereg1_csv_files
         end

       else
        
      end
    
  end

  def show
    load(params[:id])
     @first_name = session[:first_name]
  end

  def edit
    load(params[:id])
     @first_name = session[:first_name]
    @freereg1_csv_file_name = session[:freereg1_csv_file_name] 
  end

  def update
   
    load(params[:id])
     @first_name = session[:first_name]
   
    @freereg1_csv_file.update_attributes(params[:freereg1_csv_file])
    
p "updated"
    flash[:notice] = 'The change in file contents was succsessful' 
     if  @freereg1_csv_file.errors.any?
      session[:form] =   @freereg1_csv_file
      session[:errors] =  @freereg1_csv_file.errors.messages
      flash[:notice] = 'The update of the file was unsuccsessful'
      redirect_to :action => 'edit'
     
    else
      session[:type] = "edit"
      flash[:notice] = 'The update of the file was succsessful'
      redirect_to  freereg1_csv_files_path(:anchor => "#{ @freereg1_csv_file.id}")
     end
   
  end

  def error
    load(params[:id])
    @first_name = session[:first_name]
  
    my_file =  Rails.application.config.datafiles + @freereg1_csv_file.userid + '/' + session[:freereg1_csv_file_name] + '.log' #Needs generalization
    @lines = Array.new
    File.open(my_file, 'r') do |f1|  
      while line = f1.gets
        @lines << line
      end
    end
   
  end
  def my_own
    @user = session[:user]
    @first_name = session[:first_name]
    @freereg1_csv_files = Freereg1CsvFile.where(:userid => @user.userid ).all.order_by(file_name: 1) 
    render "index"

  end

  def lock
    load(params[:id])
    @first_name = session[:first_name]
    @freereg1_csv_file.update_attributes(:locked => true)
    flash[:notice] = 'The update of the file was succsessful'
    redirect_to  freereg1_csv_files_path(:anchor => "#{ @freereg1_csv_file.id}")
    
  end

  def destroy
    load(params[:id])
     @first_name = session[:first_name]
     session[:freereg1_csv_file_id] = params[:id]
     #call to delete file also deleted any entries and search records
     @freereg1_csv_file = Freereg1CsvFile.delete_file(@freereg1_csv_file)
      session[:type] = "edit"
      flash[:notice] = 'The deletion of the file was succsessful'
      redirect_to  freereg1_csv_files_path(:anchor => "#{params[:id]}")
     
  end

  def load(file_id)
   
    @freereg1_csv_file = Freereg1CsvFile.find(file_id)
    @freereg1_csv_file_name = @freereg1_csv_file.file_name
    session[:freereg1_csv_file_id] = file_id
    session[:freereg1_csv_file_name] =@freereg1_csv_file_name
      
  end


end
