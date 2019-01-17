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
class ChurchesController < ApplicationController
  rescue_from Mongoid::Errors::DeleteRestriction, with: :record_cannot_be_deleted
  rescue_from Mongoid::Errors::Validations, with: :record_validation_errors

  require 'chapman_code'

  def new
    @church = Church.new
    @county = session[:county]
    @place = Place.find(session[:place_id])
    @place_name = @place.place_name
    @user = get_user
    @first_name = @user.person_forename if @user.present?
    @church.alternatechurchnames.build
    denomination_list
  end

  def create
    @church = Church.new(church_params)
    @church.church_name = Church.standardize_church_name(@church.church_name)
    @place = Place.find(session[:place_id])
    proceed, message = @church.church_does_not_exist(@place)
    if proceed
      @place.churches << @church
      flash[:notice] = 'The addition of the Church was successful'
      redirect_to(church_path(@church)) && return
    else
      get_user_info_from_userid
      flash[:notice] = "The addition of the Church was unsuccessful because #{message}"
      redirect_to(new_church_path) && return
    end
  end

  def denomination_list
    @denominations = []
    Denomination.all.order_by(denomination: 1).each do |denomination|
      @denominations << denomination.denomination
    end
  end

  def destroy
    @church = Church.id(params[:id]).first
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Your church was not found') && return if @church.blank?

    return_place = @church.place
    @church.destroy
    flash[:notice] = 'The deletion of the Church was successful'
    redirect_to place_path(return_place)
  end

  def edit
    @church = Church.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Your church was not found') && return if @church.blank?

    setup
    @church.alternatechurchnames.build
    denomination_list
  end

  def merge
    @church = Church.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Your church was not found') && return if @church.blank?

    setup
    proceed, message = @church.merge_churches
    if proceed
      flash[:notice] = 'The merge of the Church was successful'
      redirect_to(church_path(@church)) && return
    else
      redirect_back(fallback_location: new_manage_resource_path, notice: "Church Merge unsuccessful; #{message}") && return if @church.blank?

    end
  end

  def record_cannot_be_deleted
    flash[:notice] = 'The deletion of the Church was unsuccessful because there were dependent documents; please delete them first'
    flash.keep
    redirect_to action: 'show'
  end

  def record_validation_errors
    flash[:notice] = 'The update of the children to Church with a church name change failed'
    flash.keep
    redirect_to action: 'show'
  end

  def relocate
    @church = Church.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Your church was not found') && return if @church.blank?

    setup
    @chapman_code = session[:chapman_code]
    place = Place.where(chapman_code: ChapmanCode.values_at(@county), :disabled.ne => 'true').all.order_by(place_name: 1)
    @places = []
    place.each do |my_place|
      @places << my_place.place_name
    end
    @records = @church.records
    max_records = get_max_records(@user)
    flash[:notice] = 'There are too many records for an on-line relocation' if @records.present? && @records.to_i >= max_records
    redirect_to(action: 'show') && return if @records.present? && @records.to_i >= max_records
  end

  def rename
    @church = Church.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Your church was not found') && return if @church.blank?

    setup
    @records = @church.records
    max_records = get_max_records(@user)
    flash[:notice] = 'There are too many records for an on-line relocation' if @records.present? && @records.to_i >= max_records
    redirect_to(action: 'show') && return if @records.present? && @records.to_i >= max_records
  end

  def setup
    session[:church_id] = @church._id
    @church_name = @church.church_name
    session[:church_name] = @church_name
    @place_id = @church.place
    session[:place_id] = @place_id._id
    @place = Place.find(@place_id)
    @place_name = @place.place_name
    session[:place_name] =  @place_name
    @county = ChapmanCode.has_key(@place.chapman_code)
    session[:county] = @county
    @user = get_user
    @first_name = @user.person_forename if @user.present?
  end

  def show
    @church = Church.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Your church was not found') && return if @church.blank?

    setup
    @decade = @church.daterange
    @transcribers = @church.transcribers
    @contributors = @church.contributors
  end

  def update
    @church = Church.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Your church was not found') && return if @church.blank?

    setup
    params[:church][:church_name] = params[:church][:church_name].strip if params[:church][:church_name].present?
    case
    when params[:commit] == 'Submit'
      @church.update_attributes(church_params)
      redirect_back(fallback_location: edit_manage_resource_path, notice: 'The update of the Church was unsuccessful') && return if @church.errors.any?

    when params[:commit] == 'Rename'
      proceed, message = @church.change_name(params[:church])
      redirect_back(fallback_location: rename_church_path, notice: "The rename of the Church was unsuccessful; #{message}") && return unless proceed

    when params[:commit] == 'Relocate'
      proceed, message = @church.relocate_church(params[:church])
      redirect_back(fallback_location: relocate_church_path, notice: "The relocation of the Church was unsuccessful; #{message}") && return unless proceed

    else
      # we should never get here but just in case
      flash[:notice] = 'The change to the Church was unsuccessful'
      redirect_to(church_path(@church)) && return

    end
    flash[:notice] = 'The update the Church was successful'
    redirect_to(church_path(@church)) && return
  end

  private

  def church_params
    params.require(:church).permit!
  end
end
