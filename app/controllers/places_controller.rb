class PlacesController < ApplicationController
  rescue_from Mongoid::Errors::DeleteRestriction, :with => :record_cannot_be_deleted
  rescue_from Mongoid::Errors::Validations, :with => :record_validation_errors

  skip_before_filter :require_login, only: [:for_search_form,:for_freereg_content_form]


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
     @county = session[:county]
    session[:type] = 'edit'

  end
  def rename
    get_user_info_from_userid
    load(params[:id])
    get_places_counties_and_contries
    @county = session[:county]

  end

  def relocate
    get_user_info_from_userid
    load(params[:id])
    @county = session[:county]
    get_places_counties_and_contries
  end

  def merge
    load(params[:id])
    p 'merging into'
    p @place
    errors = @place.merge_places
    p @place
    p errors
    if errors[0]  then
      flash[:notice] = "Place Merge unsuccessful; #{errors[1]}"
      render :action => 'show'
      return
    end
    flash[:notice] = 'The merge of the Places was successful'
    redirect_to place_path(@place)
  end


  def new
    get_places_counties_and_contries
    @place = Place.new
    get_user_info_from_userid
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
    case
    when params[:commit] == 'Submit'
      p 'editing place'
      p params
      p @place
      @place.save_to_original
      p @place
      @place.alternateplacenames_attributes = [{:alternate_name => params[:place][:alternateplacename][:alternate_name]}] unless params[:place][:alternateplacename][:alternate_name].blank?
      @place.alternateplacenames_attributes = params[:place][:alternateplacenames_attributes] unless params[:place][:alternateplacenames_attributes].nil?
      @place.update_attributes(params[:place])
      p @place
      if @place.errors.any?  then
        flash[:notice] = 'The update of the Place was unsuccessful'
        render :action => 'edit'
        return
      end
      flash[:notice] = 'The update the Place was successful'
      redirect_to place_path(@place)
      return
    when params[:commit] == 'Rename'
      p 'renaming place'
      p @place
      errors = @place.change_name(params[:place])
      p @place
      p errors
      if errors[0]  then
        flash[:notice] = "Place rename unsuccessful; #{errors[1]}"
        render :action => 'rename'
        return
      end
      flash[:notice] = 'The rename the Place was successful'
      redirect_to place_path(@place)
      return
    when params[:commit] == 'Relocate'
      p 'relocating place'
      p @place
      errors = @place.relocate_place(params[:place])
      p @place
      p errors
      if errors[0]  then
        flash[:notice] = "Place relocation unsuccessful; #{errors[1]}"
        render :action => 'show'
        return
      end
      flash[:notice] = "The relocation of the Place was successful. \n PLEASE CHECK YOU STILL HAVE THE CORRECT LOCATION INFORMATION"
      redirect_to place_path(@place)
      return
    else
      #we should never get here but just in case
      flash[:notice] = 'The change to the Church was unsuccessful'
      redirect_to place_path(@place)

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
    unless @place.search_records.count == 0 && @place.error_flag == "Place name is not approved"
      unless @place.churches.count == 0
        flash[:notice] = 'The Place cannot be disabled because there were Dependant churches; please remove them first'
        redirect_to places_path
        return
      end
    end
    @place.update_attributes(:disabled => "true", :data_present => false )
    if @place.errors.any? then
      @place.errors
      flash[:notice] = "The disabling of the place was unsuccessful #{@place.errors.messages}"
    end
     flash[:notice] = 'The disabling of the place was successful'
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
  def for_freereg_content_form
    chapman_codes = params[:freereg_content][:chapman_codes]

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
