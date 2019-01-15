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
    if params[:denomination].blank?
      flash[:notice] = 'You must enter a field '
      redirect_back fallback_location: { action: "index" } and return
    end
    @denomination  = Denomination.new(denomination_params)
    @denomination.save
    if @denomination.errors.any?
      flash[:notice] = "The creation of the new denomination was unsuccessful because #{@denomination.errors.messages}"
      get_userids_and_transcribers
      redirect_back fallback_location: { action: "index" } and return
    end #errors
    flash[:notice] = 'The creation of the new denomination was successful'
    redirect_to :action => 'index'
    return
  end

  def destroy
    @denomination = Denomination.id(params[:id]).first
    if @denomination.blank?
      redirect_back fallback_location: { action: "index" } and return
    else
      @denomination.delete
      flash[:notice] = 'The destruction of the denomination was successful'
      redirect_to :action => 'index'
      return
    end
  end

  def edit
    get_user_info_from_userid
    reject_access(@user,"Denomination") unless @user.person_role == 'data_manager' || @user.person_role == 'system_administrator'
    @denomination = Denomination.id(params[:id]).first
    if @denomination.blank?
      redirect_back fallback_location: { action: "index" } and return
    end
  end

  def index
    get_user_info_from_userid
    @denominations = Denomination.all.order_by(denomination: 1)
  end

  def new
    get_user_info_from_userid
    reject_access(@user,"Denomination") unless @user.person_role == 'data_manager' || @user.person_role == 'system_administrator'
    @denomination = Denomination.new
  end
  def show
    get_user_info_from_userid
    @denomination = Denomination.id(params[:id]).first
    if @denomination.blank?
      redirect_back fallback_location: { action: "index" } and return
    end
  end

  def update
    get_user_info_from_userid
    @denomination = Denomination.id(params[:id]).first
    if @denomination.blank?
      flash[:notice] = 'The entry did not exist'
      redirect_back fallback_location: "/manage_resources/new" and return
    end
    @denomination.update_attributes(denomination_params )
    flash[:notice] = 'The creation of the new denomination was successful'
    redirect_to :action => 'index'
    return
  end

  private
  def denomination_params
    params.require(:denomination).permit!
  end

end
