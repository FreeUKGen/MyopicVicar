class Freereg1CsvEntriesController < InheritedResources::Base
   layout "places"
   require 'chapman_code'

  def index
    @register = session[:register_id] 
    @register_name = session[:register_name] 
    @church = session[:church_id]
    @church_name = session[:church_name]
    @place = session[:place_id]
    @county =  session[:county]
    @place_name = session[:place_name] 
    @freereg1_csv_file_name =  session[:freereg1_csv_file_name]
    @freereg1_csv_file_id = session[:freereg1_csv_file_id]
    @freereg1_csv_file = Freereg1CsvFile.find(@freereg1_csv_file_id)
    @freereg1_csv_entries = Freereg1CsvEntry.where(:freereg1_csv_file_id => @freereg1_csv_file_id ).order_by(file_line_number: 1)
  end
  def show
    load(params[:id])
  end
  def edit
    load(params[:id])
    
  end
  def update
   
    load(params[:id])
    @freereg1_csv_entry.update_attributes(params[:freereg1_csv_entry])
    @freereg1_csv_entry.save!    
    flash[:notice] = 'The change in entry contents was succsessful' 
    redirect_to :action => 'show'
  end

  def load(file_id)
    puts params.inspect   
    @freereg1_csv_entry = Freereg1CsvEntry.find(file_id)
    session[:freereg1_csv_entry_id] = @freereg1_csv_entry._id
   
    @freereg1_csv_file_id =  session[:freereg1_csv_file_id]
    @freereg1_csv_file_name =  session[:freereg1_csv_file_name]
    @freereg1_csv_file = Freereg1CsvFile.find(@freereg1_csv_file_id)
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
