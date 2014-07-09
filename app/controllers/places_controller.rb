class PlacesController < InheritedResources::Base
  rescue_from Mongoid::Errors::DeleteRestriction, :with => :record_cannot_be_deleted
  rescue_from Mongoid::Errors::Validations, :with => :record_validation_errors
  
  def index
     if session[:userid].nil?
      redirect_to '/', notice: "You are not authorised to use these facilities"
    end
          @chapman_code = session[:chapman_code]
          @places = Place.where( :chapman_code => @chapman_code,:disabled.ne => "true" ).all.order_by( place_name: 1).page(params[:page])
          @county = session[:county]
          @first_name = session[:first_name]
           @user = UseridDetail.where(:userid => session[:userid]).first
           session[:page] = request.original_url
  end

  def list
          
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
  end

def new
       get_places_counties_and_contries
       @place = Place.new
       @counties = ChapmanCode.select_hash
       @countries = Array.new
         Country.all.order_by(country_code: 1).each do |country|
           @countries << country.country_code
         end 
       @user = UseridDetail.where(:userid => session[:userid]).first
  end
 
def create
 
    @user = UseridDetail.where(:userid => session[:userid]).first
    @place = Place.new(params[:place])     
    @place.county = ChapmanCode.has_key(params[:place][:chapman_code])
    @place.modified_place_name = @place.place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase
        #use the lat/lon if present if not calculate from the grid reference
      if @place.latitude.nil? || @place.longitude.nil? || @place.latitude.empty? || @place.longitude.empty? then
         unless (@place.grid_reference.nil? || !@place.grid_reference.is_gridref?) then
            location = @place.grid_reference.to_latlng.to_a if @place.grid_reference.is_gridref?
             @place.latitude = location[0]
             @place.longitude = location[1]
         end
      end
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
    # save place name change in Place
   
    old_place_name = @place.place_name
  
    
    #save the original entry we had
    @place.original_chapman_code = @place.chapman_code unless !@place.original_chapman_code.nil?
    @place.original_county = @place.county unless params[:place][:county].nil?
    @place.original_country = @place.country unless params[:place][:country].nil? 
    @place.original_place_name = @place.place_name unless params[:place][:place_name].nil? 
    @place.original_grid_reference = @place.grid_reference unless params[:place][:grid_reference].nil? 
    @place.original_latitude = @place.latitude unless params[:place][:latitude].nil? 
    @place.original_longitude = @place.longitude unless params[:place][:longitude].nil? 
    @place.original_source =  @place.source unless params[:place][:source].nil? 
    @place.reason_for_change = params[:place][:reason_for_change]
    @place.county = ChapmanCode.name_from_code(params[:place][:county]) unless params[:place][:county].nil?
    @place.chapman_code = params[:place][:county] unless params[:place][:county].nil?
    @place.country = params[:place][:country] unless params[:place][:country].nil?
    @place.place_name = params[:place][:place_name] unless params[:place][:place_name].nil?
    @place.modified_place_name = @place.place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase
    @place.grid_reference = params[:place][:grid_reference]  unless params[:place][:grid_reference].nil?
    @place.latitude = params[:place][:latitude] unless  params[:place][:latitude].nil?
    @place.longitude = params[:place][:longitude] unless params[:place][:longitude].nil?
    @place.place_notes = params[:place][:place_notes] unless params[:place][:place_notes].nil?
    @place.alternateplacenames_attributes = [{:alternate_name => params[:place][:alternateplacename][:alternate_name]}] unless params[:place][:alternateplacename][:alternate_name] == ''
    @place.alternateplacenames_attributes = params[:place][:alternateplacenames_attributes] unless params[:place][:alternateplacenames_attributes].nil?
    @place.chapman_code = session[:chapman_code] if @place.chapman_code.nil?
    @place.genuki_url = params[:place][:genuki_url] unless params[:place][:genuki_url].nil?
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

    @place.source =  params[:place][:source] 
    @place.reason_for_change = params[:place][:reason_for_change]
    @place.other_reason_for_change = params[:place][:other_reason_for_change]
   
    @place.save
  
   if @place.errors.any? then
     flash[:notice] = 'The update of the Place was unsuccessful'
     
     get_places_counties_and_contries
     @place_name = Place.find(session[:place_id]).place_name
     #need to prepare for the edit
     render :action => 'edit'
     return
    end #errors
     successful = true
   unless old_place_name == params[:place][:place_name]
    #deal with place name change
   
     @place.churches.each do |church|
      church_name = church.church_name
      church.registers.each do |register|
       register.freereg1_csv_files.each do |file|
        success = Freereg1CsvFile.update_file_attribute(file,church_name,params[:place][:place_name] )
        successful = false unless success 
       end #register
      end #church
     end #@place
    end # name change
    if successful
      @current_page = session[:page]
      session[:page] = session[:initial_page]
      flash[:notice] = 'The update the Place was successful'
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
    @place.disabled = "true"
    @place.save
    flash[:notice] = 'The deletion of the place was successful'
      if @place.errors.any? then
         @place.errors
         flash[:notice] = 'The deletion of the place was unsuccessful'
      end
    redirect_to places_path
 end

 def get_places_counties_and_contries
   @counties = ChapmanCode.select_hash
   @countries = Array.new
      Country.all.order_by(country_code: 1).each do |country|
        @countries << country.country_code
      end 
   placenames = Place.where(:chapman_code => session[:chapman_code],:disabled.ne => "true").all.order_by(place_name: 1)
   @placenames = Array.new
     placenames.each do |placename|
         @placenames << placename.place_name
     end
 end

 def record_cannot_be_deleted
   flash[:notice] = 'The deletion of the place was unsuccessful because there were dependant documents; please delete them first'
    redirect_to places_path
 end

 def record_validation_errors
   flash[:notice] = 'The update of the children to Place with a place name change failed'
    redirect_to places_path
 end
end