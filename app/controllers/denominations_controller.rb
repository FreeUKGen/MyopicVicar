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
class DenominationsController < ApplicationController
  def create
    redirect_back(fallback_location: { action: 'index' }, notice: 'You must enter a field ') && return if params[:denomination].blank?

    @denomination = Denomination.new(denomination_params)
    @denomination.save
    redirect_back(fallback_location: { action: 'index' }, notice: "The creation of the new denomination was unsuccessful because #{@denomination.errors.messages}") && return if @denomination.errors.any?
    flash[:notice] = 'The creation of the new denomination was successful'
    redirect_to action: 'index'
  end

  def destroy
    @denomination = Denomination.find(params[:id])
    redirect_back(fallback_location: { action: 'index' }, notice: 'The denomination was not found ') && return if @denomination.blank?

    @denomination.delete
    flash[:notice] = 'The destruction of the denomination was successful'
    redirect_to action: 'index'
  end

  def edit
    @denomination = Denomination.find(params[:id])
    redirect_back(fallback_location: { action: 'index' }, notice: 'The denomination was not found ') && return if @denomination.blank?

    get_user_info_from_userid
    reject_access(@user, 'Denomination') unless session[:role] == 'data_manager' ||
      session[:role] == 'system_administrator' || session[:role] == 'county_coordinator' #|| session[:role] == 'data_manager'
  end

  def index
    get_user_info_from_userid
    @denominations = Denomination.all.order_by(denomination: 1)
  end

  def new
    get_user_info_from_userid
    reject_access(@user, 'Denomination') unless session[:role] == 'data_manager' ||
      session[:role] == 'system_administrator' || session[:role] == 'county_coordinator' #|| session[:role] == 'data_manager'
    @denomination = Denomination.new
  end

  def show
    @denomination = Denomination.find(params[:id])
    redirect_back(fallback_location: { action: 'index' }, notice: 'The denomination was not found ') && return if @denomination.blank?

    get_user_info_from_userid
  end

  def update
    @denomination = Denomination.find(params[:id])
    redirect_back(fallback_location: { action: 'index' }, notice: 'The denomination was not found ') && return if @denomination.blank?

    get_user_info_from_userid
    proceed = @denomination.update_attributes(denomination_params)
    redirect_back(fallback_location: { action: 'index' }, notice: "The denomination update was unsuccessful; #{@denomination.errors.messages}") && return unless proceed

    flash[:notice] = 'The update of the denomination was successful'
    redirect_to action: 'index'
  end

  private

  def denomination_params
    params.require(:denomination).permit!
  end
end
