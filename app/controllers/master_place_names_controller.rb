class MasterPlaceNamesController < InheritedResources::Base

 def index
 #on initial entry we display a county selection; a second entry displays an index of the Master Place Names for the selected county   
    unless params[:commit] == "Search"
          reset_session
          @places = MasterPlaceName.new
    else       
          @places = MasterPlaceName.where( :chapman_code => params[:master_place_name][:chapman_code]).all.order_by( place_name: 1)
          @county = ChapmanCode.has_key(params[:master_place_name][:chapman_code]) 
          session[:county] = @county
          session[:chapman] = params[:master_place_name][:chapman_code]
    end

  end

  def show
    load(params[:id])
  end

 def edit
   load(params[:id])
   session[:type] = "edit"
 end

 def create
  if params[:commit] == "Search"
    redirect_to master_place_names_path(params)
  else
    p params
    @place =  session[:form] 
    @place.genuki_url = params[:master_place_name][:genuki_url]
    @place.chapman_code = session[:chapman]
    @place.county = session[:county]
    @place.country = params[:master_place_name][:country]
    @place.place_name = params[:master_place_name][:place_name]
    @place.grid_reference = params[:master_place_name][:grid_reference]
    @place.latitude = params[:master_place_name][:latitude]
    @place.longitude = params[:master_place_name][:longitude]
    @place.source = params[:master_place_name][:source] 
    @place.reason_for_change = params[:master_place_name][:reason_for_change]
    @place.other_reason_for_change = params[:master_place_name][:other_reason_for_change]
    @place.save!

   flash[:notice] = 'The addition of the Master Place Name document was succsessful'
   redirect_to master_place_name_path(@place)
  end
 end

 def update
    load(params[:id])
    
    # save place name change in Master Place Name
   
    @place.genuki_url = params[:master_place_name][:genuki_url]
    @place.original_chapman_code = @place.chapman_code unless params[:master_place_name][:chapman_code].nil? || @place.chapman_code == params[:master_place_name][:chapman_code]
    @place.original_county = @place.county unless params[:master_place_name][:county].nil? || @place.county == params[:master_place_name][:county]
    @place.original_country = @place.country unless params[:master_place_name][:country].nil? || @place.country == params[:master_place_name][:country]
    @place.original_place_name = @place.place_name unless params[:master_place_name][:place_name].nil? || @place.place_name == params[:master_place_name][:place_name]
    @place.original_grid_reference = @place.grid_reference unless params[:master_place_name][:grid_reference].nil? || @place.grid_reference == params[:master_place_name][:grid_reference]
    @place.original_latitude = @place.latitude unless params[:master_place_name][:latitude].nil? || @place.latitude == params[:master_place_name][:latitude]
    @place.original_longitude = @place.longitude unless params[:master_place_name][:longitude].nil? || @place.longitude == params[:master_place_name][:longitude]
    @place.county = ChapmanCode.has_key(params[:master_place_name][:chapman_code])
    @place.country = params[:master_place_name][:country]
    @place.place_name = params[:master_place_name][:place_name]
    @place.grid_reference = params[:master_place_name][:grid_reference]
    @place.latitude = params[:master_place_name][:latitude]
    @place.longitude = params[:master_place_name][:longitude]
    @place.source =  @place.source + params[:master_place_name][:source] unless @place.source.nil? || @place.source == params[:master_place_name][:source]
    @place.reason_for_change = params[:master_place_name][:reason_for_change]
    @place.other_reason_for_change = params[:master_place_name][:other_reason_for_change]
    @place.save!

   flash[:notice] = 'The change in Master Place Name document was succsessful'
   redirect_to :action => 'show'
 end

 def new
    @place = MasterPlaceName.new
    @place.chapman_code = session[:chapman]
    @place.county = session[:county]
    session[:form] = @place
    @county = session[:county]
    session[:type] = "new"
 end

 def destroy
    load(params[:id])
    @place.destroy
    redirect_to master_place_names_path(params)
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
