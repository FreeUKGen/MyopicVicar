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
    
  end

  def update
   
    load(params[:id])
   
    @freereg1_csv_file.update_attributes(params[:freereg1_csv_file])
    @freereg1_csv_file.save!    
    flash[:notice] = 'The change in file contents was succsessful' 
    redirect_to :action => 'show'
  end

  def load(file_id)
   
    @freereg1_csv_file = Freereg1CsvFile.find(file_id)
    @freereg1_csv_file_name = @freereg1_csv_file.file_name
    session[:freereg1_csv_file_id] = file_id
    session[:freereg1_csv_file_name] =@freereg1_csv_file_name
    @register = session[:register_id]
    @register_name = session[:register_name]
    @church = session[:church_id]
    @church_name = session[:church_name]
    @place = session[:place_id]
    @county =  session[:county]
    @place_name = session[:place_name] 
   
  end


end
