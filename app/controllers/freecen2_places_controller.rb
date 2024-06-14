#review Copyright 2012 Trustees of FreeBMD
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

  require 'chapman_code'
  require 'freecen_constants'

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
    case params[:commit]
    when 'Search Place Names'
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
      redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: 'The Place is not approved or is disabled') && return

    elsif @place.search_records.exists?
      redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: 'The Place cannot be deleted because there are dependent search records') && return

    elsif @place.freecen2_districts.exists? || @place.freecen2_pieces.exists? || @place.freecen2_civil_parishes.exists?
      redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: 'The Place cannot be deleted because there are dependent districts, sub districts or civil parishes') && return
    else
      used_as_birth_place = Freecen2Place.search_records_birth_places?(@place)
      redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: 'The Place cannot be deleted because there are search records with this place recorded as birth place') && return if used_as_birth_place

    end
    # @place.update_attributes(disabled: 'true', data_present: false) - disabled flag is obsolete when deleting/destroying a place but is used in Move Place linkages 2024/03
    place_name_deleted = @place.place_name
    @place.delete
    if @place.errors.any?
      redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: "The deletion of the place (#{place_name_deleted}) was unsuccessful #{@place.errors.messages}") && retuurn

    elsif session[:search_names].nil?
      flash[:notice] = "The deletion of the place (#{place_name_deleted}) was successful"
      redirect_to(freecen2_places_path) && return
    elsif session[:search_names].present?
      flash[:notice] = "The deletion of the place (#{place_name_deleted}) was successful"
      redirect_to(search_names_results_freecen2_place_path) && return
    else
      flash[:notice] = "The deletion of the place (#{place_name_deleted}) was successful"
      redirect_to(search_names_freecen2_place_path) && return
    end
  end

  def edit
    load(params[:id])
    redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: 'That place does not exist') && return if @place.blank?

    get_user_info_from_userid
    permitted = %w[county_coordinator master_county_coordinator country_coordinator system_administrator data_manager validator
                   executive_director project_manager].include?(session[:role]) ? true : false
    redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: 'You are not permitted to edit a place') && return unless permitted

    @county = @place.county
    @chapman_code = @place.chapman_code
    if @chapman_code == 'LND'
      lnd_county_coord = County.find_by(chapman_code: @chapman_code)
      message = 'Only system administrators, data administrator and LND county coordinator can edit LND'
      redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: message) && return unless
      %w[system_administrator data_manager].include?(session[:role]) || @user.userid == lnd_county_coord.county_coordinator
    elsif @chapman_code == 'WLS'
      message = 'Only system administrators and data administrator can edit WLS'
      redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: message) && return unless
      %w[system_administrator data_manager].include?(session[:role])
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

  def get_counties_for_selection
    @county_codes = []
    ChapmanCode::CODES.each do |_country, counties|
      counties.each do |key, value|
        @county_codes << value
      end
    end
    @county_codes = @county_codes.sort
    @county_codes = @county_codes.delete_if { |code| code == 'UNK' }
    @county_codes = @county_codes.delete_if { |code| code == 'OVB' } # GitHub story 1310
    @counties = {}
    @county_codes.each do |code|
      cnty_name = ChapmanCode.name_from_code(code)
      key = "#{code} - #{cnty_name}"
      @counties[key] = cnty_name
    end
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

  def move
    load(params[:id])
    redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: 'That place does not exist') && return if @place.blank?

    get_user_info_from_userid
    @county = session[:county]
    @chapman_code = @place.chapman_code
    @all_counties = Freecen2Place.where(disabled: 'false').distinct('chapman_code').sort_by(&:downcase)
    @counties = {}
    @counties = { '' => 'Select a County ... ' }
    @all_counties.each { |county| @counties[county] = county }
    session[:move_old_county] = @chapman_code
    session[:move_old_place] = @place.place_name
    session[:move_new_county] = ''
    session[:move_new_place] = ''
    if params[:commit] == 'Review Details'
      session[:move_old_county] = @place.chapman_code
      session[:move_old_place] = @place.place_name
      session[:move_new_county] = params[:county_new]
      session[:move_new_place] = params[:place_new]
      redirect_to review_move_freecen2_place_path
    end
  end

  def move_place_names
    county_new = params[:county_new]
    county_old = session[:move_old_county]
    place_old = session[:move_old_place]
    if county_new.present?
      @county_places = Freecen2Place.where(chapman_code: county_new, disabled: 'false').order_by(place_name: 1)
      county_places_hash = { '' => "Select a Place in #{county_new} ..." }
      @county_places.each { |place|
        next if place.chapman_code == county_old && place.place_name == place_old

        county_places_hash[place.place_name] = place.place_name
      }
      if county_places_hash.present? && county_places_hash.length > 1
        respond_to do |format|
          format.json do
            render json: county_places_hash
          end
        end
      else
        flash[:notice] = 'An Error was encountered: No places found'
      end
    else
      flash[:notice] = 'County not found'
      redirect_back(fallback_location: move_freecen2_places_path) && return

    end
  end

  def new
    get_user_info_from_userid
    permitted = %w[county_coordinator master_county_coordinator country_coordinator system_administrator data_manager validator
                   executive_director project_manager].include?(session[:role]) ? true : false
    redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: 'You are not permitted to create a new place') && return unless permitted

    @place_name = params[:place] if params[:place].present?
    @place = Freecen2Place.new
    @chapman_code = session[:chapman_code]
    @place.alternate_freecen2_place_names.build
    @place.alternate_freecen2_place_names.build
    @place.alternate_freecen2_place_names.build
    @county = session[:county]
    counties_for_select = ChapmanCode.keys
    counties_for_select -= Freecen::UNNEEDED_COUNTIES
    counties_for_select = counties_for_select.delete_if { |cnty| cnty == 'Channel Islands' } # GitHub story 1495
    counties_for_select = counties_for_select.delete_if { |cnty| cnty == 'Overseas British' } # GitHub story 1310 (note: includes #1526 mods too so that there are no conflicts when deployed)
    lnd_county_coord = County.find_by(chapman_code: 'LND')
    counties_for_select << 'London (City)' if %w[system_administrator data_manager].include?(session[:role]) || @user.userid == lnd_county_coord.county_coordinator
    counties_for_select << 'Wales' if %w[system_administrator data_manager].include?(session[:role])
    @counties = counties_for_select.sort
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

  def review_move
    get_user_info_from_userid
    county_from = session[:move_old_county]
    place_from = session[:move_old_place]
    @place_from_rec = Freecen2Place.find_by(chapman_code: county_from, place_name: place_from)
    # @place_from_used_as_pob = Freecen2Place.search_records_birth_places?(@place_from_rec) ? 'Yes' : 'No' - too slow but may improve when indexes created
    county_to = session[:move_new_county]
    place_to = session[:move_new_place]
    @place_to_rec = Freecen2Place.find_by(chapman_code: county_to, place_name: place_to)
    # @place_to_used_as_pob = Freecen2Place.search_records_birth_places?(@place_to_rec) ? 'Yes' : 'No' - too slow but may improve when indexes created
    @place_from_alternates_list = '['
    @place_from_rec.alternate_freecen2_place_names.each do |alt_name|
      @place_from_alternates_list += "#{alt_name.alternate_name}, "
    end
    @place_from_alternates_list = @place_from_alternates_list == '[' ? ' ' : @place_from_alternates_list[0..-3] + ']'

    @place_to_alternates_list = '['
    @place_to_rec.alternate_freecen2_place_names.each do |alt_name|
      @place_to_alternates_list += "#{alt_name.alternate_name}, "
    end
    @place_to_alternates_list = @place_to_alternates_list == '[' ? ' ' : @place_to_alternates_list[0..-3] + ']'

    return unless params[:commit] == 'Move Place Linkages'

    userid = @user.userid
    logger.warn("FREECEN:MOVE_FREECEN2_PLACE_LINKAGES: Starting rake task for #{userid} county #{county_from} place #{place_from}")
    if params[:review_move_fc2_place][:mode] == 'Update'
      pid1 = spawn("bundle exec rake freecen:move_freecen2_place_linkages[#{userid},#{@place_from_rec.id},#{@place_to_rec.id},Y]")
    else
      pid1 = spawn("bundle exec rake freecen:move_freecen2_place_linkages[#{userid},#{@place_from_rec.id},#{@place_to_rec.id},N]")
    end
    logger.warn("FREECEN:MOVE_FREECEN2_PLACE_LINKAGES: rake task for #{pid1}")
    flash[:notice] = "The background task (with Run Mode = #{params[:review_move_fc2_place][:mode]}) for move of linkages for #{place_from} in #{ChapmanCode.name_from_code(county_from)} (#{county_from}) to #{place_to} in #{ChapmanCode.name_from_code(county_to)} (#{county_to}) has been initiated. You will be notified by email when the task has completed."
    return unless params[:review_move_fc2_place][:mode] == 'Update'

    redirect_to freecen2_places_path
  end

  def search_names
    get_counties_for_selection
    get_user_info_from_userid

    if session[:search_names].present? && (params[:clear_form].present? || params[:new_search].present?)
      session[:search_names][:search] = ''
      session[:search_names][:search_county] = ''
      session[:search_names][:advanced_search] = 'not_applicable'
    end

    @place_name = session[:search_names].present? ? session[:search_names][:search] : ''
    @advanced_search = session[:search_names].present? ? session[:search_names][:advanced_search] : 'not_applicable'
    @county = session[:search_names].present? ? session[:search_names][:search_county] : ''

    @freecen2_place = Freecen2Place.new(place_name: @place_name, county: @county)
  end

  def search_names_results
    get_user_info_from_userid
    return redirect_back(fallback_location: search_names_freecen2_place_path, notice: 'No prior search') if session[:search_names].blank?

    search_place = session[:search_names][:search]
    return redirect_back(fallback_location: search_names_freecen2_place_path, notice: 'No prior result search') if search_place.blank?

    search_county = session[:search_names][:search_county]
    @advanced_search = session[:search_names][:advanced_search]
    if @advanced_search.present? && @advanced_search != 'not_applicable'
      redirect_back(fallback_location: search_names_freecen2_place_path, notice: 'Advanced search must contain alphabetic characters only') && return unless search_place.match(/^[A-Za-z ]+$/)
      if @advanced_search != 'soundex'
        redirect_back(fallback_location: search_names_freecen2_place_path, notice: 'Partial searches must contain at least 3 characters') && return unless Freecen2Place.standard_place(search_place).length >= 3
      end
    end
    case @advanced_search
    when 'soundex'
      place_soundex = Text::Soundex.soundex(Freecen2Place.standard_place(search_place))
      @type_head = 'Soundex'
      @results = Freecen2Place.sound_search(place_soundex, search_county)
    when 'starts_with'
      regexp = BSON::Regexp::Raw.new('^' + Freecen2Place.standard_place(search_place))
      @type_head = 'Starts with'
      @results = Freecen2Place.regexp_search(regexp, search_county)
    when 'contains'
      regexp = BSON::Regexp::Raw.new(Freecen2Place.standard_place(search_place))
      @type_head = 'Contains string'
      @results = Freecen2Place.regexp_search(regexp, search_county)
    when 'ends_with'
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

      error_message = @place.check_alternate_names(params[:freecen2_place][:alternate_freecen2_place_names_attributes], @place.chapman_code, params[:id])
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
