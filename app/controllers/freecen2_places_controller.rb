# Copyright 2012 Trustees of FreeBMD
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
#
class Freecen2PlacesController < ApplicationController
  rescue_from Mongoid::Errors::DeleteRestriction, with: :record_cannot_be_deleted
  rescue_from Mongoid::Errors::Validations, with: :record_validation_errors

  skip_before_action :require_login, only: [:for_search_form, :for_freereg_content_form, :for_freecen2_piece_form]

  def active_index
    get_user_info_from_userid
    @chapman_code = session[:chapman_code]
    @county = ChapmanCode.has_key(session[:chapman_code])
    @places = Freecen2Place.where(chapman_code: @chapman_code, data_present: true).all.order_by(place_name: 1)
    @user = get_user
    @first_name = @user.person_forename if @user.present?
    session[:page] = request.original_url
    session[:manage_places] = true
    session[:type] = 'active_place_index'
  end


  def approve
    session[:return_to] = request.referer
    load(params[:id])
    redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: 'That place does not exist') && return if @place.blank?

    get_user_info_from_userid
    @place.approve
    flash[:notice] = "Unapproved flag removed; Don't forget you now need to update the Grid Ref as well as check that county and country fields are set."
    redirect_to freecen2_place_path(@place)
  end

  def create
    @user = get_user
    params[:freecen2_place][:editor] = @user.userid
    @first_name = @user.person_forename if @user.present?
    if params[:commit] == 'Search Place Names'
      session[:search_names] = {}
      session[:search_names][:search] = params[:freecen2_place][:place_name]
      session[:search_names][:search_county] = params[:freecen2_place][:county]
      session[:search_names][:advanced_search] = params[:freecen2_place][:advanced_search]
      redirect_to search_names_results_freecen2_place_path
    else
      params[:freecen2_place][:chapman_code] = ChapmanCode.values_at(params[:freecen2_place][:county])
      params[:freecen2_place][:grid_reference] = params[:freecen2_place][:grid_reference].strip if params[:freecen2_place][:grid_reference].present?
      @place = Freecen2Place.new(freecen2_place_params)

      proceed, message, place = @place.check_and_set(params)
      if proceed && message == 'Proceed'
        @place.save
        if @place.errors.any?
          # we have errors on the creation
          flash[:notice] = 'The addition of a place was unsuccessful: (See fields below for actual error and explanations)'
          @county = session[:county]
          @place_name = @place.place_name if @place.present?
          render :new
        else
          # we are clean on the addition
          flash[:notice] = 'The addition to a place was successful'
          redirect_to(freecen2_place_path(@place)) && return
        end
      else
        if proceed
          # we are clean on the addition
          flash[:notice] = 'The addition to a place was successful'
          redirect_to(freecen2_place_path(place)) && return
        else
          flash[:notice] = "The addition of a place was unsuccessful: #{message}"
          @county = session[:county]
          places_counties_and_countries
          @place_name = @place.place_name if @place.present?
          @place.alternate_freecen2_place_names.build
          @place.alternate_freecen2_place_names.build
          @place.alternate_freecen2_place_names.build

          get_sources

          render :new
        end
      end
    end
  end

  def destroy
    load(params[:id])
    redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: 'That place does not exist') && return if @place.blank?

    if @place.error_flag == 'Place name is not approved' || @place.disabled == 'true'
      redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: 'The Place is not approved or is already disabled') && return

    elsif @place.search_records.exists?
      redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: 'The Place cannot be disabled because there are dependent search records') && return

    elsif @place.freecen2_districts.exists? || @place.freecen2_pieces.exists? || @place.freecen2_civil_parishes.exists?
      redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: 'The Place cannot be disabled because there are dependent districts, sub districts or civil parishes') && return
    end
    @place.update_attributes(disabled: 'true', data_present: false)
    if @place.errors.any?
      redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: "The disabling of the place was unsuccessful #{@place.errors.messages}") && retuurn

    elsif session[:search_names].nil?
      flash[:notice] = 'The disabling of the place was successful'
      redirect_to(freecen2_places_path) && return
    elsif session[:search_names].present?
      flash[:notice] = 'The disabling of the place was successful'
      redirect_to(search_names_results_freecen2_place_path) && return
    else
      flash[:notice] = 'The disabling of the place was successful'
      redirect_to(search_names_freecen2_place_path) && return
    end
  end

  def edit
    load(params[:id])
    redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: 'That place does not exist') && return if @place.blank?

    get_user_info_from_userid
    permitted = %w[county_coordinator master_county_coordinator country_coordinator system_administrator data_manager validator
                   executive_director project_manager].include?(@user.person_role) ? true : false
    redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: 'You are not permitted to edit a place') && return unless permitted

    @county = @place.county
    @chapman_code = @place.chapman_code
    if @chapman_code == 'LND' ||  @chapman_code == 'WLS'
      message = 'Only system administrators and data administrator can edit LND and WLS'
      redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: message) && return unless
      %w[system_administrator data_manager].include?(@user.person_role)
    end
    @place_name = @place.place_name
    @place.alternate_freecen2_place_names.build
    @place.alternate_freecen2_place_names.build
    @place.alternate_freecen2_place_names.build

    get_reasons
    get_sources

  end

  def for_search_form
    if params[:search_query]
      chapman_codes = params[:search_query][:chapman_codes]
    else
      log_possible_host_change
      chapman_codes = []
    end
    county_places = Freecen2PlaceCache.in(chapman_code: chapman_codes)
    county_response = ''
    county_places.each do |pc|
      county_response << pc.places_json if pc.present?
    end
    respond_to do |format|
      format.json do
        render json: county_response
      end
    end
  end



  def index
    get_user_info_from_userid
    @chapman_code = session[:chapman_code]
    @county = ChapmanCode.has_key(session[:chapman_code])
    if session[:active_place]
      @places = Freecen2Place.where(chapman_code: @chapman_code, data_present: true).all.order_by(place_name: 1)
    else
      @places = Freecen2Place.where(chapman_code: @chapman_code, disabled: 'false').all.order_by(place_name: 1)
    end
    @user = get_user
    @first_name = @user.person_forename if @user.present?
    session[:page] = request.original_url
    session[:manage_places] = true
    session[:type] = 'place'
  end

  def full_index
    get_user_info_from_userid
    @chapman_code = session[:chapman_code]
    @county = ChapmanCode.has_key(session[:chapman_code])
    if session[:active_place]
      @places = Freecen2Place.where(chapman_code: @chapman_code, data_present: true).all.order_by(place_name: 1)
    else
      @places = Freecen2Place.where(chapman_code: @chapman_code, disabled: 'false').all.order_by(place_name: 1)
    end
    @user = get_user
    @first_name = @user.person_forename if @user.present?
    session[:page] = request.original_url
    session[:manage_places] = true
    session[:type] = 'place_index'
  end

  def get_reasons
    @reasons = []
    PlaceEditReason.all.order_by(reason: 1).each do |reason|
      @reasons << reason.reason
    end
  end

  def get_sources
    sources_array = Freecen2PlaceSource.all.map { |rec| [rec.source, rec.source.downcase] }
    sources_array_sorted = sources_array.sort_by { |entry| entry[1] }
    @sources = []
    sources_array_sorted.each do |entry|
      @sources << entry[0]
    end
  end

  def load(place_id)
    @place = Freecen2Place.find_by(id: place_id)
    return if @place.blank?

    @user = get_user
    @first_name = @user.person_forename if @user.present?
    session[:place_id] = place_id
    @place_name = @place.place_name
    session[:place_name] = @place_name
    @chapman_code = @place.chapman_code
    @county = ChapmanCode.has_key(@place.chapman_code)
    @first_name = session[:first_name]
  end

  def new
    get_user_info_from_userid
    permitted = %w[county_coordinator master_county_coordinator country_coordinator system_administrator data_manager validator
                   executive_director project_manager].include?(@user.person_role) ? true : false
    redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: 'You are not permitted to create a new place') && return unless permitted

    @place_name = params[:place] if params[:place].present?
    @place = Freecen2Place.new
    @chapman_code = session[:chapman_code]
    @place.alternate_freecen2_place_names.build
    @place.alternate_freecen2_place_names.build
    @place.alternate_freecen2_place_names.build
    @county = session[:county]
    @counties = ChapmanCode.keys.sort
    @counties -= Freecen::UNNEEDED_COUNTIES
    @counties << 'London (City)' if %w[system_administrator data_manager].include?(@user.person_role)
    @counties << 'Wales' if %w[system_administrator data_manager].include?(@user.person_role)

    get_sources
  end

  def places_counties_and_countries
    @countries = []
    Country.all.order_by(country_code: 1).each do |country|
      @countries << country.country_code
    end
    @counties = ChapmanCode.keys.sort
    @counties -= Freecen::UNNEEDED_COUNTIES
    @placenames = Freecen2Place.place_names(session[:chapman_code])
  end

  def record_cannot_be_deleted
    flash[:notice] = 'The deletion of the place was unsuccessful because there were dependent documents; please delete them first'
    redirect_to freecen2_places_path
  end

  def record_validation_errors
    flash[:notice] = 'The validation of Place failed when it should not have done'
    redirect_to freecen2_places_path
  end

  def rename
    load(params[:id])
    redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: 'That place does not exist') && return if @place.blank?

    get_user_info_from_userid
    places_counties_and_countries
    @county = session[:county]
    @chapman_code = @place.chapman_code
    @records = @place.search_records.count
    max_records = get_max_records(@user)
    if @records.present? && @records.to_i >= max_records
      flash[:notice] = 'There are too many records for an on-line relocation'
      redirect_to(action: 'show') && return
    end
  end

  def search_names
    @counties = ChapmanCode.keys.sort
    @counties = @counties.delete_if { |county| county == 'Unknown' }
    get_user_info_from_userid
    @place_name = session[:search_names].present? ? session[:search_names][:search] : ''
    if session[:search_names].present?
      if session[:search_names][:clear_county]
        @county = ''
        session[:search_names][:clear_county] = false
      else
        @county = session[:search_names].present? ? session[:search_names][:search_county] : ''
      end
    end
    @advanced_search = session[:search_names].present? ? session[:search_names][:advanced_search] : 'not_applicable'
    @freecen2_place = Freecen2Place.new(place_name: @place_name, county: @county)
    #session.delete(:search_names) if session[:search_names].present?
    #session[:search_names] = []
  end

  def search_names_results
    get_user_info_from_userid
    return redirect_back(fallback_location: search_names_freecen2_place_path, notice: 'No prior search') if session[:search_names].blank?

    search_place = session[:search_names][:search]
    return redirect_back(fallback_location: search_names_freecen2_place_path, notice: 'No prior result search') if search_place.blank?

    search_county = session[:search_names][:search_county]
    @advanced_search = session[:search_names][:advanced_search]
    if @advanced_search.present?
      redirect_back(fallback_location: search_names_freecen2_place_path, notice: 'Advanced search must contain alphabetic characters only') && return unless search_place.match(/^[A-Za-z ]+$/)
      if @advanced_search != "soundex" && @advanced_search != "not_applicable"
        redirect_back(fallback_location: search_names_freecen2_place_path, notice: 'Partial searches must contain at least 3 characters') && return unless Freecen2Place.standard_place(search_place).length >=3
      end
    end
    case @advanced_search
    when "soundex"
      place_soundex = Text::Soundex.soundex(Freecen2Place.standard_place(search_place))
      @type_head = 'Soundex'
      @results = Freecen2Place.sound_search(place_soundex, search_county)
    when "starts_with"
      regexp = BSON::Regexp::Raw.new('^' + Freecen2Place.standard_place(search_place))
      @type_head = 'Starts with'
      @results = Freecen2Place.regexp_search(regexp, search_county)
    when "contains"
      regexp = BSON::Regexp::Raw.new(Freecen2Place.standard_place(search_place))
      @type_head = 'Contains string'
      @results = Freecen2Place.regexp_search(regexp, search_county)
    when "ends_with"
      regexp = BSON::Regexp::Raw.new(Freecen2Place.standard_place(search_place) + '$')
      @type_head = 'Ends with'
      @results = Freecen2Place.regexp_search(regexp, search_county)
    else
      @type_head = ''
      @results = Freecen2Place.search(search_place, search_county)
    end
    @county = search_county.present? ? search_county : 'All Counties'
    @total = @results.length
  end

  def selection_by_name
    @chapman_code = session[:chapman_code]
    get_user_info_from_userid
    @freecen2_place = Freecen2Place.new
    freecen2_places = {}
    Freecen2Place.chapman_code(@chapman_code).not_disabled.order_by(place_name: 1).each do |place|
      freecen2_places["#{place.place_name}"] = place._id
    end
    @options = freecen2_places
    @location = 'location.href= "/freecen2_places/" + this.value'
    @prompt = 'Select the specific Place'
    session[:type] = 'place_name'
    render '_form_for_selection'
  end

  def show
    load(params[:id])
    redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: 'That place does not exist') && return if @place.blank?

    session.delete(:from)
  end

  def show_place_edits
    load(params[:id])
    redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: 'That place does not exist') && return if @place.blank?
    @edits = @place.freecen2_place_edits.order_by(_id: -1)
  end

  def update
    load(params[:id])
    redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: 'That place does not exist') && return if @place.blank?

    case
    when params[:commit] == 'Submit'

      if params[:freecen2_place][:source].blank?
        flash[:notice] = 'The source field cannot be empty'
        get_reasons
        get_sources
        render action: 'edit'
        return
      end

      if Freecen2Place.invalid_url?(params[:freecen2_place][:genuki_url])
        flash[:notice] = 'The valid Website for Place Source is required'
        get_reasons
        get_sources
        render action: 'edit'
        return
      end

      error_message = @place.check_alternate_names(params[:freecen2_place][:alternate_freecen2_place_names_attributes], @place.chapman_code, params[:freecen2_place][:place_name])
      unless error_message == 'None'
        flash[:notice] = error_message
        get_reasons
        get_sources
        @place.alternate_freecen2_place_names.build
        @place.alternate_freecen2_place_names.build
        @place.alternate_freecen2_place_names.build
        render action: 'edit'
        return
      end

      @place.save_to_original
      @place.add_freecen2_place_edit(params)

      proceed = @place.update_attributes(freecen2_place_params)

      if proceed
        flash[:notice] = 'The update the Place was successful'
        redirect_to freecen2_place_path(@place)
      else
        flash[:notice] = 'The update of the Place was unsuccessful'
        render action: 'edit'
      end
      return
    when params[:commit] == 'Rename'
      proceed, message = @place.change_name(params[:freecen2_place])
      if proceed
        flash[:notice] = 'The rename the Place was successful'
        redirect_to freecen2_place_path(@place)
      else
        flash[:notice] = "Place rename unsuccessful; #{message}"
        render action: 'rename'
      end
      return
    else
      # we should never get here but just in case
      flash[:notice] = 'The change to the Place was unsuccessful'
      redirect_to freecen2_place_path(@place)
    end
  end

  private

  def freecen2_place_params
    params.require(:freecen2_place).permit!
  end
end
