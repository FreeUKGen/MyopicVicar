class AliasPlaceChurchesController < ApplicationController
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
  require 'chapman_code'
  require 'place'

  def create
    case
    when params[:commit] == "Search"
      redirect_to alias_place_churches_path(params)

    when params[:commit] == "Select Place"
      place = params[:alias_place_church][:place_name]
      session[:place] =  place
      session[:edit] = "new church"
      redirect_to new_alias_place_church_path

    when params[:commit] == "Select Church"
      church = params[:alias_place_church][:church_name]
      session[:church] =  church
      session[:edit] = "edit"
      redirect_to new_alias_place_church_path

    else
      @alias_place_church = AliasPlaceChurch.new if session[:edit] = "new"
      @alias_place_church.chapman_code = session[:chapman_code]
      @alias_place_church.place_name = session[:place]
      @alias_place_church.church_name = session[:church]
      @alias_place_church.alternate_church_name = params[:alias_place_church][:alternate_church_name]
      @alias_place_church.alternate_place_name = params[:alias_place_church][:alternate_place_name]
      @alias_place_church.alias_notes = params[:alias_place_church][:alias_notes]
      @alias_place_church.save!

      flash[:notice] = 'The addition of the Alias document was successful'
      redirect_to alias_place_church_path(@alias_place_church)
    end
  end

  def destroy
    load(params[:id])
    @alias_place_church.destroy
    redirect_to alias_place_churches_path
  end

  def edit
    load(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Attempting to edit an incomplete entry') && return if @alias_place_church.blank?

    session[:edit] = 'edit'
    @county = session[:county]
  end

  def index
    unless params[:commit] == 'Search'
      reset_session
      @alias_place_church = AliasPlaceChurch.new
    else
      @alias_place_church = AliasPlaceChurch.where(chapman_code: params[:alias_place_church][:chapman_code]).all.order_by(place_name: 1)

      @county = ChapmanCode.has_key(params[:alias_place_church][:chapman_code])
      @chapman_code = params[:alias_place_church][:chapman_code]
      @place = Place.where(chapman_code: @chapman_code).all.order_by(place_name: 1)
      session[:chapman_code] = @chapman_code
      session[:county] = @county
      session[:edit] = 'new place'
    end
  end

  def load(alias_place_church_id)
    @alias_place_church = AliasPlaceChurch.find(alias_place_church_id)
    return if @alias_place_church.blank?

    session[:alias_place_church_id] = @alias_place_church_id
    @alias_place_church_church_name = @alias_place_church.church_name
    session[:church_name] = @alias_place_church_church_name
    @alias_place_church_place_name = @alias_place_church_place_name
    session[:place] = @alias_place_church_place_name
    @alias_place_church_county = session[:county]
  end

  def new
    case session[:edit]
    when 'new place'
      @alias_place_church = AliasPlaceChurch.new
      @chapman_code = session[:chapman_code]
      @place_names = Array.new
      @county = session[:county]
      @place = Place.where(chapman_code: @chapman_code).all.order_by(place_name: 1)
      session[:form] = @alias_place_church
      @place.each do |place|
        @place_names << place.place_name
      end

    when 'new church'
      @county = session[:county]
      @place = session[:place]
      place = Place.find_by(place_name: @place)
      redirect_back(fallback_location: new_manage_resource_path, notice: 'Attempting to create an incomplete entry') && return if place.blank?

      @church_names = []
      @church_ids = place.church_ids
      @church_ids.each do |my_church|
        church = Church.find(my_church)
        redirect_back(fallback_location: new_manage_resource_path, notice: 'Attempting to create an incomplete entry') && return if church.blank?

        @church_names << church.church_name
      end
      @alias_place_church = session[:form]

      @alias_place_church.place_name = session[:place]

    when 'edit'
      @alias_place_church =  session[:form]
      @alias_place_church.place_name = session[:place]
      @alias_place_church.church_name = session[:church]
    end
  end

  def show
    load(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Attempting to show an incomplete entry') && return if @alias_place_church.blank?

  end

  def update
    load(params[:id])
    @alias_place_church.alternate_church_name = params[:alias_place_church][:alternate_church_name]
    @alias_place_church.alternate_place_name = params[:alias_place_church][:alternate_place_name]
    @alias_place_church.alias_notes = params[:alias_place_church][:alias_notes]
    @alias_place_church.save!
    flash[:notice] = 'The change in the Alias document was successful'
    redirect_to alias_place_church_path(@alias_place_church)
  end
end
