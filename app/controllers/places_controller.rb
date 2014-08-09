class PlacesController < ApplicationController
  rescue_from Mongoid::Errors::DeleteRestriction, :with => :record_cannot_be_deleted
  rescue_from Mongoid::Errors::Validations, :with => :record_validation_errors
  
  def index
     if session[:userid].nil?
      redirect_to '/', notice: "You are not authorised to use these facilities"
    end
          @chapman_code = session[:chapman_code]
          @county = ChapmanCode.has_key(session[:chapman_code])
          if session[:active_place] == 'Active'
              @places = Array.new
                Place.where( :chapman_code => @chapman_code).all.each do |place|
                  @places << place if place.churches.exists?
                end
               @places = Kaminari.paginate_array(@places).page(params[:page])
           else 
            @places = Place.where( :chapman_code => @chapman_code,:disabled.ne => "true").all.order_by( place_name: 1).page(params[:page])  
           end
         
          @first_name = session[:first_name]
           @user = UseridDetail.where(:userid => session[:userid]).first
           session[:page] = request.original_url
  end

  def relocate
    load(params[:id])
     get_places_counties_and_contries
     session[:type] = 'relocate'
     render :edit
          
  end

  def show
          load(params[:id])
          @places = Place.where( :chapman_code => @chapman_code,  :disabled.ne => "true" ).all.order_by( place_name: 1)
          session[:parameters] = params
          @names = Array.new
          @alternate_place_names = @place.alternateplacenames.all
          @alternate_place_names.each do |acn|
          name = acn.alternate_name
          @names << name
         end
        
   end

  def edit
      load(params[:id])
      get_places_counties_and_contries
      @place_name = Place.find(session[:place_id]).place_name
      session[:type] = 'edit'
  end

def new
       get_places_counties_and_contries
       @place = Place.new
       @user = UseridDetail.where(:userid => session[:userid]).first
       session[:type] = 'new'
  end
 
def create
    @user = UseridDetail.where(:userid => session[:userid]).first
    @place = Place.new(params[:place])     
    @place.chapman_code = ChapmanCode.values_at(params[:place][:county])
    @place.modified_place_name = @place.place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase
        #use the lat/lon if present if not calculate from the grid reference
    @place.add_location_if_not_present
      
    @place.alternateplacenames_attributes = [{:alternate_name => params[:place][:alternateplacename][:alternate_name]}] unless params[:place][:alternateplacename][:alternate_name] == ''
    @place.save
     if @place.errors.any?
        #we have errors on the creation
        flash[:notice] = 'The addition to Place Name was unsuccessful'
        get_places_counties_and_contries
        @place_name = Place.find(session[:place_id]).place_name
        render :new
      else
        #we are clean on the addition
        flash[:notice] = 'The addition to Place Name was successful'
        redirect_to places_path
      end
 end

def update
    load(params[:id])
    place_name_change = false
    # save place name change in Place
    unless params[:place][:county].nil? && params[:place][:country].nil? && params[:place][:place_name].nil?
    place_name_change = true unless @place.place_name == params[:place][:place_name]
       #save the original entry we had
    end
    @place.save_to_original # this the last change data for the place
    @place.chapman_code = ChapmanCode.name_from_code(params[:place][:county]) unless params[:place][:county].nil?
    @place.chapman_code = session[:chapman_code] if @place.chapman_code.nil?
    @place.chapman_code = ChapmanCode.name_from_code(params[:place][:county]) unless params[:place][:county].nil?
    @place.chapman_code = session[:chapman_code] if @place.chapman_code.nil?
    @place.alternateplacenames_attributes = [{:alternate_name => params[:place][:alternateplacename][:alternate_name]}] unless params[:place][:alternateplacename][:alternate_name] == ''
    @place.alternateplacenames_attributes = params[:place][:alternateplacenames_attributes] unless params[:place][:alternateplacenames_attributes].nil?
    
    #We use the lat/lon if provided and the grid reference if  lat/lon not available
     change = @place.change_lat_lon(params[:place][:latitude],params[:place][:longitude]) 
   
     @place.change_grid_reference(params[:place][:grid_reference]) if  change == "unchanged"

     params[:place].delete :latitude
     params[:place].delete :longitude
     params[:place].delete :grid_reference
     @place.update_attributes(params[:place])
    
   if @place.errors.any? then
     flash[:notice] = 'The update of the Place was unsuccessful'
     #need to prepare for the edit
     get_places_counties_and_contries
     render :action => 'edit'
     return
    end #errors
     successful = true
     successful = @place.change_name(params[:place][:place_name]) if place_name_change
    if successful
      @current_page = session[:page]
      session[:page] = session[:initial_page]
      flash[:notice] = 'The update of the Place was successful'
      redirect_to @current_page
      return
     else 
     flash[:notice] = 'The update of the Place was unsuccessful'
      get_places_counties_and_contries
      @place_name = Place.find(session[:place_id]).place_name
     render :action => 'edit'
     return
     end
  end

  
  def load(place_id)
   @user = UseridDetail.where(:userid => session[:userid]).first
   @place = Place.find(place_id)
   session[:place_id] = place_id
   @place_name = @place.place_name
   session[:place_name] = @place_name
   @county = ChapmanCode.has_key(@place.chapman_code)
   session[:county] = @county
   @first_name = session[:first_name]

  end

 def destroy
    load(params[:id])

    unless @place.churches.count == 0
       flash[:notice] = 'The Place cannot be disabled because there were dependant churches; please remove them first'
       redirect_to places_path
       return
    end

    @place.disabled = "true"
    @place.save
    flash[:notice] = 'The disabling of the place was successful'
      if @place.errors.any? then
         @place.errors
         flash[:notice] = 'The disabling of the place was unsuccessful'
      end
    redirect_to places_path
 end

 def get_places_counties_and_contries
   @counties = ChapmanCode.keys
   @counties.insert(0,@county)
   @countries = Array.new
      Country.all.order_by(country_code: 1).each do |country|
        @countries << country.country_code
      end 
   placenames = Place.where(:chapman_code => session[:chapman_code],:disabled.ne => "true").all.order_by(place_name: 1)
   @placenames = Array.new
     placenames.each do |placename|
         @placenames << placename.place_name unless placename.county.nil? && placename.country.nil?
     end
 end

 def record_cannot_be_deleted
   flash[:notice] = 'The deletion of the place was unsuccessful because there were dependant documents; please delete them first'
    redirect_to places_path
 end

 def record_validation_errors
   flash[:notice] = 'The validation of Place failed when it should not have done'
    redirect_to places_path
 end
  
  def for_search_form
    chapman_codes = params[:search_query][:chapman_codes]
    
    county_places = PlaceCache.in(:chapman_code => chapman_codes)
    county_response = ""
    county_places.each { |pc| county_response << pc.places_json }

    respond_to do |format|
      format.json do 
        render :json => county_response
      end
    end
  end
end