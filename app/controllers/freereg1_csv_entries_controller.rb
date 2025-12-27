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
    if session[:freereg1_csv_file_id].blank?
      message = 'We are missing a vital piece of information. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    get_user_info_from_userid
    unless Freereg1CsvFile.valid_freereg1_csv_file?(session[:freereg1_csv_file_id])
      flash[:notice] = 'The entry was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    @freereg1_csv_file = Freereg1CsvFile.find(session[:freereg1_csv_file_id])
    @freereg1_csv_entry = Freereg1CsvEntry.new(freereg1_csv_entry_params)
    place, church, register = @freereg1_csv_entry.add_additional_location_fields(@freereg1_csv_file)

    @freereg1_csv_file.check_and_augment_def(params[:freereg1_csv_entry])
    params[:freereg1_csv_entry][:record_type] = @freereg1_csv_file.record_type
    year = @freereg1_csv_entry.get_year(params[:freereg1_csv_entry], year)
    if session[:error_id].blank?
      file_line_number, line_id = @freereg1_csv_file.augment_record_number_on_creation
    else
      file_line_number, line_id = @freereg1_csv_file.determine_line_information(session[:error_id])
    end
    proceed = @freereg1_csv_entry.update_attributes(freereg1_csv_file_id: session[:freereg1_csv_file_id],
                                                    register_type: @freereg1_csv_file.register_type, year: year,
                                                    line_id: line_id, record_type: @freereg1_csv_file.record_type,
                                                    file_line_number: file_line_number, county: place.chapman_code,
                                                    place: place.place_name, church_name: church.church_name)
    unless proceed
      message = "The entry update failed #{@freereg1_csv_entry.errors.full_messages}"
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    # need to deal with change in place
    @freereg1_csv_file.freereg1_csv_entries << @freereg1_csv_entry
    @freereg1_csv_entry.save
    if @freereg1_csv_file.errors.any?
      message = "The entry creation failed #{@freereg1_csv_entry.errors.full_messages}"
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    # We need to update the file statistics and update the search record
    update_file_statistics(place)
    if @freereg1_csv_file.errors.any?
      message = "The file update after the entry addition failed #{@freereg1_csv_file.errors.full_messages}"
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    # WE update the place, church and register distributions
    @freereg1_csv_entry.reload
    old_search_record = nil
    @freereg1_csv_entry.update_place_ucf_list(place, @freereg1_csv_file, old_search_record)
    update_other_statistics(place, church, register)

    # clean up if  it was a batch error creation
    update_batch_error_file if session[:error_id].present?

    flash[:notice] = 'The creation/update in entry contents was successful, a backup of file made and locked'
    redirect_to(freereg1_csv_entry_path(@freereg1_csv_entry)) && return
  end

  def destroy
    @freereg1_csv_entry = Freereg1CsvEntry.find(params[:id]) if params[:id].present?

    unless Freereg1CsvEntry.valid_freereg1_csv_entry?(@freereg1_csv_entry)
      message = 'The entry was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    @freereg1_csv_file = @freereg1_csv_entry.freereg1_csv_file

    redirect_back(fallback_location: new_manage_resource_path, notice: 'File is currently awaiting processing and should not be edited') && return unless @freereg1_csv_file.can_we_edit?
    @freereg1_csv_entry.clean_up_ucf_list
    @freereg1_csv_entry.destroy
    @freereg1_csv_file.update_statistics_and_access(session[:my_own])
    flash[:notice] = 'The deletion of the entry was successful and the batch is locked'
    redirect_to freereg1_csv_file_path(@freereg1_csv_file)
  end

  def display_info
    @freereg1_csv_file = @freereg1_csv_entry.blank? ? Freereg1CsvFile.find(session[:freereg1_csv_file_id]) : @freereg1_csv_entry.freereg1_csv_file
    @freereg1_csv_file_id = @freereg1_csv_file.id
    @freereg1_csv_file_name = @freereg1_csv_file.file_name
    @file_owner = @freereg1_csv_file.userid
    @register = @freereg1_csv_file.register
    @register_type = @register.register_type
    @register_name = RegisterType.display_name(@register.register_type)
    @church = @register.church
    @church_name = @church.church_name
    @place = @church.place
    @county = @place.county
    @chapman_code = @place.chapman_code
    @place_name = @place.place_name
    @user = get_user
    @first_name = @user.person_forename if @user.present?
  end

  def edit
    @freereg1_csv_entry = Freereg1CsvEntry.find(params[:id]) if params[:id].present?

    unless Freereg1CsvEntry.valid_freereg1_csv_entry?(@freereg1_csv_entry)
      message = 'The entry was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    @freereg1_csv_file = @freereg1_csv_entry.freereg1_csv_file
    redirect_back(fallback_location: new_manage_resource_path, notice: 'File is currently awaiting processing and should not be edited') && return unless @freereg1_csv_file.can_we_edit?
    display_info

    @embargo_permitted = (session[:role] == 'system_administrator' || session[:role] == 'executive_director') ? true : false
    @freereg1_csv_entry.embargo_records.build if @embargo_permitted
    @date = DateTime.now
    session[:freereg1_csv_entry_id] = @freereg1_csv_entry._id
    session[:zero_listing] = true if params[:zero_listing].present?
    @freereg1_csv_entry.multiple_witnesses.build if @freereg1_csv_entry.multiple_witnesses.count < FreeregOptionsConstants::MAXIMUM_WINESSES
  end

  def edit_embargo
    @freereg1_csv_entry = Freereg1CsvEntry.find(params[:id]) if params[:id].present?

    unless Freereg1CsvEntry.valid_freereg1_csv_entry?(@freereg1_csv_entry)
      message = 'The entry was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    @freereg1_csv_file = @freereg1_csv_entry.freereg1_csv_file
    redirect_back(fallback_location: new_manage_resource_path, notice: 'File is currently awaiting processing and should not be edited') && return unless @freereg1_csv_file.can_we_edit?

    display_info

    @embargo_permitted = (session[:role] == 'system_administrator' || session[:role] == 'executive_director') ? true : false
    @freereg1_csv_entry.embargo_records.build if @embargo_permitted
    @date = DateTime.now
    session[:freereg1_csv_entry_id] = @freereg1_csv_entry._id
    session[:zero_listing] = true if params[:zero_listing].present?
  end

  def error
    # This prepares an error file to be edited by the entry edit/create process.
    # The error file was created by the csv file processor
    @error_file = BatchError.find(params[:id]) if params[:id].present?
    @error = true
    if @error_file.blank?
      flash[:notice] = 'The error entry was not found'
      redirect_to(params[:referrer]) && return
    end

    unless Freereg1CsvFile.valid_freereg1_csv_file?(@error_file.freereg1_csv_file_id)
      flash[:notice] = 'The error entry was not correctly linked. Have your coordinator contact the web master'
      redirect_to(params[:referrer]) && return
    end

    @freereg1_csv_file = @error_file.freereg1_csv_file
    entry = Freereg1CsvEntry.new(@error_file.data_line)
    data_record = @error_file.data_line
    if data_record[:record_type] == "ma" || data_record[:record_type] == "ba"
      entry.multiple_witnesses << MultipleWitness.new(:witness_forename => data_record[:witness1_forename],:witness_surname => data_record[:witness1_surname]) unless data_record[:witness1_forename].blank? && data_record[:witness1_surname].blank?
      entry.multiple_witnesses << MultipleWitness.new(:witness_forename => data_record[:witness2_forename],:witness_surname => data_record[:witness2_surname]) unless data_record[:witness2_forename].blank? && data_record[:witness2_surname].blank?
      entry.multiple_witnesses << MultipleWitness.new(:witness_forename => data_record[:witness3_forename], :witness_surname => data_record[:witness3_surname]) unless data_record[:witness3_forename].blank? &&  data_record[:witness3_surname].blank?
      entry.multiple_witnesses << MultipleWitness.new(:witness_forename => data_record[:witness4_forename], :witness_surname => data_record[:witness4_surname]) unless data_record[:witness4_forename].blank? &&  data_record[:witness4_surname].blank?
      entry.multiple_witnesses << MultipleWitness.new(:witness_forename => data_record[:witness5_forename], :witness_surname => data_record[:witness5_surname]) unless data_record[:witness5_forename].blank? &&  data_record[:witness5_surname].blank?
      entry.multiple_witnesses << MultipleWitness.new(:witness_forename => data_record[:witness6_forename], :witness_surname => data_record[:witness6_surname]) unless data_record[:witness6_forename].blank? &&  data_record[:witness6_surname].blank?
      entry.multiple_witnesses << MultipleWitness.new(:witness_forename => data_record[:witness7_forename], :witness_surname => data_record[:witness7_surname]) unless data_record[:witness7_forename].blank? &&  data_record[:witness7_surname].blank?
      entry.multiple_witnesses << MultipleWitness.new(:witness_forename => data_record[:witness8_forename], :witness_surname => data_record[:witness8_surname]) unless data_record[:witness8_forename].blank? &&  data_record[:witness8_surname].blank?
    end
    entry.multiple_witnesses.each do |witness|
      witness.witness_surname = witness.witness_surname.upcase if witness.witness_surname.present?
    end
    @freereg1_csv_entry = entry
    session[:error_id] = params[:id]
  end

  def index
    unless Freereg1CsvFile.valid_freereg1_csv_file?(session[:freereg1_csv_file_id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    display_info
    @freereg1_csv_entries = Freereg1CsvEntry.where(freereg1_csv_file_id: @freereg1_csv_file_id).all.order_by(file_line_number: 1)
  end

  def new
    session[:error_id] = nil
    unless Freereg1CsvFile.valid_freereg1_csv_file?(session[:freereg1_csv_file_id])
      flash[:notice] = 'The entry was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    display_info
    file_line_number = @freereg1_csv_file.records.to_i + 1
    redirect_back(fallback_location: new_manage_resource_path, notice: 'File is currently awaiting processing and should not be edited') && return unless @freereg1_csv_file.can_we_edit?

    line_id = @freereg1_csv_file.userid + '.' + @freereg1_csv_file.file_name.upcase + '.' + file_line_number.to_s
    @freereg1_csv_entry = Freereg1CsvEntry.new(record_type: @freereg1_csv_file.record_type, line_id: line_id, file_line_number: file_line_number)
    @freereg1_csv_entry.multiple_witnesses.build
    @freereg1_csv_entry.multiple_witnesses.build
  end

  def show
    @freereg1_csv_entry = Freereg1CsvEntry.find(params[:id]) if params[:id].present?

    unless Freereg1CsvEntry.valid_freereg1_csv_entry?(@freereg1_csv_entry)
      message = 'The entry was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    @get_zero_year_records = 'true' if params[:zero_record] == 'true'
    @zero_year = 'true' if params[:zero_listing] == 'true'
    display_info
    session[:from] = 'file' if params[:from].present? && params[:from] == 'file'
    @embargoed = @freereg1_csv_entry.embargo_records.present? ? true : false
    @embargo_permitted = (@user.present? && (session[:role] == 'system_administrator' || session[:role] == 'executive_director' || session[:role] == 'data_manager')) ? true : false
    session[:freereg1_csv_entry_id] = @freereg1_csv_entry._id
    @search_record = @freereg1_csv_entry.search_record
    @forenames = []
    @surnames = []
    @entry = @freereg1_csv_entry
    @image_id = @entry.get_the_image_id(@church, @user, session[:manage_user_origin], session[:image_server_group_id], session[:chapman_code])
    @all_data = true
    record_type = @freereg1_csv_entry.lookup_record_type
    @order, @array_of_entries, @json_of_entries = @freereg1_csv_entry.order_fields_for_record_type(record_type, @entry.freereg1_csv_file.def, current_user.present?)
  end

  def update
    @freereg1_csv_entry = Freereg1CsvEntry.find(params[:id]) if params[:id].present?
    unless Freereg1CsvEntry.valid_freereg1_csv_entry?(@freereg1_csv_entry)
      message = 'The entry was incorrectly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    old_search_record = @freereg1_csv_entry.search_record
    @freereg1_csv_file = @freereg1_csv_entry.freereg1_csv_file
    params[:freereg1_csv_entry][:record_type] = @freereg1_csv_file.record_type
    @freereg1_csv_file.check_and_augment_def(params[:freereg1_csv_entry])

    params[:freereg1_csv_entry] = @freereg1_csv_entry.adjust_parameters(params[:freereg1_csv_entry])
    proceed = @freereg1_csv_entry.update_attributes(freereg1_csv_entry_params)
    message = @freereg1_csv_entry.errors.full_messages
    message = message + @freereg1_csv_entry.embargo_records.last.errors.full_messages unless @freereg1_csv_entry.embargo_records.blank?
    redirect_back(fallback_location: edit_freereg1_csv_entry_path(@freereg1_csv_entry), notice: "The update of the entry failed #{message}.") && return unless proceed

    @freereg1_csv_entry.check_and_correct_county
    @freereg1_csv_entry.check_year
    
    # search_version = calculate_software_version
    place, _church, _register = get_location_from_file(@freereg1_csv_file)
    # SearchRecord.update_create_search_record(@freereg1_csv_entry, search_version, place)
    
    update_file_statistics(place)
    # @freereg1_csv_file.update_statistics_and_access(session[:my_own])

    @freereg1_csv_entry.reload
    @freereg1_csv_entry.update_place_ucf_list(place, @freereg1_csv_file, old_search_record)
    flash[:notice] = 'The change in entry contents was successful, the file is now locked against replacement until it has been downloaded.'
    if session[:zero_listing]
      session.delete(:zero_listing)
      redirect_to freereg1_csv_entry_path(@freereg1_csv_entry, zero_listing: 'true')
    else
      redirect_to freereg1_csv_entry_path(@freereg1_csv_entry)
    end
  end

  def update_batch_error_file
    error = @freereg1_csv_file.batch_errors.find(session[:error_id])
    error.delete
    session[:error_id] = nil
  end

  def update_file_statistics(place)
    @freereg1_csv_file.calculate_distribution
    search_version = calculate_software_version
    SearchRecord.update_create_search_record(@freereg1_csv_entry, search_version, place)
    @freereg1_csv_file.backup_file
    @freereg1_csv_file.lock_all(session[:my_own])
    @freereg1_csv_file.modification_date = Time.now.strftime("%d %b %Y")
    @freereg1_csv_file.error = @freereg1_csv_file.batch_errors.count - 1 if session[:error_id].present?
    @freereg1_csv_file.userid_detail_id = @userid
    @freereg1_csv_file.save
  end

  def update_other_statistics(place, church, register)
    register.calculate_register_numbers
    church.calculate_church_numbers
    place.calculate_place_numbers
  end

  private

  def freereg1_csv_entry_params
    params.require(:freereg1_csv_entry).permit!
  end
end
