class MasterPlaceNamesController < ActionController::Base
    
 def index
   if session[:userid].nil?
      redirect_to '/', notice: "You are not authorised to use these facilities"
    end
         @chapman_code = session[:chapman_code]
          @county = session[:county]
           @first_name = session[:first_name]
         
          @places = MasterPlaceName.where( :chapman_code =>  @chapman_code).all.order_by( place_name: 1)
  end

  def show
    load(params[:id])
       @first_name = session[:first_name]   
  end

 def edit
   load(params[:id]) 
   session[:type] = "edit"
     @first_name = session[:first_name]
 end

 def create
     @place = MasterPlaceName.new
      
    @place.place_name =  params[:master_place_name][:place_name] 
    @place.genuki_url = params[:master_place_name][:genuki_url] unless params[:master_place_name][:genuki_url].nil?
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
    
    flash[:notice] = 'The addition to Master Place Name was unsuccsessful'
    render :new
   else
    #we are clean on the addition
  
  
  
   flash[:notice] = 'The addition to Master Place Name was succsessful'

   redirect_to master_place_name_path(@place)
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
   
    @place = MasterPlaceName.new
      @place.chapman_code = session[:chapman_code]
      @place.county = session[:county]
      
      @first_name = session[:first_name]
      @county = session[:county]
      session[:type] = "new"
  end

 def destroy
    load(params[:id])
    @place.disabled = "true"
    @place.save
   
   
     flash[:notice] = 'The discard of the Master Place Name record was succsessful'
    redirect_to master_place_names_path
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
