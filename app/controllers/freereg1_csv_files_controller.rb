class Freereg1CsvFilesController < InheritedResources::Base
 require 'chapman_code'
  def index
 
    @register = session[:register_id]
     @user = UseridDetail.where(:userid => session[:userid]).first
    @first_name = session[:first_name]
    session[:my_own] = 'no'
    userids = Array.new
    @freereg1_csv_files = Array.new
     case 
       when @user.person_role == "system_administrator" || @user.person_role == "volunteer_coordinator"
         @freereg1_csv_files = Freereg1CsvFile.all.order_by(file_name: 1) 
         
       when @user.person_role == "country_coordinator" 
          countries = Syndicate.where(:country_coordinator => @user.userid).all
          countries.each do |country|
          freereg1_csv_files = Freereg1CsvFile.where(:county => country.chapman_code).all.order_by(file_name: 1) 
          freereg1_csv_files.each do |freereg1_csv_file|
          @freereg1_csv_files << freereg1_csv_file
         end
         end

       when @user.person_role == "county_coordinator" 
          counties = County.where(:county_coordinator => @user.userid)
          counties.each do |county|
          freereg1_csv_files = Freereg1CsvFile.where(:county => county.chapman_code).all.order_by(file_name: 1) 
          freereg1_csv_files.each do |freereg1_csv_file|
          @freereg1_csv_files << freereg1_csv_file
         end
         end
          
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
    
    flash[:notice] = 'The change in file contents was succsessful'
     if @freereg1_csv_file.errors.any?
      session[:form] = @freereg1_csv_file
      session[:errors] = @freereg1_csv_file.errors.messages
      flash[:notice] = 'The update of the file was unsuccsessful'
      redirect_to :action => 'edit'
     
    else
      session[:type] = "edit"
      flash[:notice] = 'The update of the file was succsessful'
      if session[:my_own] == 'my_own'
      redirect_to my_own_freereg1_csv_file_path(:anchor => "#{ @freereg1_csv_file.id}")
      else
       redirect_to freereg1_csv_files_path(:anchor => "#{ @freereg1_csv_file.id}")
      end
     end
   
  end

  def error
    load(params[:id])
    my_file =  File.join(Rails.application.config.datafiles, @freereg1_csv_file.userid,session[:freereg1_csv_file_name]) + '.log' #Needs generalization
    
    @lines = Array.new
    File.open(my_file, 'r') do |f1|  
      while line = f1.gets
         @lines << line
      end
    end
   
  end
  
  def my_own
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
    @freereg1_csv_files = Freereg1CsvFile.where(:userid => session[:userid]).all.order_by(file_name: 1)
    session[:my_own] = 'my_own'
    render "index"
  end


  def lock
    load(params[:id])
    @freereg1_csv_file.update_attributes(:locked => true)
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
    session[:freereg1_csv_file_name] =@freereg1_csv_file_name
    @user = UseridDetail.where(:userid => session[:userid]).first
    @first_name = session[:first_name] 
     session[:county] = @freereg1_csv_file.county
     session[:place_name] = @freereg1_csv_file.place
       session[:church_name] = @freereg1_csv_file.church_name


  end
 
end
