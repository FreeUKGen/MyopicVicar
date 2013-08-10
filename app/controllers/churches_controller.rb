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
    @church.update_attributes(params[:church])
    @church.save!
    flash[:notice] = 'The change in Church Name was succsessful'    
    redirect_to church_path(@church)
  end
  
  def load(church_id)
        
    @church = Church.find(church_id)
    @place = @church.place_id
    @county = ChapmanCode.has_key(@church.place.chapman_code)
    @place_name = Place.find( @place)
    @place_name = @place_name.place_name
  end

end
