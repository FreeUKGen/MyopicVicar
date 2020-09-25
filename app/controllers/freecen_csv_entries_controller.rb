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

  def accept
    @freecen_csv_entry = FreecenCsvEntry.find(params[:id]) if params[:id].present?
    unless FreecenCsvEntry.valid_freecen_csv_entry?(@freecen_csv_entry)
      message = 'The entry was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    @freecen_csv_entry.update_attributes(warning_messages: '', record_valid: 'true')

    @freecen_csv_entry.remove_flags if @freecen_csv_entry.flag

    flash[:notice] = 'The acceptance was successful'
    redirect_to(freecen_csv_entry_path(@freecen_csv_entry)) && return
  end

  def revalidate
    @freecen_csv_entry = FreecenCsvEntry.find(params[:id]) if params[:id].present?
    unless FreecenCsvEntry.valid_freecen_csv_entry?(@freecen_csv_entry)
      message = 'The entry was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    @freecen_csv_entry.update_attributes(record_valid: 'false')
    @freecen_csv_entry.validate_on_line_edit_of_fields(@freecen_csv_entry)

    if @freecen_csv_entry.errors.any?
      redirect_back(fallback_location: edit_freecen_csv_entry_path(@freecen_csv_entry), notice: "The revalidation of the entry failed #{@freecen_csv_entry.errors.full_messages}.") && return
    else
      @freecen_csv_entry.update_attributes(warning_messages: "Warning: Line #{@freecen_csv_entry.record_number}: Validator requested reprocessing", record_valid: 'false')
      @freecen_csv_file = @freecen_csv_entry.freecen_csv_file
      @freecen_csv_file.update_attributes(locked_by_transcriber: true)
      flash[:notice] = 'The entry was declared false.'
      redirect_to freecen_csv_entry_path(@freecen_csv_entry)
    end
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

    # need to deal with change in place
    @freecen_csv_file.freereg1_csv_entries << @freecen_csv_entry
    @freecen_csv_file.save
    if @freecen_csv_file.errors.any?
      message = "The entry creation failed #{@freecen_csv_file.errors.full_messages}"
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    # We need to update the file statistics and update the search record
    # WE update the place, church and register distributions

    flash[:notice] = 'The creation was successful, a backup of file made and locked'
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
    @piece = @freecen_csv_file.freecen2_piece
    @year = @piece.year
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
    @year, piece, @census_fields = Freecen2Piece.extract_year_and_piece(@piece.number, @chapman_code)
    @data_transition = @freecen_csv_entry.data_transition
    @date = DateTime.now
    session[:freecen_csv_entry_id] = @freecen_csv_entry._id
    @deleted_flag = ''
    @subplaces = []
    @piece.freecen2_civil_parishes.each do |place|
      @subplaces << place[:name]
    end
    @languages = FreecenValidations::VALID_LANGUAGE
    @dwelling = Freecen::LOCATION_DWELLING
    @counties = ChapmanCode.freecen_birth_codes
    @counties.sort!
    get_user_info_from_userid
  end

  def index
    unless FreecenCsvFile.valid_freecen_csv_file?(session[:freecen_csv_file_id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    display_info
    @type = params[:type]

    @type = session[:cen_index_type] if @type.blank? && session[:cen_index_type].present?
    session[:cen_index_type] = params[:type]
    if @type.blank?
      @freecen_csv_entries = FreecenCsvEntry.where(freecen_csv_file_id: @freecen_csv_file_id).all.order_by(record_number: 1)
    elsif @type == 'Civ'
      @freecen_csv_entries = FreecenCsvEntry.where(freecen_csv_file_id: @freecen_csv_file_id).in(data_transition: Freecen::LOCATION).all.order_by(record_number: 1)
    elsif @type == 'Pag'
      @freecen_csv_entries = FreecenCsvEntry.where(freecen_csv_file_id: @freecen_csv_file_id).in(data_transition: Freecen::LOCATION_PAGE).all.order_by(record_number: 1)
    elsif @type == 'Dwe'
      @freecen_csv_entries = FreecenCsvEntry.where(freecen_csv_file_id: @freecen_csv_file_id).in(data_transition: Freecen::LOCATION_DWELLING).all.order_by(record_number: 1)
    elsif @type == 'Ind'
      @freecen_csv_entries = FreecenCsvEntry.where(freecen_csv_file_id: @freecen_csv_file_id).all.order_by(record_number: 1)
    elsif @type == 'Err'
      @freecen_csv_entries = FreecenCsvEntry.where(freecen_csv_file_id: @freecen_csv_file_id).where(:error_messages.gte => 1).all.order_by(record_number: 1)
    elsif @type == 'War'
      @freecen_csv_entries = FreecenCsvEntry.where(freecen_csv_file_id: @freecen_csv_file_id).where(:warning_messages.gte => 1).all.order_by(record_number: 1)
    elsif @type == 'Inf'
      @freecen_csv_entries = FreecenCsvEntry.where(freecen_csv_file_id: @freecen_csv_file_id).where(:info_messages.gte => 1).all.order_by(record_number: 1)
    elsif @type == 'Fla'
      @freecen_csv_entries = FreecenCsvEntry.where(freecen_csv_file_id: @freecen_csv_file_id).where(flag: true).all.order_by(record_number: 1)
    end
    @freecen_csv_file.add_list_of_records(@type, @freecen_csv_entries)
  end

  def new
    # NOT CURRENTLY IN USE
    session[:error_id] = nil
    unless FreecenCsvFile.valid_freecen_csv_file?(session[:freecen_csv_file_id])
      flash[:notice] = 'The entry was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    display_info
    @freecen_csv_file = FreecenCsvFile.find_by(_id: session[:freecen_csv_file_id])
    record_number = @freecen_csv_file.total_records.to_i + 1
    redirect_back(fallback_location: new_manage_resource_path, notice: 'File is currently awaiting processing and should not be edited') && return unless @freecen_csv_file.can_we_edit?

    @freecen_csv_entry = FreecenCsvEntry.new(freecen_csv_file_id: session[:freecen_csv_file_id], record_number: record_number)
    session[:freecen_csv_entry_id] = @freecen_csv_entry._id
    @subplaces = []
    @piece.freecen2_civil_parishes.each do |place|
      @subplaces << place[:name]
    end
    @languages = FreecenValidations::VALID_LANGUAGE
  end

  def show
    @freecen_csv_entry = FreecenCsvEntry.find(params[:id]) if params[:id].present?

    unless FreecenCsvEntry.valid_freecen_csv_entry?(@freecen_csv_entry)
      message = 'The entry was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    display_info
    @type = session[:cen_index_type]
    session[:freecen_csv_entry_id] = @freecen_csv_entry._id
    @search_record = @freecen_csv_entry.search_record
    @entry = @freecen_csv_entry
    @next_entry, @previous_entry = @freecen_csv_entry.next_and_previous_entries
    @next_list_entry, @previous_list_entry = @freecen_csv_entry.next_and_previous_list_entries
    session[:current_list_entry] = @entry.id if @next_list_entry.present? || @previous_list_entry.present?
    session[:next_list_entry] = @next_list_entry.id if @next_list_entry.present?
    session[:previous_list_entry] = @previous_list_entry.id if @previous_list_entry.present?
  end

  def update
    @freecen_csv_entry = FreecenCsvEntry.find(params[:id]) if params[:id].present?
    unless FreecenCsvEntry.valid_freecen_csv_entry?(@freecen_csv_entry)
      message = 'The entry was incorrectly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    old_search_record = @freecen_csv_entry.search_record
    @freecen_csv_file = @freecen_csv_entry.freecen_csv_file
    params[:freecen_csv_entry][:verbatim_birth_place] = params[:freecen_csv_entry][:verbatim_birth_place].strip
    @freecen_csv_entry.validate_on_line_edit_of_fields(params[:freecen_csv_entry])

    if @freecen_csv_entry.errors.any?
      redirect_back(fallback_location: edit_freecen_csv_entry_path(@freecen_csv_entry), notice: "The update of the entry failed #{@freecen_csv_entry.errors.full_messages}.") && return
    else
      @freecen_csv_entry.update_attributes(params[:freecen_csv_entry])
      #SearchRecord.update_create_search_record(@freecen_csv_entry, search_version, place)
      @freecen_csv_file.update_attributes(locked_by_transcriber: true)
      flash[:notice] = 'The change in entry contents was successful, the file is now locked against replacement until it has been downloaded.'
      redirect_to freecen_csv_entry_path(@freecen_csv_entry)
    end
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

  private

  def freecen_csv_entry_params
    params.require(:freecen_csv_entry).permit!
  end
end
