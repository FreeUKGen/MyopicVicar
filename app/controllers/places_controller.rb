class PlacesController < InheritedResources::Base


def index
    
    unless params[:commit] == "Search"
          reset_session
          @places = Place.new
      else       
          @places = Place.where( :chapman_code => params[:place][:chapman_code]).all.order_by( place_name: 1)
          @county = ChapmanCode.has_key(params[:place][:chapman_code]) 
          session[:county] = @county
      end

  end

def show
    load(params[:id])

  end

def edit
  
  load(params[:id])
    

end

def create
  if params[:commit] == "Search"
    redirect_to places_path(params)
  else
    redirect_to :action => :new
  end
end

def update
    load(params[:id])
    place = params[:place][:alternate_place_name]
    notes = params[:place][:notes]
    
    # save place name change in Place
     @place.alternate_place_name = @place.place_name
    old_county = @place.chapman_code
    @place.place_name = place
   
    @place.place_notes = notes
    @place.save!

  # save place name change in register
    @place.churches.each do |church|
      church.registers.each do |register|
        register.place_name = place
        register.save!
      end
    end
   
 # save place name change in Freereg_csv_file
    county = old_county if county.nil?
    my_files = Freereg1CsvFile.where(:county => county, :place => @place.alternate_place_name).all
    if my_files
      my_files.each do |myfile|
        myfile.place = place
        myfile.save!

# save place name change in Freereg_csv_entry
        myfile_id = myfile._id
       
        my_entries = Freereg1CsvEntry.where(:freereg1_csv_file_id => myfile_id).all
        my_entries.each do |myentries|
            myentries.place = place
            myentries.save!
        end
      end
    else
    end

  # Need to add failure capture code
  
   flash[:notice] = 'The change in Place Name was succsessful'
   redirect_to :action => 'show'
  end

  
  def load(place_id)
   @place = Place.find(place_id)
   session[:place_id] = place_id
   @place_name = @place.place_name
   session[:place_name] = @place_name
   @county = ChapmanCode.has_key(@place.chapman_code)
   session[:county] = @county
  end
 def destroy
   
    load(params[:id])
    @place.destroy
    redirect_to places_path
 end

end