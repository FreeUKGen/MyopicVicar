class PlacesController < ApplicationController
  rescue_from Mongoid::Errors::DeleteRestriction, :with => :record_cannot_be_deleted
  rescue_from Mongoid::Errors::Validations, :with => :record_validation_errors

  skip_before_filter :require_login, only: [:for_search_form,:for_freereg_content_form]

  def index
    get_user_info_from_userid
    @chapman_code = session[:chapman_code]
    @county = ChapmanCode.has_key(session[:chapman_code])
    if session[:active_place]
      @places = Place.where( :chapman_code => @chapman_code, :data_present => true).all.order_by(place_name: 1)
    else
      @places = Place.where( :chapman_code => @chapman_code,:disabled => 'false').all.order_by(place_name: 1)
    end
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first
    session[:page] = request.original_url
  end

  def new
    get_places_counties_and_countries
    @place = Place.new
    get_user_info_from_userid
    @place.alternateplacenames.build
    @county = session[:county]

  end

  def create
    @user = UseridDetail.where(:userid => session[:userid]).first
    @place = Place.new(place_params)
    @place.chapman_code = ChapmanCode.values_at(params[:place][:county])
    @place.modified_place_name = @place.place_name.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase
    #use the lat/lon if present if not calculate from the grid reference
    @place.add_location_if_not_present
    @place.save
    if @place.errors.any?
      #we have errors on the creation
      flash[:notice] = 'The addition to Place Name was unsuccessful'
      @county = session[:county]
      get_places_counties_and_countries
      @place_name = @place.place_name unless @place.nil?
      render :new
    else
      #we are clean on the addition
      flash[:notice] = 'The addition to Place Name was successful'
      redirect_to place_path(@place)
    end
  end

  def show
    load(params[:id])
  end

  def edit
    load(params[:id])
    get_places_counties_and_countries
    @place_name = Place.find(session[:place_id]).place_name
    @place.alternateplacenames.build
    @county = session[:county]
  end

  def rename
    get_user_info_from_userid
    load(params[:id])
    get_places_counties_and_countries
    @county = session[:county]
    @records = @place.search_records.count
  end

  def relocate
    get_user_info_from_userid
    load(params[:id])
    @county = session[:county]
    get_places_counties_and_countries
    @records = @place.search_records.count

  end

  def update
    load(params[:id])
    case
    when params[:commit] == 'Submit'
      @place.save_to_original
      @place.adjust_location_before_applying(params,session)
      @place.update_attributes(place_params)
      if @place.errors.any?  then
        flash[:notice] = 'The update of the Place was unsuccessful'
        render :action => 'edit'
        return
      end
      flash[:notice] = 'The update the Place was successful'
      redirect_to place_path(@place)
      return
    when params[:commit] == 'Rename'
      errors = @place.change_name(params[:place])
      if errors[0]  then
        flash[:notice] = "Place rename unsuccessful; #{errors[1]}"
        render :action => 'rename'
        return
      end
      flash[:notice] = 'The rename the Place was successful'
      redirect_to place_path(@place)
      return
    when params[:commit] == 'Relocate'
      errors = @place.relocate_place(params[:place])
      if errors[0]  then
        flash[:notice] = "Place filling unsuccessful; #{errors[1]}"
        render :action => 'show'
        return
      end
      flash[:notice] = "The filling of the county country information was successful."
      redirect_to place_path(@place)
      return
    else
      #we should never get here but just in case
      flash[:notice] = 'The change to the Place was unsuccessful'
      redirect_to place_path(@place)
    end
  end

  def destroy
    load(params[:id])
    unless @place.search_records.count == 0 && @place.error_flag == "Place name is not approved"
      unless @place.churches.count == 0
        flash[:notice] = 'The Place cannot be disabled because there were Dependant churches; please remove them first'
        redirect_to places_path(:anchor => "#{@place.id}", :page => "#{session[:place_index_page]}")
        return
      end
    end
    @place.update_attributes(:disabled => "true", :data_present => false )
    if @place.errors.any? then
      @place.errors
      flash[:notice] = "The disabling of the place was unsuccessful #{@place.errors.messages}"
      redirect_to places_path(:anchor => "#{@place.id}", :page => "#{session[:place_index_page]}")
      return
    end
    flash[:notice] = 'The disabling of the place was successful'
    redirect_to places_path(:anchor => "#{@place.id}", :page => "#{session[:place_index_page]}")
  end
  #additional controller actions
  def approve
    session[:return_to] = request.referer
    get_user_info_from_userid
    load(params[:id])
    @place.approve
    flash[:notice] = "Unapproved flag removed; Don't forget you now need to update the Grid Ref as well as check that county and country fields are set."
    redirect_to place_path(@place)
  end

  def merge
    load(params[:id])
    success,message = @place.merge_places
    if !success then
      flash[:notice] = "Place Merge unsuccessful; #{message}"
      render :action => 'show'
      return
    end
    flash[:notice] = 'The merge of the Places was successful'
    redirect_to place_path(@place)
  end
  #controller methods
  def load(place_id)
    @user = UseridDetail.where(:userid => session[:userid]).first
    @place = Place.id(place_id).first
    if @place.nil?
      go_back("place",place_id)
    else
      session[:place_id] = place_id
      @place_name = @place.place_name
      session[:place_name] = @place_name
      @county = ChapmanCode.has_key(@place.chapman_code)
      session[:county] = @county
      @first_name = session[:first_name]
    end
  end

  def for_search_form
    if params[:search_query]
      chapman_codes = params[:search_query][:chapman_codes]
    else
      log_possible_host_change
      chapman_codes = []
    end
    county_places = PlaceCache.in(:chapman_code => chapman_codes)
    county_response = ""
    county_places.each  do |pc|
      county_response << pc.places_json unless pc.nil?
    end
    respond_to do |format|
      format.json do
        render :json => county_response
      end
    end
  end

  def for_freereg_content_form
    unless params[:freereg_content].nil?
      chapman_codes = params[:freereg_content][:chapman_codes]
      county_response = ""
      county_places = PlaceCache.in(:chapman_code => chapman_codes)
      county_places.each do |pc|
        county_response << pc.places_json unless pc.nil?
      end
      respond_to do |format|
        format.json do
          render :json => county_response
        end
      end
    end
  end

  def get_places_counties_and_countries
    @countries = Array.new
    Country.all.order_by(country_code: 1).each do |country|
      @countries << country.country_code
    end
    @counties = ChapmanCode.keys
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
  private
  def place_params
    params.require(:place).permit!
  end
end
