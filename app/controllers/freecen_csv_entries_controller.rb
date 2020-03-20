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
class FreecenCsvEntriesController < ApplicationController
  require 'chapman_code'
  require 'freecen_validations'
  require 'freecen_constants'

  skip_before_action :require_login, only: [:show]

  ActionController::Parameters.permit_all_parameters = true

  def calculate_software_version
    @server = SoftwareVersion.extract_server(Socket.gethostname)
    @application = appname
    software_version = SoftwareVersion.server(@server).app(@application).control.first
    search_version = ''
    search_version = software_version.last_search_record_version if software_version.present?
    search_version
  end

  def create
    # This deals with a simple entry creation and also the correction of a batch entry error
    # The distinction is made by the presence/absence of session[:error_id]
    if session[:freecen_csv_file_id].blank?
      message = 'We are missing a vital piece of information. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    get_user_info_from_userid
    unless FreecenCsvFile.valid_freecen_csv_file?(session[:freecen_csv_file_id])
      flash[:notice] = 'The entry was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    @freecen_csv_file = FreecenCsvFile.find(session[:freecen_csv_file_id])
    @freecen_csv_entry = FreecenCsvEntry.new(freecen_csv_entry_params)
    place, church, register = @freecen_csv_entry.add_additional_location_fields(@freecen_csv_file)

    @freecen_csv_file.check_and_augment_def(params[:freecen_csv_entry])
    params[:freecen_csv_entry][:record_type] = @freecen_csv_file.record_type
    year = @freecen_csv_entry.get_year(params[:freecen_csv_entry], year)
    if session[:error_id].blank?
      file_line_number, line_id = @freecen_csv_file.augment_record_number_on_creation
    else
      file_line_number, line_id = @freecen_csv_file.determine_line_information(session[:error_id])
    end
    proceed = @freecen_csv_entry.update_attributes(freecen_csv_file_id: session[:freecen_csv_file_id],
                                                   register_type: @freecen_csv_file.register_type, year: year,
                                                   line_id: line_id, record_type: @freecen_csv_file.record_type,
                                                   file_line_number: file_line_number, county: place.chapman_code,
                                                   place: place.place_name, church_name: church.church_name)
    unless proceed
      message = "The entry update failed #{@freecen_csv_entry.errors.full_messages}"
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    # need to deal with change in place
    @freecen_csv_file.freereg1_csv_entries << @freecen_csv_entry
    @freecen_csv_entry.save
    if @freecen_csv_file.errors.any?
      message = "The entry creation failed #{@freecen_csv_entry.errors.full_messages}"
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    # We need to update the file statistics and update the search record
    update_file_statistics(place)
    if @freecen_csv_file.errors.any?
      message = "The file update after the entry addition failed #{@freecen_csv_file.errors.full_messages}"
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    # WE update the place, church and register distributions
    @freecen_csv_entry.reload
    old_search_record = nil
    @freecen_csv_entry.update_place_ucf_list(place, @freecen_csv_file, old_search_record)
    update_other_statistics(place, church, register)

    # clean up if  it was a batch error creation
    update_batch_error_file if session[:error_id].present?

    flash[:notice] = 'The creation/update in entry contents was successful, a backup of file made and locked'
    redirect_to(freecen_csv_entry_path(@freecen_csv_entry)) && return
  end

  def destroy
    @freecen_csv_entry = FreecenCsvEntry.find(params[:id]) if params[:id].present?

    unless FreecenCsvEntry.valid_freecen_csv_entry?(@freecen_csv_entry)
      message = 'The entry was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    @freecen_csv_file = @freecen_csv_entry.freecen_csv_file

    redirect_back(fallback_location: new_manage_resource_path, notice: 'File is currently awaiting processing and should not be edited') && return unless @freecen_csv_file.can_we_edit?
    @freecen_csv_entry.clean_up_ucf_list
    @freecen_csv_file.freereg1_csv_entries.delete(@freecen_csv_entry)
    @freecen_csv_entry.destroy
    @freecen_csv_file.update_statistics_and_access(session[:my_own])
    flash[:notice] = 'The deletion of the entry was successful and the batch is locked'
    redirect_to freecen_csv_file_path(@freecen_csv_file)
  end

  def display_info
    @freecen_csv_file = @freecen_csv_entry.blank? ? FreecenCsvFile.find(session[:freecen_csv_file_id]) : @freecen_csv_entry.freecen_csv_file
    @freecen_csv_file_id = @freecen_csv_file.id
    @freecen_csv_file_name = @freecen_csv_file.file_name
    @file_owner = @freecen_csv_file.userid
    @piece = @freecen_csv_file.freecen_piece
    @chapman_code = @piece.chapman_code
    @place_name = @piece.district_name
    @user = get_user
    @first_name = @user.person_forename if @user.present?
  end

  def edit
    @freecen_csv_entry = FreecenCsvEntry.find(params[:id]) if params[:id].present?

    unless FreecenCsvEntry.valid_freecen_csv_entry?(@freecen_csv_entry)
      message = 'The entry was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    @freecen_csv_file = @freecen_csv_entry.freecen_csv_file
    redirect_back(fallback_location: new_manage_resource_path, notice: 'File is currently awaiting processing and should not be edited') && return unless @freecen_csv_file.can_we_edit?
    display_info

    @embargo_permitted = (@user.person_role == 'system_administrator' || @user.person_role == 'executive_director') ? true : false
    @freecen_csv_entry.embargo_records.build if @embargo_permitted
    @date = DateTime.now
    session[:freecen_csv_entry_id] = @freecen_csv_entry._id
    session[:zero_listing] = true if params[:zero_listing].present?
    @freecen_csv_entry.multiple_witnesses.build if @freecen_csv_entry.multiple_witnesses.count < FreeregOptionsConstants::MAXIMUM_WINESSES
  end

  def error
    # This prepares an error file to be edited by the entry edit/create process.
    # The error file was created by the csv file processor
    @error_file = BatchError.find(params[:id]) if params[:id].present?
    if @error_file.blank?
      flash[:notice] = 'The error entry was not found'
      redirect_to(params[:referrer]) && return
    end

    unless FreecenCsvFile.valid_freecen_csv_file?(@error_file.freecen_csv_file_id)
      flash[:notice] = 'The error entry was not correctly linked. Have your coordinator contact the web master'
      redirect_to(params[:referrer]) && return
    end

    @freecen_csv_file = @error_file.freecen_csv_file
    @freecen_csv_entry = FreecenCsvEntry.new(@error_file.data_line)
    session[:error_id] = params[:id]
  end

  def index
    unless FreecenCsvFile.valid_freecen_csv_file?(session[:freecen_csv_file_id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    display_info
    @freecen_csv_entries = FreecenCsvEntry.where(freecen_csv_file_id: @freecen_csv_file_id).all.order_by(file_line_number: 1)
  end

  def new
    session[:error_id] = nil
    unless FreecenCsvFile.valid_freecen_csv_file?(session[:freecen_csv_file_id])
      flash[:notice] = 'The entry was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    display_info
    file_line_number = @freecen_csv_file.records.to_i + 1
    redirect_back(fallback_location: new_manage_resource_path, notice: 'File is currently awaiting processing and should not be edited') && return unless @freecen_csv_file.can_we_edit?

    line_id = @freecen_csv_file.userid + '.' + @freecen_csv_file.file_name.upcase + '.' + file_line_number.to_s
    @freecen_csv_entry = FreecenCsvEntry.new(record_type: @freecen_csv_file.record_type, line_id: line_id, file_line_number: file_line_number)
    @freecen_csv_entry.multiple_witnesses.build
    @freecen_csv_entry.multiple_witnesses.build
  end

  def show
    @freecen_csv_entry = FreecenCsvEntry.find(params[:id]) if params[:id].present?

    unless FreecenCsvEntry.valid_freecen_csv_entry?(@freecen_csv_entry)
      message = 'The entry was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    @get_zero_year_records = 'true' if params[:zero_record] == 'true'
    @zero_year = 'true' if params[:zero_listing] == 'true'
    display_info
    session[:from] = 'file' if params[:from].present? && params[:from] == 'file'
    @embargoed = @freecen_csv_entry.embargo_records.present? ? true : false
    @embargo_permitted = (@user.present? && (@user.person_role == 'system_administrator' || @user.person_role == 'executive_director' || @user.person_role == 'data_manager')) ? true : false
    session[:freecen_csv_entry_id] = @freecen_csv_entry._id
    @search_record = @freecen_csv_entry.search_record
    @forenames = []
    @surnames = []
    @entry = @freecen_csv_entry
    @image_id = @entry.get_the_image_id(@church, @user, session[:manage_user_origin], session[:image_server_group_id], session[:chapman_code])
    @all_data = true
    record_type = @freecen_csv_entry.get_record_type
    @order, @array_of_entries, @json_of_entries = @freecen_csv_entry.order_fields_for_record_type(record_type, @entry.freecen_csv_file.def, current_authentication_devise_user.present?)
  end

  def update
    @freecen_csv_entry = FreecenCsvEntry.find(params[:id]) if params[:id].present?
    unless FreecenCsvEntry.valid_freecen_csv_entry?(@freecen_csv_entry)
      message = 'The entry was incorrectly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    old_search_record = @freecen_csv_entry.search_record
    @freecen_csv_file = @freecen_csv_entry.freecen_csv_file
    params[:freecen_csv_entry][:record_type] = @freecen_csv_file.record_type
    @freecen_csv_file.check_and_augment_def(params[:freecen_csv_entry])

    params[:freecen_csv_entry] = @freecen_csv_entry.adjust_parameters(params[:freecen_csv_entry])
    proceed = @freecen_csv_entry.update_attributes(freecen_csv_entry_params)
    message = @freecen_csv_entry.errors.full_messages + @freecen_csv_entry.embargo_records.last.errors.full_messages unless @freecen_csv_entry.embargo_records.blank?
    redirect_back(fallback_location: edit_freecen_csv_entry_path(@freecen_csv_entry), notice: "The update of the entry failed #{message}.") && return unless proceed

    @freecen_csv_entry.check_and_correct_county
    @freecen_csv_entry.check_year
    search_version = calculate_software_version
    place, _church, _register = get_location_from_file(@freecen_csv_file)
    SearchRecord.update_create_search_record(@freecen_csv_entry, search_version, place)
    @freecen_csv_file.update_statistics_and_access(session[:my_own])
    @freecen_csv_entry.reload
    @freecen_csv_entry.update_place_ucf_list(place, @freecen_csv_file, old_search_record)
    flash[:notice] = 'The change in entry contents was successful, the file is now locked against replacement until it has been downloaded.'
    if session[:zero_listing]
      session.delete(:zero_listing)
      redirect_to freecen_csv_entry_path(@freecen_csv_entry, zero_listing: 'true')
    else
      redirect_to freecen_csv_entry_path(@freecen_csv_entry)
    end
  end

  def update_batch_error_file
    error = @freecen_csv_file.batch_errors.find(session[:error_id])
    error.delete
    session[:error_id] = nil
  end

  def update_file_statistics(place)
    @freecen_csv_file.calculate_distribution
    search_version = calculate_software_version
    SearchRecord.update_create_search_record(@freecen_csv_entry, search_version, place)
    @freecen_csv_file.backup_file
    @freecen_csv_file.lock_all(session[:my_own])
    @freecen_csv_file.modification_date = Time.now.strftime("%d %b %Y")
    @freecen_csv_file.error = @freecen_csv_file.batch_errors.count - 1 if session[:error_id].present?
    @freecen_csv_file.userid_detail_id = @userid
    @freecen_csv_file.save
  end

  def update_other_statistics(place, church, register)
    register.calculate_register_numbers
    church.calculate_church_numbers
    place.calculate_place_numbers
  end

  private

  def freecen_csv_entry_params
    params.require(:freecen_csv_entry).permit!
  end
end
