class Freereg1CsvFilesController < InheritedResources::Base
layout "places"
 require 'chapman_code'
  def index
    @register = session[:register_id]
    @freereg1_csv_files = Freereg1CsvFile.where(:register_id => @register ).order_by(file_name: 1)
  end
  def show
    load(params[:id])
  end

  def edit
    load(params[:id])
    @freereg1_csv_file_name = session[:freereg1_csv_file_name] 
    puts  session[:freereg1_csv_file_id].inspect 
    puts  @freereg1_csv_file.inspect 
  end

  def update
   
    load(params[:id])
     puts params.inspect 
    @freereg1_csv_file.update_attributes(params[:freereg1_csv_file])
    @freereg1_csv_file.save!    
    flash[:notice] = 'The change in file contents was succsessful' 
    redirect_to :action => 'show'
  end

  def load(file_id)
     puts params.inspect  
    @freereg1_csv_file = Freereg1CsvFile.find(file_id)
    puts "files controller"
     @freereg1_csv_file_name = @freereg1_csv_file.file_name
    session[:freereg1_csv_file_id] = file_id

    session[:freereg1_csv_file_name] =@freereg1_csv_file_name
    puts  session[:freereg1_csv_file_name].inspect 
    puts  session[:freereg1_csv_file_id].inspect 
    puts  @freereg1_csv_file.inspect 
    @register = session[:register_id]
    @register_name = session[:register_name]
    @church = session[:church_id]
    @church_name = session[:church_name]
    @place = session[:place_id]
    @county =  session[:county]
    @place_name = session[:place_name] 
    puts session.inspect
  end


end
