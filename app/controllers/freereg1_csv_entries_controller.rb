class Freereg1CsvEntriesController < InheritedResources::Base
   layout "places"
   require 'chapman_code'

  def index
    @freereg1_csv_file = session[:freereg1_csv_file_id]
    @freereg1_csv_entries = Freereg1CsvEntry.where(:freereg1_csv_file_id => @freereg1_csv_file ).order_by(file_line_number: 1)
  end
  def show
    load(params[:id])
  end
  def edit
    load(params[:id])
    @file = Freereg1CsvFile.find(@freereg1_csv_file_id)
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
   
    @register = session[:register_id] 
    @register_name = session[:register_name] 
    @church = session[:church_id]
    @church_name = session[:church]
    @place = session[:place_id]
    @county =  session[:county]
    @place_name = session[:place] 
    puts session.inspect
    
  end
end
