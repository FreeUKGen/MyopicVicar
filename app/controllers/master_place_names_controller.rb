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
class MasterPlaceNamesController < ActionController::Base

  def index
    if session[:userid].blank?
      redirect_to '/', notice: 'You are not authorized to use these facilities'
    end
    @chapman_code = session[:chapman_code]
    @county = session[:county]
    @first_name = session[:first_name]

    @places = MasterPlaceName.where(chapman_code: @chapman_code).all.order_by(place_name: 1)
  end

  def show
    load(params[:id])
    @first_name = session[:first_name]
  end

  def edit
    load(params[:id])
    session[:type] = 'edit'
    @first_name = session[:first_name]
  end

  def create
    @place = MasterPlaceName.new

    @place.place_name = params[:master_place_name][:place_name]
    @place.genuki_url = params[:master_place_name][:genuki_url] if params[:master_place_name][:genuki_url].present?
    @place.chapman_code = params[:master_place_name][:chapman_code]
    @place.county = ChapmanCode.has_key(params[:master_place_name][:chapman_code])
    @place.country = params[:master_place_name][:country]
    @place.place_name = params[:master_place_name][:place_name]
    @place.modified_place_name = @place.place_name.gsub(/-/, ' ').gsub(/\./, '').gsub(/\'/, '').downcase
    @place.grid_reference = params[:master_place_name][:grid_reference]
    @place.latitude = params[:master_place_name][:latitude]
    @place.longitude = params[:master_place_name][:longitude]

    #use the lat/lon if present if not calculate from the grid reference
    if @place.latitude.blank? || @place.longitude.blank? || @place.latitude.empty? || @place.longitude.empty? then
      unless (@place.grid_reference.blank? || !@place.grid_reference.is_gridref?)
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
      flash[:notice] = 'The addition to Master Place Name was unsuccessful'
      render :new
    else
      flash[:notice] = 'The addition to Master Place Name was successful'
      redirect_to master_place_name_path(@place)
    end
  end

  def update
    load(params[:id])
    # save place name change in Master Place Name
    @place.genuki_url = params[:master_place_name][:genuki_url] unless params[:master_place_name][:genuki_url].blank?
    #save the original entry we had
    @place.original_chapman_code = session[:chapman_code] unless !@place.original_chapman_code.blank?
    @place.original_county = session[:county] unless !@place.original_county.blank?
    @place.original_country = @place.country unless params[:master_place_name][:country].blank? || !@place.original_country.blank?
    @place.original_place_name = @place.place_name unless params[:master_place_name][:place_name].blank? || !@place.original_place_name.blank?
    @place.original_grid_reference = @place.grid_reference unless params[:master_place_name][:grid_reference].blank? || !@place.original_grid_reference.blank?
    @place.original_latitude = @place.latitude unless params[:master_place_name][:latitude].blank? || !@place.original_latitude.blank?
    @place.original_longitude = @place.longitude unless params[:master_place_name][:longitude].blank? || !@place.original_longitude.blank?
    @place.original_source =  @place.source unless params[:master_place_name][:source].blank? || !@place.original_source.blank?
    @place.reason_for_change = params[:master_place_name][:reason_for_change]
    @place.county = session[:county]
    @place.country = params[:master_place_name][:country]
    @place.place_name = params[:master_place_name][:place_name]
    @place.modified_place_name = @place.place_name.gsub(/-/, ' ').gsub(/\./, '').gsub(/\'/, '').downcase
    @place.grid_reference = params[:master_place_name][:grid_reference]
    @place.latitude = params[:master_place_name][:latitude]
    @place.longitude = params[:master_place_name][:longitude]
    #use the lat/lon if present if not calculate from the grid reference
    if @place.latitude.blank? || @place.longitude.blank? || @place.latitude.empty? || @place.longitude.empty? then
      unless (@place.grid_reference.blank? || !@place.grid_reference.is_gridref?) then
        location = @place.grid_reference.to_latlng.to_a if @place.grid_reference.is_gridref?
        @place.latitude = location[0]
        @place.longitude = location[1]
      end
    else
      #have they changed?
      if @place.original_latitude == @place.latitude && @place.original_longitude == @place.longitude
        #yes they have not changed so use Grid ref
        unless (@place.grid_reference.blank? || !@place.grid_reference.is_gridref?) then
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
      flash[:notice] = 'The change in Master Place Name record was unsuccessful'
      render :edit
    else
      session[:form] = nil
      flash[:notice] = 'The change in Master Place Name record was successful'
      redirect_to :action => 'show'
    end
  end

  def new

    @place = MasterPlaceName.new
    @place.chapman_code = session[:chapman_code]
    @place.county = session[:county]

    @first_name = session[:first_name]
    @county = session[:county]
    session[:type] = 'new'
  end

  def destroy
    load(params[:id])
    @place.disabled = 'true'
    @place.save


    flash[:notice] = 'The discard of the Master Place Name record was successful'
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
end
