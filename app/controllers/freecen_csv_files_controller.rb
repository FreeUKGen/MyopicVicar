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
class FreecenCsvFilesController < ApplicationController
  require 'chapman_code'
  require 'freecen_constants'

  def by_userid
    # entry by userid
    session[:page] = request.original_url
    session[:my_own] = false
    session[:userid_id] = params[:id]
    get_user_info_from_userid
    @county =  session[:county]
    @role = session[:role]
    user = UseridDetail.find(params[:id])
    @who = user.userid
    @role = session[:role]
    @freecen_csv_files = FreecenCsvFile.userid(user.userid).all.order_by('file_name ASC', 'userid_lower_case ASC').page(params[:page]).per(FreeregOptionsConstants::FILES_PER_PAGE)  unless user.blank?
    render 'index'
  end

  def change_userid
    @freecen_csv_file = FreecenCsvFile.find(params[:id])
    unless FreecenCsvFile.valid_freecen_csv_file?(params[:id])
      message = 'The file was not correctly linked. Contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    redirect_back(fallback_location: freecen_csv_file_path(@freecen_csv_file), notice: 'File is currently awaiting processing and should not be edited') && return unless @freecen_csv_file.can_we_edit?

    session[:return_to] = request.original_url
    controls(@freecen_csv_file)
    @records = @freecen_csv_file.freecen_csv_entries.count
    @userids = UseridDetail.get_userids_for_selection('all')
  end

  def controls(file)
    get_user_info_from_userid
    @physical_file = PhysicalFile.userid(file.userid).file_name(file.file_name).first
    @role = session[:role]
    @freecen_csv_file_name = file.file_name
    session[:freecen_csv_file_id] = file._id
    @piece = file.freecen2_piece
    @return_location = file.freecen2_piece.id if file.freecen2_piece.present?
  end

  def convert_header
    @freecen_csv_file = FreecenCsvFile.find(params[:id])
    unless FreecenCsvFile.valid_freecen_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    success, message, file_location, _fil = @freecen_csv_file.create_modern_header_file
    if success
      if File.file?(file_location)
        send_file(file_location, filename: @freecen_csv_file.file_name, x_sendfile: true) && return
      end
    else
      flash[:notice] = "There was a problem saving the file prior to download. Please send this message #{message} to your coordinator"
    end

    redirect_back(fallback_location: new_manage_resource_path) && return
  end

  def create
  end

  def destroy
    # this removes all batches and the file
    @freecen_csv_file = FreecenCsvFile.find(params[:id])
    unless FreecenCsvFile.valid_freecen_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    redirect_back(fallback_location: freecen_csv_file_path(@freecen_csv_file), notice: 'File is currently awaiting processing and should not be edited') && return unless @freecen_csv_file.can_we_edit?
    controls(@freecen_csv_file)
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The batch cannot be deleted it is locked') && return if @freecen_csv_file.locked_by_transcriber || @freecen_csv_file.locked_by_coordinator

    redirect_back(fallback_location: new_manage_resource_path, notice: 'The physical file entry no longer exists. Perhaps you have already deleted it.') && return  if @physical_file.blank?


    # save a copy to attic and delete all batches
    @physical_file.freecen_csv_file_and_entries_delete

    @physical_file.delete
    session[:type] = 'edit'
    flash[:notice] = 'The deletion of the batches was successful'
    if session[:my_own]
      redirect_to my_own_freecen_csv_file_path
    else
      redirect_to register_path(@return_location)
    end
  end

  def display_my_own_files
    get_user_info_from_userid
    @who = @first_name
    @sorted_by = 'Alphabetical by file name'
    session[:sort] = 'file_name ASC'
    session[:sorted_by] = @sorted_by
    @freecen_csv_files = FreecenCsvFile.userid(session[:userid]).order_by(session[:sort]).all.page(params[:page]).per(FreeregOptionsConstants::FILES_PER_PAGE)
    render 'index'
  end

  def display_my_error_files
    get_user_info_from_userid
    @who = @first_name
    @sorted_by = 'Ordered by number of errors'
    session[:sorted_by] = @sorted_by
    session[:sort] = 'error DESC, file_name ASC'
    @freecen_csv_files = FreecenCsvFile.userid(session[:userid]).errors.order_by(session[:sort]).all.page(params[:page]).per(FreeregOptionsConstants::FILES_PER_PAGE)
    render 'index'
  end

  def display_my_own_files_by_descending_uploaded_date
    get_user_info_from_userid
    @who = @first_name
    @sorted_by = 'Ordered by most recent'
    session[:sorted_by] = @sorted_by
    session[:sort] = 'uploaded_date DESC'
    @freecen_csv_files = FreecenCsvFile.userid(session[:userid]).order_by(session[:sort]).all.page(params[:page]).per(FreeregOptionsConstants::FILES_PER_PAGE)
    render 'index'
  end

  def display_my_own_files_by_ascending_uploaded_date
    get_user_info_from_userid
    @who = @first_name
    @sorted_by = 'Ordered by oldest'
    session[:sort] = 'uploaded_date ASC'
    session[:sorted_by] = @sorted_by
    @freecen_csv_files = FreecenCsvFile.userid(session[:userid]).order_by(session[:sort]).all.page(params[:page]).per(FreeregOptionsConstants::FILES_PER_PAGE)
    render 'index'
  end

  def display_my_own_files_by_selection
    get_user_info_from_userid
    @who = @first_name
    @freecen_csv_file = FreecenCsvFile.new
    @freecen_csv_files = FreecenCsvFile.userid(@user.userid).order_by('file_name ASC').all
    @files = {}
    @freecen_csv_files.each do |file|
      @files[":#{file.file_name}"] = file._id if file.file_name.present?
    end
    @options = @files
    @location = 'location.href= "/freecen_csv_files/" + this.value'
    @prompt = 'Select batch'
    render '_form_for_selection'
  end

  def display_my_own_files_waiting_to_be_processed
    get_user_info_from_userid
    @who = @first_name
    @batches = PhysicalFile.userid(@user.userid).waiting.all.order_by('waiting_date DESC')
  end

  def download
    @freecen_csv_file = FreecenCsvFile.find(params[:id])
    unless FreecenCsvFile.valid_freecen_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    proceed, message = @freecen_csv_file.check_file
    if proceed
      success = @freecen_csv_file.backup_file
      if success
        my_file = File.join(Rails.application.config.datafiles, @freecen_csv_file.userid, @freecen_csv_file.file_name)
        if File.file?(my_file)
          @freecen_csv_file.update_attributes(digest: Digest::MD5.file(my_file).hexdigest)
          @freecen_csv_file.force_unlock
          send_file(my_file, filename: @freecen_csv_file.file_name, x_sendfile: true) and return
        end
      else
        flash[:notice] = 'There was a problem saving the file prior to download. Please send this message to your coordinator'
      end
    else
      flash[:notice] = "We cannot download the file: #{message}. Contact your coordinator if you need advice."
    end
    redirect_back(fallback_location: new_manage_resource_path) && return
  end

  def download_message_report
    @freecen_csv_file = FreecenCsvFile.find(params[:id])
    unless FreecenCsvFile.valid_freecen_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    proceed, message = @freecen_csv_file.check_file
    if proceed
      text_file = "#{@freecen_csv_file.file_name}.txt"
      my_file = File.join(Rails.application.config.datafiles, @freecen_csv_file.userid, text_file)
      if File.file?(my_file)
        flash[:notice] = 'The file has been downloaded to your computer'
        send_file(my_file, filename: text_file, x_sendfile: true) and return
      else
        flash[:notice] = 'The message file does not exist.'
      end
    else
      flash[:notice] = "We cannot download the message file: #{message}. Contact your coordinator if you need advice."
    end
    redirect_back(fallback_location: new_manage_resource_path) && return
  end

  def download_spreadsheet
    @freecen_csv_file = FreecenCsvFile.new
    @options = {}
    Freecen::HEADER_OPTIONS.each_with_index do |value, index|
      @options[value.to_sym] = index
    end
    @location = 'location.href= "/freecen_csv_files/spreadsheet/" + this.value'
    @prompt = 'Select spreadsheet'
  end

  def edit
    @freecen_csv_file = FreecenCsvFile.find(params[:id])
    unless FreecenCsvFile.valid_freecen_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    if session[:error_line].present?
      message = 'Header and Place name errors can only be corrected by correcting the file and either replacing or uploading a new file'
      redirect_back(fallback_location: {:action => 'show'}, notice: message) && return
    end
    if @freecen_csv_file.can_we_edit?
      session[:return_to] = request.original_url
      controls(@freecen_csv_file)
      @role = session[:role]
      get_places_for_menu_selection
    else
      message = 'File is currently awaiting processing and should not be edited'
      redirect_back(fallback_location: { action: 'show' }, notice: message) && return
    end
  end

  def error
    @referrer = request.referer
    @freecen_csv_file = FreecenCsvFile.find(params[:id])
    unless FreecenCsvFile.valid_freecen_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    session[:freecen_csv_file_id] = @freecen_csv_file.id if @freecen_csv_file.present?
    redirect_to freecen_csv_entries_path(type: 'Err')
  end

  def incorporate
    @freecen_csv_file = FreecenCsvFile.find(params[:id])
    unless FreecenCsvFile.valid_freecen_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    result, message = @freecen_csv_file.can_we_incorporate?

    redirect_back(fallback_location: { action: 'show' }, notice: message) && return unless result

    get_user_info_from_userid
    logger.warn("FREECEN:CSV_PROCESSING: Starting incorporation rake task for #{@freecen_csv_file.file_name}")
    pid1 =  spawn("rake freecen_csv_file_incorporate[#{@freecen_csv_file.id}]")
    message = "The records for the csv file #{@freecen_csv_file.file_name} are being incorporated. You will receive an email when the task has been completed."
    logger.warn("FREECEN:CSV_PROCESSING: rake task for #{pid1}")

    redirect_back(fallback_location: { action: 'show' }, notice: message) && return
  end

  def unincorporate
    @freecen_csv_file = FreecenCsvFile.find(params[:id])
    unless FreecenCsvFile.valid_freecen_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    proceed, message = @freecen_csv_file.can_we_unincorporate?
    redirect_back(fallback_location: { action: 'show' }, notice: message) && return unless proceed

    get_user_info_from_userid
    logger.warn("FREECEN:CSV_PROCESSING: Starting unincorporation rake task for #{@freecen_csv_file.file_name}")
    pid1 =  spawn("rake freecen_csv_file_unincorporate[#{@freecen_csv_file.id}]")
    message = "The records for the csv file #{@freecen_csv_file.file_name} are being removed from the database. You will receive an email when the task has been completed."
    logger.warn("FREECEN:CSV_PROCESSING: rake task for #{pid1}")

    redirect_back(fallback_location: { action: 'show' }, notice: message) && return
  end


  def index
    # the common listing entry by syndicates and counties
    @county =  session[:county]
    @syndicate =  session[:syndicate]
    @role = session[:role]
    @sorted_by = session[:sorted_by].presence || 'Ordered by most recent'
    if (@county.blank? && @syndicate.blank?) || @role.blank? || @sorted_by.blank?
      redirect_back(fallback_location: new_manage_resource_path, notice: 'Missing parameters') && return
    end
    batches = FreeregOptionsConstants::FILES_PER_PAGE
    get_user_info_from_userid
    if session[:syndicate].present? && session[:userid_id].blank? && helpers.can_view_files?(session[:role]) && helpers.sorted_by?(session[:sorted_by])
      userids = Syndicate.get_userids_for_syndicate(session[:syndicate])
      @freecen_csv_files = FreecenCsvFile.in(userid: userids).gt(total_errors: 0).order_by(session[:sort]).all.page(params[:page]).per(batches)
    elsif session[:syndicate].present? && session[:userid_id].blank? && helpers.can_view_files?(session[:role])
      userids = Syndicate.get_userids_for_syndicate(session[:syndicate])
      @freecen_csv_files = FreecenCsvFile.in(userid: userids).order_by(session[:sort]).all.page(params[:page]).per(batches).includes(:freecen_csv_entries)
    elsif session[:syndicate].present? && session[:userid_id].present? && helpers.can_view_files?(session[:role])
      @freecen_csv_files = FreecenCsvFile.userid(UseridDetail.find(session[:userid_id]).userid).no_timeout.order_by(session[:sort]).all.page(params[:page]).per(batches)
    elsif session[:county].present? && helpers.can_view_files?(session[:role]) && session[:sorted_by] == '; sorted by descending number of errors and then file name'
      @freecen_csv_files = FreecenCsvFile.chapman_code(session[:chapman_code]).gt(total_errors: 0).order_by(session[:sort]).all.page(params[:page]).per(batches)
    elsif session[:county].present? && session[:sorted_by] == '; being validated'
      @freecen_csv_files = FreecenCsvFile.where(chapman_code: session[:chapman_code], validation: true, incorporated: false).order_by(session[:sort]).all.page(params[:page]).per(batches)
    elsif session[:county].present? && session[:sorted_by] == '; incorporated'
      @freecen_csv_files = FreecenCsvFile.where(chapman_code: session[:chapman_code], incorporated: true).no_timeout.order_by(session[:sort]).all.page(params[:page]).per(batches)
    elsif session[:county].present? && helpers.can_view_files?(session[:role])
      @freecen_csv_files = FreecenCsvFile.chapman_code(session[:chapman_code]).no_timeout.order_by(session[:sort]).all.page(params[:page]).per(batches)
    end
    session[:current_page] = @freecen_csv_files.current_page if @freecen_csv_files.present?
  end

  def lock
    @freecen_csv_file = FreecenCsvFile.find(params[:id])
    unless FreecenCsvFile.valid_freecen_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    controls(@freecen_csv_file)
    @freecen_csv_file.lock(session[:my_own])
    flash[:notice] = 'The lock change to all the batches in the file was successful'
    redirect_to freecen_csv_file_path(@freecen_csv_file)
  end

  def merge
    @freecen_csv_file = FreecenCsvFile.find(params[:id])
    unless FreecenCsvFile.valid_freecen_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    redirect_back(fallback_location: freecen_csv_file_path(@freecen_csv_file), notice: 'File is currently awaiting processing and should not be edited') && return unless @freecen_csv_file.can_we_edit?

    controls(@freecen_csv_file)
    proceed, message = @freecen_csv_file.merge_batches
    redirect_back(fallback_location: { action: 'show' }, notice: "Merge unsuccessful; #{message}") && return unless proceed

    success = @freecen_csv_file.calculate_distribution
    @freecen_csv_file.update_freereg_contents_after_processing

    redirect_back(fallback_location: freecen_csv_file_path(@freecen_csv_file), notice: 'The recalculation of the number of records and distribution was unsuccessful') && return unless success

    flash[:notice] = 'The merge of the batches was successful'
    redirect_to freecen_csv_file_path(@freecen_csv_file)
  end

  def my_own
    clean_session
    clean_session_for_county
    clean_session_for_syndicate
    get_user_info_from_userid
    session[:my_own] = true
    @who = @first_name
    @sorted_by = 'Ordered by most recent'
    session[:sorted_by] = @sorted_by
    session[:sort] = 'uploaded_date DESC'
    @freecen_csv_files = FreecenCsvFile.userid(session[:userid]).order_by(session[:sort]).all.page(params[:page]).per(FreeregOptionsConstants::FILES_PER_PAGE)
    render 'index'
  end

  def relocate
    @freecen_csv_file = FreecenCsvFile.find(params[:id])
    unless FreecenCsvFile.valid_freecen_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    redirect_back(fallback_location: freecen_csv_file_path(@freecen_csv_file), notice: 'File is currently awaiting processing and should not be edited') && return unless @freecen_csv_file.can_we_edit?

    session[:return_to] = request.original_url
    controls(@freecen_csv_file)
    session[:initial_page] = @return_location
    session[:selectcountry] = nil
    session[:selectcounty] = nil
    @records = @freecen_csv_file.freecen_csv_entries.count
    max_records = get_max_records(@user)
    redirect_back(fallback_location: freecen_csv_file_path(@freecen_csv_file), notice: 'There are too many records for an on-line relocation') && return if @records.present? && @records.to_i >= max_records

    session[:records] = @records
    if @user.person_role == 'system_administrator' || @user.person_role == 'data_manager'
      @county = session[:county]
      locations
      # setting these means that we are a DM
      session[:selectcountry] = nil
      session[:selectcounty] = nil
      session[:selectplace] = session[:selectchurch] = nil
      @countries = ['Select Country', 'England', 'Islands', 'Scotland', 'Wales']
      @counties = []
      @placenames = []
      @churches = []
      @register_types = []
      @selected_place = @selected_church = @selected_register = ''
    else
      # only senior managers can move between counties and countries; coordinators could loose files
      place = @freecen_csv_file.register.church.place
      session[:selectcountry] = place.country
      session[:selectcounty] = place.chapman_code
      redirect_to(action: 'update_places') && return
    end
  end

  def remove
    # this just removes a batch of records it leaves the entries and search records there to be removed by a rake task
    @freecen_csv_file = FreecenCsvFile.find(params[:id])
    unless FreecenCsvFile.valid_freecen_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    redirect_back(fallback_location: freecen_csv_file_path(@freecen_csv_file), notice: 'File is currently awaiting processing and should not be edited') && return unless @freecen_csv_file.can_we_edit?

    controls(@freecen_csv_file)
    proceed, message = @freecen_csv_file.remove_batch
    flash[:notice] = proceed ? 'The removal of the batch was successful' : message
    if session[:my_own]
      redirect_to my_own_freecen_csv_file_path
    elsif session[:page]
      redirect_to session[:page]
    elsif session[:return_to].present?
      redirect_to session[:return_to]
    else
      redirect_to manage_resource_path(@user)
    end
  end

  def show
    # show an individual batch
    @freecen_csv_file = FreecenCsvFile.find(params[:id])
    unless FreecenCsvFile.valid_freecen_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    controls(@freecen_csv_file)
    session.delete(:cen_index_type)
    session.delete(:next_list_entry)
    session.delete(:current_list_entry)
    session.delete(:previous_list_entry)
    @freecen_csv_file.update_attribute(:list_of_records, nil) if @freecen_csv_file.list_of_records.present?
    @piece = @freecen_csv_file.freecen2_piece
  end

  def spreadsheet
    @freecen_csv_file = FreecenCsvFile.new
    header = Freecen::HEADER_OPTIONS_TRANSLATION[params[:id].to_i]
    file_name = "#{Freecen::HEADER_OPTIONS[params[:id].to_i]}_spreadersheet_header.csv"
    my_file = @freecen_csv_file.write_spreadsheet_header(header)
    if File.file?(my_file)
      flash[:notice] = 'The spreadsheet header has been downloaded to your computer'
      send_file(my_file, filename: file_name, x_sendfile: true) && return
    else
      flash[:notice] = 'The message file does not exist.'
    end
  end

  def update
    #update the headers
    @freecen_csv_file = FreecenCsvFile.find(params[:id])
    unless FreecenCsvFile.valid_freecen_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    redirect_back(fallback_location: freecen_csv_file_path(@freecen_csv_file), notice: 'File is currently awaiting processing and should not be edited') && return unless @freecen_csv_file.can_we_edit?
    controls(@freecen_csv_file)
    case params[:commit]
    when 'Copy to Userid'
      flash[:notice] = 'Cannot select a blank userid' if params[:freecen_csv_file][:userid].blank?
      redirect_to(action: 'change_userid') && return if params[:freecen_csv_file][:userid].blank?

      proceed, message = @freecen_csv_file.change_owner_of_file(params[:freecen_csv_file][:userid])
      if proceed
        flash[:notice] = 'The copy of the file to userid is being processed'
        redirect_to(freecen_csv_file_path(@freecen_csv_file)) && return
      else
        flash[:notice] = "The copy of the file to userid was unsuccessful: #{message}"
        redirect_to(change_userid_freecen_csv_file_path(@freecen_csv_file)) && return
      end
    when 'Submit'
      # lets see if we are moving the file
      @freecen_csv_file.check_locking_and_set(params[:freecen_csv_file], session)
      @freecen_csv_file.update_attributes(freecen_csv_file_params)
      @freecen_csv_file.update_attributes(:modification_date => Time.now.strftime('%d %b %Y'))
      if @freecen_csv_file.errors.any?
        flash[:notice] = "The update of the batch was unsuccessful: #{message}"
        render action: 'edit'
        return
      end
      if session[:error_line].present?
        # lets remove the header errors
        @freecen_csv_file.error = @freecen_csv_file.error - session[:header_errors]
        session[:error_id].each do |id|
          error = BatchError.find(id)
          @freecen_csv_file.batch_errors.delete(error) if error.present?
        end
        @freecen_csv_file.save
        # clean out the session variables
        session[:error_id] = nil
        session[:header_errors] = nil
        session[:error_line] = nil
      else
        session[:type] = 'edit'
        flash[:notice] = 'The update of the batch was successful'
        redirect_to(action: 'show') && return
      end
    when 'Relocate'
      proceed, message = FreecenCsvFile.file_update_location(@freecen_csv_file, params[:freecen_csv_file], session)
      if proceed
        flash[:notice] = 'The relocation of the batch was successful'
      else
        flash[:notice] = message
        redirect_to(action: 'relocate') && return
      end
    else
      # lets see if we are moving the file
      @freecen_csv_file.check_locking_and_set(params[:freecen_csv_file], session)
      @freecen_csv_file.update_attributes(freecen_csv_file_params)
      @freecen_csv_file.update_attributes(:modification_date => Time.now.strftime('%d %b %Y'))
      if @freecen_csv_file.errors.any?
        flash[:notice] = "The update of the batch was unsuccessful: #{message}"
        render action: 'edit'
        return
      end
      if session[:error_line].present?
        # lets remove the header errors
        @freecen_csv_file.error = @freecen_csv_file.error - session[:header_errors]
        session[:error_id].each do |id|
          error = BatchError.find(id)
          @freecen_csv_file.batch_errors.delete(error) if error.present?
        end
        @freecen_csv_file.save
        # clean out the session variables
        session[:error_id] = nil
        session[:header_errors] = nil
        session[:error_line] = nil
      else
        session[:type] = 'edit'
        flash[:notice] = 'The update of the batch was successful'
        redirect_to(action: 'show') && return
      end
    end
    redirect_to session[:return_to]
  end

  def validate
    file = FreecenCsvFile.find_by(id: params[:id])
    if file.blank?
      message = 'File does not exist'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    elsif file.traditional.zero?
      message = 'File has traditional headers and  must be converted before validation'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    elsif file.validation
      message = 'File is already bring validated'
    elsif file.total_errors > 0
      message = 'File has error messages so cannot be validated'
    else
      file.update(validation: true)
      message = 'File is now ready for validation'
    end
    flash[:notice] = message
    redirect_to freecen_csv_file_path(file)
  end

  private

  def freecen_csv_file_params
    params.require(:freecen_csv_file).permit!
  end

  def display_info
    @freecen_csv_file_id = @freecen_csv_file.id
    @freecen_csv_file_name = @freecen_csv_file.file_name
    @file_owner = @freecen_csv_file.userid
    @register = @freecen_csv_file.register
    @register_name = RegisterType.display_name(@register.register_type)
    @church = @register.church
    @church_name = @church.church_name
    @place = @church.place
    @county = @place.county
    @place_name = @place.place_name
    @user = get_user
    @first_name = @user.person_forename if @user.present?
  end
end
