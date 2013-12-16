class MasterPlaceNamesController < ApplicationController

 def index
 #on initial entry we display a county selection; a second entry displays an index of the Master Place Names for the selected county   
    unless params[:commit] == "Search"
          reset_session
          @places = MasterPlaceName.new
    else       
          @places = MasterPlaceName.where( :chapman_code => params[:master_place_name][:chapman_code]).all.order_by( place_name: 1)
          @county = ChapmanCode.has_key(params[:master_place_name][:chapman_code]) 
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
    redirect_to master_place_names_path(params)
  else
    redirect_to :action => :new
  end
 end

 def update
    load(params[:id])
    
    # save place name change in Master Place Name
   
    @place.genuki_url = params[:master_place_name][:genuki_url]
    @place.original_county = @place.county unless @place.chapman_code == params[:master_place_name][:chapman_code]
    @place.original_place_name = @place.place_name unless @place.place_name == params[:master_place_name][:place_name]
    @place.original_grid_reference = @place.grid_reference unless @place.grid_reference == params[:master_place_name][:grid_refernce]
    @place.original_latitude = @place.latitude unless @place.latitude == params[:master_place_name][:latitude]
    @place.original_longitude = @place.longitude unless @place.longitude == params[:master_place_name][:longitude]
    @place.county = ChapmanCode.has_key(params[:master_place_name][:chapman_code])
    @place.place_name = params[:master_place_name][:place_name]
    @place.grid_reference = params[:master_place_name][:grid_refernce]
    @place.latitude = params[:master_place_name][:latitude]
    @place.longitude = params[:master_place_name][:longitude]
    @place.source =  @place.source + params[:master_place_name][:source] unless @place.source == params[:master_place_name][:source]
    @place.reason_for_change = params[:master_place_name][:reason_for_change]
    @place.other_reason_for_change = params[:master_place_name][:other_reason_for_change]
    @place.save!

   flash[:notice] = 'The change in Master Place Name document was succsessful'
   redirect_to :action => 'show'
 end

 def new
   load(params[:id])
    @place.county = ChapmanCode.has_key(params[:master_place_name][:chapman_code])
    @place.place_name = params[:master_place_name][:place_name]
    @place.grid_reference = params[:master_place_name][:grid_refernce]
    @place.latitude = params[:master_place_name][:latitude]
    @place.longitude = params[:master_place_name][:longitude]
    @place.source =  @place.source + params[:master_place_name][:source]
    @place.save!
    flash[:notice] = 'The addition of the Master Place Name document was succsessful'
    redirect_to :action => 'show'
 end

 def destroy
    load(params[:id])
    @place.destroy
    redirect_to places_path
 end

 def load(place_id)
   @place = MasterPlaceName.find(place_id)
   session[:place_id] = place_id
   @place_name = @place.place_name
   session[:place_name] = @place_name
   @county = ChapmanCode.has_key(@place.chapman_code)
   session[:county] = @county
 end

end
