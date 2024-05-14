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
class CountiesController < ApplicationController
  require 'county'

  def create
    params[:county][:chapman_code] = ChapmanCode.values_at(params[:county][:county_description])
    params[:county][:county_coordinator] = UseridDetail.id(params[:county][:county_coordinator]).first.userid
    county = County.create(county_params)
    if county.errors.any?
      flash[:notice] = 'Activation failed'
      redirect_to(new_county_path) && return
    else
      flash[:notice] = 'Activation successful'
      redirect_to(counties_path) && return
    end
  end

  def display
    get_user_info_from_userid
    @counties = County.application_counties
    @control_access_roles =  ['system_administrator', 'data_manager']
    render action: :index
  end

  def edit
    load(params[:id])
    redirect_back(fallback_location: counties_path, notice: 'The county was not found') && return if @county.blank?

    get_userids_and_transcribers
  end

  def index
    @user = get_user
    @first_name = @user.person_forename if @user.present?
    @counties = County.application_counties
    @control_access_roles =  ['system_administrator', 'data_manager']
  end

  def load(id)
    @county = County.find(id)
  end

  def new
    @user = get_user
    @first_name = @user.person_forename if @user.present?
    @counties = County.inactive_counties
    @county = County.new
    get_userids_and_transcribers
  end

  def selection
    @user = get_user
    @first_name = @user.person_forename if @user.present?
    session[:county] = 'all' if session[:role] == 'system_administrator'
    case params[:county]
    when 'Browse counties'
      @counties = County.application_counties
      render 'index'
      return
    when 'Create county'
      redirect_to action: 'new'
      return
    when 'Edit specific county'
      counties = County.application_counties
      @counties = []
      counties.each do |county|
        @counties << county.chapman_code
      end
      @location = 'location.href= "select?act=edit&county=" + this.value'
    when 'Show specific county'
      counties = County.application_counties
      @counties = []
      counties.each do |county|
        @counties << county.chapman_code
      end
      @location = 'location.href= "select?act=show&county=" + this.value'
    else
      flash[:notice] = 'Invalid option'
      redirect_back(fallback_location: { action: 'show' }) && return
      return
    end
    @prompt = 'Select county'
    params[:county] = nil
    @county = session[:county]
  end

  def select
    @user = get_user
    @first_name = @user.person_forename if @user.present?
    redirect_back(fallback_location: { action: 'show' }, notice: 'Blank cannot be selected') && return if params[:county].blank?

    county = County.where(chapman_code: params[:county]).first
    redirect_back(fallback_location: { action: 'show' }, notice: 'Invalid county selected') && return if county.blank?

    if params[:act] == 'show'
      redirect_to county_path(county)
    else
      redirect_to edit_county_path(county)
    end
  end

  def show
    load(params[:id])
    redirect_back(fallback_location: counties_path, notice: 'The county was not found') && return if @county.blank?

    person = UseridDetail.userid(@county.county_coordinator).first
    @person = person.person_forename + ' ' + person.person_surname if person.present? && person.person_forename.present?
    person = UseridDetail.userid(@county.previous_county_coordinator).first
    @previous_person = person.person_forename + ' ' + person.person_surname if person.present? && person.person_forename.present?
    @user = get_user
    @first_name = @user.person_forename if @user.present?
  end

  def update
    load(params[:id])
    redirect_back(fallback_location: counties_path, notice: 'The county was not found') && return if @county.blank?

    params[:county] = @county.update_fields_before_applying(params[:county])
    @county.update_attributes(county_params)
    redirect_back(fallback_location: edit_counties_path, notice: 'The change to the county was unsuccessful') && return if @county.errors.any?

    flash[:notice] = 'The change to the county was successful'
    redirect_to counties_path
  end

  private

  def county_params
    params.require(:county).permit!
  end
end
