class MasterPlaceNamesController < ActionController::Base
    
 def index
 #on initial entry we display a county selection; a second entry displays an index of the Master Place Names for the selected county   
    unless params[:commit] == "Search"
      #coming through for the very first time so we will go get a county
          reset_session
          @places = MasterPlaceName.new
    else  
    #coming through for the second time with knowledge of the county so will offer the index of places in that county     
          @places = MasterPlaceName.where( :chapman_code => params[:master_place_name][:chapman_code]).all.order_by( place_name: 1)
          @county = ChapmanCode.has_key(params[:master_place_name][:chapman_code]) 
          session[:county] = @county
          session[:chapman_code] = params[:master_place_name][:chapman_code]
          #reset the session errors flag
      
          session[:form] = nil
          session[:parameters] = params
    end

  end

  def show
    load(params[:id])
    #make sure the show is clean and ready for an edit
    session[:type] = "edit"
 
    
  end

 def edit
   load(params[:id])
  
   @place = session[:form] if (!session[:form].nil? && session[:type] = "new")
   session[:type] = "edit"
  
 end

 def create
  #our first pass through is following the selection of a county
  if params[:commit] == "Search"
    redirect_to master_place_names_path(params)
  else
    #this time we are creally creating a new entry
    
    @place =  session[:form] 
    @place.genuki_url = params[:master_place_name][:genuki_url]
    @place.chapman_code = params[:master_place_name][:chapman_code]
    @place.county = ChapmanCode.has_key(params[:master_place_name][:chapman_code])
    @place.country = params[:master_place_name][:country]
    @place.place_name = params[:master_place_name][:place_name]
    @place.modified_place_name = @place.place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase
    @place.grid_reference = params[:master_place_name][:grid_reference]
    @place.latitude = params[:master_place_name][:latitude]
    @place.longitude = params[:master_place_name][:longitude]

      #use the lat/lon if present if not calculate from the grid reference
    if @place.latitude.nil? || @place.longitude.nil? || @place.latitude.empty? || @place.longitude.empty? then
     unless (@place.grid_reference.nil? || !@place.grid_reference.is_gridref?) then
      location = @place.grid_reference.to_latlng.to_a if @place.grid_reference.is_gridref?
      @place.latitude = location[0]
      @place.longitude = location[1]
     end
    end
    @place.source = params[:master_place_name][:source] 
    @place.reason_for_change = params[:master_place_name][:reason_for_change]
    @place.other_reason_for_change = params[:master_place_name][:other_reason_for_change]
    @place.save
    if @place.errors.any?
      #we have errors on the creation
   
    session[:form] =  @place
   
    flash[:notice] = 'The addition to Master Place Name was unsuccsessful'
    render :new
   else
    #we are clean on the addition
  
   session[:form] = nil
   session[:type] = "edit"
   flash[:notice] = 'The addition to Master Place Name was succsessful'
   redirect_to master_place_name_path(@place)
   end

  end
 end

 def update
    load(params[:id])
    
    # save place name change in Master Place Name
   
    @place.genuki_url = params[:master_place_name][:genuki_url] unless params[:master_place_name][:genuki_url].nil?
    #save the original entry we had
    @place.original_chapman_code = session[:chapman_code] unless !@place.original_chapman_code.nil?
    @place.original_county = session[:county] unless !@place.original_county.nil?
    @place.original_country = @place.country unless params[:master_place_name][:country].nil? || !@place.original_country.nil?
    @place.original_place_name = @place.place_name unless params[:master_place_name][:place_name].nil? || !@place.original_place_name.nil?
    @place.original_grid_reference = @place.grid_reference unless params[:master_place_name][:grid_reference].nil? || !@place.original_grid_reference.nil?
    @place.original_latitude = @place.latitude unless params[:master_place_name][:latitude].nil? || !@place.original_latitude.nil?
    @place.original_longitude = @place.longitude unless params[:master_place_name][:longitude].nil? || !@place.original_longitude.nil?
    @place.original_source =  @place.source unless params[:master_place_name][:source].nil? || !@place.original_source.nil?
    @place.reason_for_change = params[:master_place_name][:reason_for_change]
    @place.county = session[:county]
    @place.country = params[:master_place_name][:country]
    @place.place_name = params[:master_place_name][:place_name]
    @place.modified_place_name = @place.place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase
    @place.grid_reference = params[:master_place_name][:grid_reference]
    @place.latitude = params[:master_place_name][:latitude]
    @place.longitude = params[:master_place_name][:longitude]
   #use the lat/lon if present if not calculate from the grid reference
    if @place.latitude.nil? || @place.longitude.nil? || @place.latitude.empty? || @place.longitude.empty? then
        unless (@place.grid_reference.nil? || !@place.grid_reference.is_gridref?) then
           location = @place.grid_reference.to_latlng.to_a if @place.grid_reference.is_gridref?
           @place.latitude = location[0]
           @place.longitude = location[1]
        end
      else
        #have they changed?
        if @place.original_latitude == @place.latitude && @place.original_longitude == @place.longitude
          #yes they have not changed so use Grid ref
          unless (@place.grid_reference.nil? || !@place.grid_reference.is_gridref?) then
            location = @place.grid_reference.to_latlng.to_a if @place.grid_reference.is_gridref?
            @place.latitude = location[0]
            @place.longitude = location[1]
          end
        end
      end
    @place.source =  params[:master_place_name][:source] 
    @place.reason_for_change = params[:master_place_name][:reason_for_change]
    @place.other_reason_for_change = params[:master_place_name][:other_reason_for_change]
    @place.save
   if @place.errors.any?
      #we have errors in the editing
   
    session[:form] = @place
    flash[:notice] = 'The change in Master Place Name record was unsuccsessful'
    render :edit
   else
   session[:form] =  nil
   flash[:notice] = 'The change in Master Place Name record was succsessful'
   redirect_to :action => 'show'
   end
 end

 def new
   
      #coming through new for the first time so get a new instance
      @place = MasterPlaceName.new
      @place.chapman_code = session[:chapman]
      @place.county = session[:county]
      session[:form] = @place
      @county = session[:county]
     
    
     #Coming through new with errors
     @place = session[:form]
    
    session[:type] = "new"
  end

 def destroy
    load(params[:id])
    @place.disabled = "true"
    @place.save
    params = session[:parameters]
    #redirect_to :action => 'index'
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
rescue
end
