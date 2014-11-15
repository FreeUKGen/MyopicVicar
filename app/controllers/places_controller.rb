class PlacesController < ApplicationController
  rescue_from Mongoid::Errors::DeleteRestriction, :with => :record_cannot_be_deleted
  rescue_from Mongoid::Errors::Validations, :with => :record_validation_errors

  skip_before_filter :require_login, only: [:for_search_form]

  
  def index
     get_user_info_from_userid
          @chapman_code = session[:chapman_code]
          @county = ChapmanCode.has_key(session[:chapman_code])
          if session[:active_place] == 'Active'
              @places = Array.new
                Place.where( :chapman_code => @chapman_code).all.order_by( place_name: 1).each do |place|
                  @places << place if place.churches.exists?
                end
               @places = Kaminari.paginate_array(@places).page(params[:page])
           else 
            @places = Place.where( :chapman_code => @chapman_code,:disabled => 'false').all.order_by( place_name: 1).page(params[:page])  
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
          @names = @place.get_alternate_place_names
        
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
    @place.update_attributes(params[:place])
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
    if session[:type] == 'relocate' #place_name_change
      p "relocating"
      if  ChapmanCode.values_at(params[:place][:county]) == session[:chapman_code]
        #not changing county
        successful = @place.change_name(params[:place][:place_name],params[:place][:county])
      else
        #changing county
        @county = params[:place][:county]
        flash[:notice] = 'Relocating to a place in the new county'
        session[:chapman_code] = ChapmanCode.values_at(params[:place][:county])
        get_places_counties_and_contries
        render :action => 'edit'
        return
      end # county change
     unless successful
      flash[:notice] = 'The update of the Place was unsuccessful'
      get_places_counties_and_contries
      @place_name = Place.find(session[:place_id]).place_name
      render :action => 'edit'
      return
     end # successfull
    else
      #not relocating
    old_place_name = @place.place_name
    new_place_name = params[:place][:place_name]
    #just changing fields for place
     #save the orginal data
    @place.save_to_original 
     #adjust lat and lon and other fields
    @place.adjust_params_before_applying(params,session)
    @place.update_attributes(params[:place])
    @place.update_attributes(:modified_place_name => @place.place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase)
    @place.change_name(new_place_name,ChapmanCode.name_from_code(@place.chapman_code)) unless new_place_name.nil? || old_place_name == new_place_name
     if @place.errors.any? then
      flash[:notice] = 'The update of the Place was unsuccessful'
      #need to prepare for the edit
      get_places_counties_and_contries
      render :action => 'edit'
      return
     end #errors 
    end # relocate
      session[:type] = nil
      @current_page = session[:page]
      session[:page] = session[:initial_page]
      flash[:notice] = 'The update of the Place was successful'
      redirect_to @current_page
     
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
    unless @place.search_records.count == 0 && @place.error_flag == "Place name is not approved"
      unless @place.churches.count == 0
       flash[:notice] = 'The Place cannot be disabled because there were dependant churches; please remove them first'
       redirect_to places_path
       return
      end
    end
    @place.disabled = "true"
    @place.data_present = false
    @place.save
    flash[:notice] = 'The disabling of the place was successful'
      if @place.errors.any? then
         @place.errors
         flash[:notice] = 'The disabling of the place was unsuccessful'
      end
    redirect_to places_path
 end

 def get_places_counties_and_contries
   @countries = Array.new
   Country.all.each do |country|
    @countries << country.country_code
   end
   @countries.insert(0,'England')
   @counties = ChapmanCode.keys
   @counties.insert(0,@county)
     placenames = Place.where(:chapman_code => session[:chapman_code],:disabled => 'false',:error_flag.ne => "Place name is not approved").all.order_by(place_name: 1)
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