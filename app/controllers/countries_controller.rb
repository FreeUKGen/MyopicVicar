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
class CountriesController < ApplicationController
  def create
    params[:country][:country_code] = params[:country][:country_description]
    params[:country][:country_coordinator] = UseridDetail.find(params[:country][:country_coordinator]).userid
    @country = Country.new(country_params)
    @country.save
    if @country.errors.any?
      flash[:notice] = 'The addition of the Country was unsuccessful'
      render action: 'edit'
      return
    else
      flash[:notice] = 'The addition of the Country was successful'
      redirect_to countries_path
    end
  end

  def edit
    load(params[:id])
    redirect_back(fallback_location: countries_path, notice: 'The country was not found') && return if @country.blank?

    @user = get_user
    @first_name = @user.person_forename if @user.present?
    get_userids_and_transcribers
  end

  def index
    @user = get_user
    @first_name = @user.person_forename if @user.present?
    @countries = Country.all.order_by(country_code: 1)
  end

  def load(id)
    @country = Country.find(id)
  end

  def new
    @user = get_user
    @first_name = @user.person_forename if @user.present?
    @country = Country.new
    get_userids_and_transcribers
  end

  def show
    load(params[:id])
    redirect_back(fallback_location: countries_path, notice: 'The country was not found') && return if @country.blank?

    person = UseridDetail.where(userid: @country.country_coordinator).first
    @person = person.person_forename + ' ' + person.person_surname if person.present? && person.person_forename.present?
    person = UseridDetail.where(userid: @country.previous_country_coordinator).first
    @previous_person = person.person_forename + ' ' + person.person_surname if person.present? && person.person_forename.present?
    @user = get_user
    @first_name = @user.person_forename if @user.present?
  end

  def update
    load(params[:id])
    redirect_back(fallback_location: countries_path, notice: 'The country was not found') && return if @country.blank?

    params[:country] = @country.update_fields_before_applying(params[:country])
    @country.update_attributes(country_params)
    redirect_back(fallback_location: edit_countries_path, notice: 'The change to the country was unsuccessful') && return if @country.errors.any?

    flash[:notice] = 'The change to the country was successful'
    redirect_to countries_path
  end

  private

  def country_params
    params.require(:country).permit!
  end
end
