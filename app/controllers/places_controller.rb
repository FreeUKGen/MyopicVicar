class PlacesController < InheritedResources::Base


def index
    @places = Place.exists(place_name: true).order_by(chapman_code: 1, place_name: 1)
  end

def show
    load(params[:id])

  end

def update
    
    load(params[:id])
    place = params[:place][:place_name]
    county = params[:place][:chapman_code]
    genuki = params[:place][:genuki_url]
    
  # save place name change in Place
    old_place = @place.place_name
    old_county = @place.chapman_code
    @place.place_name = place
    @place.genuki_url = genuki
    @place.save!

  # save place name change in register
    @place.churches.each do  |church|  
      church.registers.each do |register| 
        register.place_name = place
        register.save!
      end
    end 
   
 # save place name change in Freereg_csv_file
    county = old_county if county.nil?
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

  
  def load(place_id)
   
  	@place = Place.find(place_id)
    
  end


end
