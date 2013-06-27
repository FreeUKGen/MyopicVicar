class PlacesController < InheritedResources::Base


def index
    @places = Place.where.order_by(chapman_code: 1)
  end


def update
    
    load(params[:id])
    place = params[:place][:place_name]
    county = params[:place][:chapman_code]
    
  # save place name change in Place
    old_place = @place.place_name
    @place.place_name = place
    @place.save!

  # save place name change in register
    @place.churches.each do  |church|  
      church.registers.each do |register| 
        register.place_name = place
        register.save!
      end
    end 
   
 # save place name change in Freereg_csv_file
    my_files = Freereg1CsvFile.where(:county => county, :place => old_place).to_a
    
    if my_files
      my_files.each do |myfile|
        myfile.place = place
        myfile.save!

# save place name change in Freereg_csv_entry
        myfile_id = myfile._id
       
        my_entries = Freereg1CsvEntry.where(:freereg1_csv_file_id => myfile_id).to_a
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

  
  def load(place_id_string)
  	place_id = BSON::ObjectId(place_id_string)
    @place = Place.find(place_id)
    
  end


end
