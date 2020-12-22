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
    @first_name = @user.person_forename if @user.present?
    if params[:commit] == 'Search Place Names'
      session[:search_names] = {}
      session[:search_names][:search] = params[:freecen2_place][:place_name]
      session[:search_names][:search_county] = params[:freecen2_place][:county]
      redirect_to search_names_results_freecen2_place_path
    else
      params[:freecen2_place][:chapman_code] = ChapmanCode.values_at(params[:freecen2_place][:county])
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

    if @place.data_present
      flash[:notice] = 'You must use the rename action as there are search records using this current place name'
      redirect_to(freecen2_place_path(@place)) && return
    else
      @place_name = @place.place_name
      @place.alternate_freecen2_place_names.build
      @place.alternate_freecen2_place_names.build
      @place.alternate_freecen2_place_names.build
      @county = session[:county]
      @chapman_code = session[:chapman_code]
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
    @place_name = params[:place] if params[:place].present?
    @place = Freecen2Place.new
    @chapman_code = session[:chapman_code]
    get_user_info_from_userid
    @place.alternate_freecen2_place_names.build
    @place.alternate_freecen2_place_names.build
    @place.alternate_freecen2_place_names.build
    @county = session[:county]
    @counties = ChapmanCode.keys.sort
    @counties -= Freecen::UNNEEDED_COUNTIES
  end

  def places_counties_and_countries
    @countries = []
    Country.all.order_by(country_code: 1).each do |country|
      @countries << country.country_code
    end
    @counties = ChapmanCode.keys.sort
    @counties -= Freecen::UNNEEDED_COUNTIES
    placenames = Freecen2Place.where(:chapman_code => session[:chapman_code], :disabled => 'false', :error_flag.ne => "Place name is not approved").all.order_by(place_name: 1)
    @placenames = []
    placenames.each do |placename|
      @placenames << placename.place_name
    end
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
    @freecen2_place = Freecen2Place.new
    get_user_info_from_userid
    session.delete(:search_names) if session[:search_names].present?
    session[:search_names] = []
  end

  def search_names_results
    get_user_info_from_userid
    @results = Freecen2Place.search(session[:search_names][:search], session[:search_names][:search_county])
    @county = session[:search_names][:search_county].present? ? session[:search_names][:search_county] : 'All Counties'
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

  def update
    load(params[:id])
    redirect_back(fallback_location: select_action_manage_counties_path(@county), notice: 'That place does not exist') && return if @place.blank?

    case
    when params[:commit] == 'Submit'
      @place.save_to_original

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
