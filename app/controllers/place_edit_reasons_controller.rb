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
class PlaceEditReasonsController < ApplicationController
  def create
    redirect_back(fallback_location: { action: 'index' }, notice: 'You must enter a field ') && return if params[:place_edit_reason].blank?

    @reason = PlaceEditReason.new(place_edit_reason_params)
    @reason.save
    redirect_back(fallback_location: { action: 'index' }, notice: "The creation of the new reason was unsuccessful because #{@reason.errors.messages}") && return if @reason.errors.any?
    flash[:notice] = 'The creation of the new reason was successful'
    redirect_to action: 'index'
  end

  def destroy
    @reason = PlaceEditReason.find(params[:id])
    redirect_back(fallback_location: { action: 'index' }, notice: 'The reason was not found ') && return if @reason.blank?

    @reason.delete
    flash[:notice] = 'The destruction of the reason was successful'
    redirect_to action: 'index'
  end

  def edit
    @reason = PlaceEditReason.find(params[:id])
    redirect_back(fallback_location: { action: 'index' }, notice: 'The reason was not found ') && return if @reason.blank?

    get_user_info_from_userid
    reject_access(@user, 'Reason') unless session[:role] == 'data_manager' ||
      session[:role] == 'system_administrator' || session[:role] == 'county_coordinator' || session[:role] == 'data_manager'
  end

  def index
    get_user_info_from_userid
    @reasons = PlaceEditReason.all.order_by(reason: 1)
  end

  def new
    get_user_info_from_userid
    reject_access(@user, 'Reason') unless session[:role] == 'data_manager' ||
      session[:role] == 'system_administrator' || session[:role] == 'county_coordinator' || session[:role] == 'data_manager'
    @reason = PlaceEditReason.new
  end

  def show
    @reason = PlaceEditReason.find(params[:id])
    redirect_back(fallback_location: { action: 'index' }, notice: 'The reason was not found ') && return if @reason.blank?

    get_user_info_from_userid
  end

  def update
    @reason = PlaceEditReason.find(params[:id])
    redirect_back(fallback_location: { action: 'index' }, notice: 'The reason was not found ') && return if @reason.blank?

    get_user_info_from_userid
    proceed = @reason.update_attributes(place_edit_reason_params)
    redirect_back(fallback_location: { action: 'index' }, notice: "The reason update was unsuccessful; #{@reason.errors.messages}") && return unless proceed

    flash[:notice] = 'The update of the reason was successful'
    redirect_to action: 'index'
  end

  private

  def place_edit_reason_params
    params.require(:place_edit_reason).permit!
  end
end
