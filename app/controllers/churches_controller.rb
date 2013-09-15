class ChurchesController < InheritedResources::Base
 layout "places"
 require 'chapman_code'
  def show
    load(params[:id])

  end
  
  def edit
    load(params[:id])
  end

  def update
    load(params[:id])
    old_church_name = @church.church_name
    puts params[:church].inspect
    @church.update_attributes(params[:church])
    @church.save!
    
    my_files = Freereg1CsvFile.where(:county => @county, :place => @place_name, :church_name =>  old_church_name).to_a
    if my_files
      my_files.each do |myfile|
        myfile.church_name = params[:church_name]
        myfile.save!

# save place name change in Freereg_csv_entry
        myfile_id = myfile._id
       
        my_entries = Freereg1CsvEntry.where(:freereg1_csv_file_id => myfile_id).to_a
        my_entries.each do |myentries|
            myentries.church_name =params[:church_name]
            myentries.save!
        end
      end
    else
    end

    flash[:notice] = 'The change in Church Name was succsessful'    
    redirect_to :action => 'show'
  end
  
  def load(church_id)
        
    @church = Church.find(church_id)
    session[:church_id] = @church._id
    @church_name = @church.church_name
    session[:church_name] = @church_name
    @place_id = @church.place
    session[:place_id] = @place_id._id
    @place = Place.find(@place_id)
    @place_name = @place.place_name
    session[:place_name] =  @place_name
   
    @county = ChapmanCode.has_key(@place.chapman_code)
    session[:county] = @county
   
    
    
   

  end
  def destroy
   puts "destroy"
    puts params.inspect
    load(params[:id])
    @church.destroy
    redirect_to church_path
 end

end
