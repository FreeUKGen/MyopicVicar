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
class Freereg1CsvEntriesController < ApplicationController
  require 'chapman_code'
  require 'freereg_validations'
  require 'freereg_options_constants'

  skip_before_action :require_login, only: [:show]

  def calculate_software_version
    software_version = SoftwareVersion.control.first
    search_version = ''
    search_version = software_version.last_search_record_version if software_version.present?
    search_version
  end

  def create
    # This deals with a simple entry creation and also the correction of a batch entry error
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Somehow we are missing a vital piece of information. Please have you coordinator contact System Administration with this message') && return if session[:freereg1_csv_file_id].blank?

    get_user_info_from_userid
    @freereg1_csv_file = Freereg1CsvFile.find(session[:freereg1_csv_file_id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The entry was not found. Please have you coordinator contact System Administration with this message') && return if @freereg1_csv_file.blank?

    @freereg1_csv_entry = Freereg1CsvEntry.new(freereg1_csv_entry_params)
    @freereg1_csv_file.check_and_augment_def(params[:freereg1_csv_entry])
    params[:freereg1_csv_entry][:record_type] = @freereg1_csv_file.record_type
    year = @freereg1_csv_entry.get_year(params[:freereg1_csv_entry])
    if session[:error_id].blank?
      file_line_number, line_id = @freereg1_csv_file.augment_record_number_on_creation
    else
      file_line_number, line_id = @freereg1_csv_file.determine_line_information(session[:error_id])
    end
    proceed = @freereg1_csv_entry.update_attributes(freereg1_csv_file_id: session[:freereg1_csv_file_id], register_type: @freereg1_csv_file.register_type, year: year, line_id: line_id, record_type: @freereg1_csv_file.record_type, file_line_number: file_line_number)
    redirect_back(fallback_location: new_manage_resource_path, notice: "The entry update failed #{@freereg1_csv_entry.errors.full_messages}") && return unless proceed

    # need to deal with change in place
    place, church, register = @freereg1_csv_entry.add_additional_location_fields(@freereg1_csv_file)
    @freereg1_csv_file.freereg1_csv_entries << @freereg1_csv_entry
    @freereg1_csv_entry.save
    redirect_back(fallback_location: new_manage_resource_path, notice: "The entry creation failed #{@freereg1_csv_entry.errors.full_messages}") && return if @freereg1_csv_file.errors.any?

    @freereg1_csv_file.calculate_distribution
    search_version = calculate_software_version
    SearchRecord.update_create_search_record(@freereg1_csv_entry, search_version, place)
    @freereg1_csv_file.backup_file
    @freereg1_csv_file.lock_all(session[:my_own])
    @freereg1_csv_file.modification_date = Time.now.strftime("%d %b %Y")
    if session[:error_id].present?
      @freereg1_csv_file.error = @freereg1_csv_file.error - 1
      error = @freereg1_csv_file.batch_errors.find(session[:error_id])
      error.delete
    end
    display_info
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The entry was not correctly linked. Have your coordinator contact the web master') && return if @freereg1_csv_file.blank? ||
      @register.blank? || @church.blank? || @place.blank?

    @freereg1_csv_file.save
    redirect_back(fallback_location: new_manage_resource_path, notice: "The file update after the entry addition failed #{@freereg1_csv_file.errors.full_messages}") && return if @freereg1_csv_file.errors.any?

    register.calculate_register_numbers
    church.calculate_church_numbers
    place.calculate_place_numbers

    session[:error_id] = nil
    flash[:notice] = 'The creation/update in entry contents was successful, a backup of file made and locked'
    redirect_to(freereg1_csv_entry_path(@freereg1_csv_entry)) && return
  end

  def destroy
    @freereg1_csv_entry = Freereg1CsvEntry.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The entry was not found') && return if @freereg1_csv_entry.blank?

    @freereg1_csv_file = @freereg1_csv_entry.freereg1_csv_file
    @freereg1_csv_file.freereg1_csv_entries.delete(@freereg1_csv_entry)
    @freereg1_csv_entry.destroy
    @freereg1_csv_file.update_statistics_and_access(session[:my_own])
    flash[:notice] = 'The deletion of the entry was successful and the files is locked'
    redirect_to freereg1_csv_file_path(@freereg1_csv_file)
  end

  def display_info
    @freereg1_csv_entry.blank? ? @freereg1_csv_file = Freereg1CsvFile.find(session[:freereg1_csv_file_id]) :
      @freereg1_csv_file = @freereg1_csv_entry.freereg1_csv_file
    return if @freereg1_csv_file.blank?

    @freereg1_csv_file_id = @freereg1_csv_file.id
    @freereg1_csv_file_name = @freereg1_csv_file.file_name
    @file_owner = @freereg1_csv_file.userid
    @register = @freereg1_csv_file.register
    return if @register.blank?

    @register_type = @register.register_type
    @register_name = RegisterType.display_name(@register.register_type)
    @church = @register.church
    return if @church.blank?

    @church_name = @church.church_name
    @place = @church.place
    return if @place.blank?

    @county = @place.county
    @chapman_code = @place.chapman_code
    @place_name = @place.place_name
    @user = get_user
    @first_name = @user.person_forename if @user.present?
  end

  def edit
    @freereg1_csv_entry = Freereg1CsvEntry.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The entry was not found') && return if @freereg1_csv_entry.blank?

    display_info
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The entry was not correctly linked. Have your coordinator contact the web master') && return if @freereg1_csv_file.blank? ||
      @register.blank? || @church.blank? || @place.blank?

    session[:freereg1_csv_entry_id] = @freereg1_csv_entry._id
    session[:zero_listing] = true if params[:zero_listing].present?
    @freereg1_csv_entry.multiple_witnesses.build
  end

  def error
    @error_file = BatchError.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The error entry was not found') && return if @error_file.blank?

    set_up_error_display
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The entry was not correctly linked. Have your coordinator contact the web master') && return if @freereg1_csv_file.blank? ||
      @register.blank? || @church.blank? || @place.blank?

    session[:error_id] = params[:id]
  end

  def index
    display_info
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The entry was not correctly linked. Have your coordinator contact the web master') && return if @freereg1_csv_file.blank? ||
      @register.blank? || @church.blank? || @place.blank?

    @freereg1_csv_entries = Freereg1CsvEntry.where(freereg1_csv_file_id: @freereg1_csv_file_id).all.order_by(file_line_number: 1)
  end

  def new
    session[:error_id] = nil
    display_info
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The entry was not correctly linked. Have your coordinator contact the web master') && return if @freereg1_csv_file.blank? ||
      @register.blank? || @church.blank? || @place.blank?

    file_line_number = @freereg1_csv_file.records.to_i + 1
    line_id = @freereg1_csv_file.userid + '.' + @freereg1_csv_file.file_name.upcase + '.' + file_line_number.to_s
    @freereg1_csv_entry = Freereg1CsvEntry.new(record_type: @freereg1_csv_file.record_type, line_id: line_id, file_line_number: file_line_number)
    @freereg1_csv_entry.multiple_witnesses.build
  end

  def set_up_error_display
    @freereg1_csv_file = @error_file.freereg1_csv_file
    return if @freereg1_csv_file.blank?

    @error_file.data_line[:record_type] = @error_file.record_type
    @error_file.data_line.delete(:chapman_code)
    @error_file.data_line.delete(:place_name)
    @freereg1_csv_entry = Freereg1CsvEntry.new(@error_file.data_line)
    @error_line = @error_file.record_number
    @error_message = @error_file.error_message
    @place_names = []
    Place.where(:chapman_code => session[:chapman_code], :disabled.ne => 'true').all.each do |place|
      @place_names << place.place_name
    end
    @freereg1_csv_file_name = @freereg1_csv_file.file_name
    @file_owner = @freereg1_csv_file.userid
    @register = @freereg1_csv_file.register
    return if @register.blank?

    @register_name = RegisterType.display_name(@register.register_type)
    @church = @register.church
    return if @church.blank?

    @church_name = @church.church_name
    @place = @church.place
    return if @place.blank?

    @county = @place.county
    @place_name = @place.place_name
    @user = get_user
    @first_name = @user.person_forename if @user.present?
  end

  def show
    @freereg1_csv_entry = Freereg1CsvEntry.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The entry was not found') && return if @freereg1_csv_entry.blank?

    @get_zero_year_records = 'true' if params[:zero_record]== 'true'
    @zero_year = 'true' if params[:zero_listing] == 'true'
    display_info
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The entry was not correctly linked. Have your coordinator contact the web master') && return if @freereg1_csv_file.blank? ||
      @register.blank? || @church.blank? || @place.blank?

    session[:freereg1_csv_entry_id] = @freereg1_csv_entry._id
    @search_record = @freereg1_csv_entry.search_record
    @forenames = []
    @surnames = []
    @entry = @freereg1_csv_entry
    @image_id = @entry.get_the_image_id(@church, @user, session[:manage_user_origin], session[:image_server_group_id], session[:chapman_code])
    @all_data = true
    record_type = @entry.get_record_type
    @order, @array_of_entries, @json_of_entries = @freereg1_csv_entry.order_fields_for_record_type(record_type, @entry.freereg1_csv_file.def, current_authentication_devise_user.present?)
  end

  def update
    @freereg1_csv_entry = Freereg1CsvEntry.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The entry was not found') && return if @freereg1_csv_entry.blank?

    @freereg1_csv_file = @freereg1_csv_entry.freereg1_csv_file
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The entry had no file. Have your coordinator contact the web master') && return if @freereg1_csv_file.blank?

    params[:freereg1_csv_entry][:record_type] = @freereg1_csv_file.record_type
    @freereg1_csv_file.check_and_augment_def(params[:freereg1_csv_entry])

    params[:freereg1_csv_entry], sex_change = @freereg1_csv_entry.adjust_parameters(params[:freereg1_csv_entry])
    proceed = @freereg1_csv_entry.update_attributes(freereg1_csv_entry_params)
    redirect_back(fallback_location: edit_freereg1_csv_entry_path(@freereg1_csv_entry), notice: "The update of the entry failed #{@freereg1_csv_file.errors.full_messages}.") && return unless proceed

    @freereg1_csv_entry.check_and_correct_county
    @freereg1_csv_entry.check_year
    @freereg1_csv_entry.search_record.destroy if sex_change # updating the search names is too complex on a sex change it is better to just recreate
    @freereg1_csv_entry.search_record(true) if sex_change # this frefreshes the cache
    search_version = calculate_software_version
    place, church, register = get_location_from_file(@freereg1_csv_file)
    SearchRecord.update_create_search_record(@freereg1_csv_entry, search_version, place)
    @freereg1_csv_file.update_statistics_and_access(session[:my_own])
    flash[:notice] = 'The change in entry contents was successful, the file is now locked against replacement until it has been downloaded.'
    if session[:zero_listing]
      session.delete(:zero_listing)
      redirect_to freereg1_csv_entry_path(@freereg1_csv_entry, zero_listing: 'true')
    else
      redirect_to freereg1_csv_entry_path(@freereg1_csv_entry)
    end
  end

  private

  def freereg1_csv_entry_params
    params.require(:freereg1_csv_entry).permit!
  end
end
