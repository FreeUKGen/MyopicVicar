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
class Freereg1CsvFilesController < ApplicationController
  require 'chapman_code'
  require 'freereg_options_constants'

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
    batches = FreeregOptionsConstants::FILES_PER_PAGE
    @freereg1_csv_files = Freereg1CsvFile.userid(user.userid).all.order_by('file_name ASC', 'userid_lower_case ASC').page(params[:page]).per(batches)  unless user.blank?
    render 'index'
  end

  def change_userid
    @freereg1_csv_file = Freereg1CsvFile.find(params[:id])
    unless Freereg1CsvFile.valid_freereg1_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    redirect_back(fallback_location: freereg1_csv_file_path(@freereg1_csv_file), notice: 'File is currently awaiting processing and should not be edited') && return unless @freereg1_csv_file.can_we_edit?

    session[:return_to] = request.original_url
    controls(@freereg1_csv_file)
    locations
    @records = @freereg1_csv_file.freereg1_csv_entries.count
    @userids = UseridDetail.get_userids_for_selection('all')
  end

  def controls(file)
    get_user_info_from_userid
    @physical_file = PhysicalFile.userid(file.userid).file_name(file.file_name).first
    @role = session[:role]
    @freereg1_csv_file_name = file.file_name
    session[:freereg1_csv_file_id] = file._id
    @register = file.register
    @return_location = file.register.id if file.register.present?
  end

  def create
  end

  def destroy
    # this removes all batches and the file
    @freereg1_csv_file = Freereg1CsvFile.find(params[:id])
    unless Freereg1CsvFile.valid_freereg1_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    redirect_back(fallback_location: freereg1_csv_file_path(@freereg1_csv_file), notice: 'File is currently awaiting processing and should not be edited') && return unless @freereg1_csv_file.can_we_edit?
    controls(@freereg1_csv_file)
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The batch cannot be deleted it is locked') && return if @freereg1_csv_file.locked_by_transcriber || @freereg1_csv_file.locked_by_coordinator

    redirect_back(fallback_location: new_manage_resource_path, notice: 'The physical file entry no longer exists. Perhaps you have already deleted it.') && return  if @physical_file.blank?

    @freereg1_csv_file.remove_from_ucf_list
    # save a copy to attic and delete all batches
    @physical_file.file_and_entries_delete
    @freereg1_csv_file.update_freereg_contents_after_processing
    @physical_file.delete
    session[:type] = 'edit'
    flash[:notice] = 'The deletion of the batches was successful'
    if session[:my_own]
      redirect_to my_own_freereg1_csv_file_path
    else
      redirect_to register_path(@return_location)
    end
  end

  def display_my_own_files
    get_user_info_from_userid
    @who = @first_name
    @sorted_by = ' Alphabetical by file name'
    session[:sort] = 'file_name ASC'
    session[:sorted_by] = @sorted_by
    batches = FreeregOptionsConstants::FILES_PER_PAGE
    @freereg1_csv_files = Freereg1CsvFile.userid(session[:userid]).order_by(session[:sort]).all.page(params[:page]).per(batches)
    render 'index'
  end

  def display_my_error_files
    get_user_info_from_userid
    @who = @first_name
    @sorted_by = ' Ordered by number of errors'
    session[:sorted_by] = @sorted_by
    session[:sort] = 'error DESC, file_name ASC'
    batches = FreeregOptionsConstants::FILES_PER_PAGE
    @freereg1_csv_files = Freereg1CsvFile.userid(session[:userid]).errors.order_by(session[:sort]).all.page(params[:page]).per(batches)
    render 'index'
  end

  def display_my_own_files_by_descending_uploaded_date
    get_user_info_from_userid
    @who = @first_name
    @sorted_by = ' Ordered by most recent'
    session[:sorted_by] = @sorted_by
    session[:sort] = 'uploaded_date DESC'
    batches = FreeregOptionsConstants::FILES_PER_PAGE
    @freereg1_csv_files = Freereg1CsvFile.userid(session[:userid]).order_by(session[:sort]).all.page(params[:page]).per(batches)
    render 'index'
  end

  def display_my_own_files_by_ascending_uploaded_date
    get_user_info_from_userid
    @who = @first_name
    @sorted_by = ' Ordered by oldest'
    session[:sort] = 'uploaded_date ASC'
    session[:sorted_by] = @sorted_by
    batches = FreeregOptionsConstants::FILES_PER_PAGE
    @freereg1_csv_files = Freereg1CsvFile.userid(session[:userid]).order_by(session[:sort]).all.page(params[:page]).per(batches)
    render 'index'
  end

  def display_my_own_zero_years
    get_user_info_from_userid
    @who = @first_name
    session[:zero_action] = 'My Own Action'
    @sorted_by = ' Zero years'
    session[:sort] = 'uploaded_date ASC'
    session[:sorted_by] = @sorted_by
    batches = FreeregOptionsConstants::FILES_PER_PAGE
    @freereg1_csv_files = Freereg1CsvFile.userid(session[:userid]).datemin('0').order_by(session[:sort]).page(params[:page]).per(batches)
    render 'index'
  end

  def display_my_own_files_by_selection
    get_user_info_from_userid
    @who = @first_name
    @freereg1_csv_file = Freereg1CsvFile.new
    @freereg1_csv_files = Freereg1CsvFile.userid(@user.userid).order_by('file_name ASC').all
    @files = {}
    @freereg1_csv_files.each do |file|
      @files[":#{file.file_name}"] = file._id if file.file_name.present?
    end
    @options = @files
    @location = 'location.href= "/freereg1_csv_files/" + this.value'
    @prompt = 'Select batch'
    render '_form_for_selection'
  end

  def display_my_own_files_waiting_to_be_processed
    get_user_info_from_userid
    @who = @first_name
    @batches = PhysicalFile.userid(@user.userid).waiting.all.order_by('waiting_date DESC')
  end

  def download
    @freereg1_csv_file = Freereg1CsvFile.find(params[:id])
    unless Freereg1CsvFile.valid_freereg1_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    proceed, message = @freereg1_csv_file.check_file
    if proceed
      success = @freereg1_csv_file.backup_file
      if success
        my_file = File.join(Rails.application.config.datafiles, @freereg1_csv_file.userid, @freereg1_csv_file.file_name)
        if File.file?(my_file)
          @freereg1_csv_file.update_attributes(digest: Digest::MD5.file(my_file).hexdigest)
          @freereg1_csv_file.force_unlock
          flash[:notice] = 'The file has been downloaded to your computer'
          send_file(my_file, filename: @freereg1_csv_file.file_name, x_sendfile: true) and return
        end
      else
        flash[:notice] = 'There was a problem saving the file prior to download. Please take this message to your coordinator'
      end
    else
      flash[:notice] = "We cannot download the file: #{message}. Contact your coordinator if you need advice."
    end
    redirect_back(fallback_location: new_manage_resource_path) && return
  end

  def edit
    @freereg1_csv_file = Freereg1CsvFile.find(params[:id])
    unless Freereg1CsvFile.valid_freereg1_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    if session[:error_line].present?
      message = 'Header and Place name errors can only be corrected by correcting the file and either replacing or uploading a new file'
      redirect_back(fallback_location: {:action => 'show'}, notice: message) && return
    end
    if @freereg1_csv_file.can_we_edit?
      session[:return_to] = request.original_url
      controls(@freereg1_csv_file)
      @role = session[:role]
      get_places_for_menu_selection
    else
      message = 'File is currently awaiting processing and should not be edited'
      redirect_back(fallback_location: { action: 'show' }, notice: message) && return
    end
  end

  def embargoed_entries
    @freereg1_csv_file = Freereg1CsvFile.find(params[:id])
    unless Freereg1CsvFile.valid_freereg1_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    @freereg1_csv_entries = @freereg1_csv_file.all_embargoed_entries
    display_info

    @embargoed_entries = true
    render 'freereg1_csv_entries/index'
  end

  def error
    @referrer = request.referer
    @freereg1_csv_file = Freereg1CsvFile.find(params[:id])
    unless Freereg1CsvFile.valid_freereg1_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    controls(@freereg1_csv_file)
    errors_for_error_display
  end

  def errors_for_error_display
    @referrer = request.referer
    @errors = @freereg1_csv_file.batch_errors.count
    @owner = @freereg1_csv_file.userid
    redirect_back(fallback_location: new_manage_resource_path, notice: 'There are no errors') && return if @errors.zero?
    lines = @freereg1_csv_file.batch_errors.all
    @role = session[:role]
    @lines = []
    @system = []
    @header = []
    lines.each do |line|
      @lines << line if line.error_type == 'Data_Error'
      @system << line if line.error_type == 'System_Error'
      @header << line if line.error_type == 'Header_Error'
    end
  end

  def index
    # the common listing entry by syndicates and counties
    @county =  session[:county]
    @syndicate =  session[:syndicate]
    @role = session[:role]
    @sorted_by = session[:sorted_by].presence || ' Ordered by most recent'
    session[:sort] = session[:sort].presence || 'uploaded_date DESC'
    if (@county.blank? && @syndicate.blank?) || @role.blank? || @sorted_by.blank?
      redirect_back(fallback_location: new_manage_resource_path, notice: 'Missing parameters') && return
    end

    batches = FreeregOptionsConstants::FILES_PER_PAGE
    get_user_info_from_userid
    if session[:syndicate].present? && session[:userid_id].blank? && helpers.can_view_files?(session[:role]) && helpers.sorted_by?(session[:sorted_by])
      userids = Syndicate.get_userids_for_syndicate(session[:syndicate])
      @freereg1_csv_files = Freereg1CsvFile.in(userid: userids).gt(error: 0).order_by(session[:sort]).all.page(params[:page]).per(batches)
    elsif session[:syndicate].present? && session[:userid_id].blank? && helpers.can_view_files?(session[:role])
      userids = Syndicate.get_userids_for_syndicate(session[:syndicate])
      @freereg1_csv_files = Freereg1CsvFile.in(userid: userids).order_by(session[:sort]).all.page(params[:page]).per(batches).includes(:freereg1_csv_entries)
    elsif session[:syndicate].present? && session[:userid_id].present? && helpers.can_view_files?(session[:role])
      @freereg1_csv_files = Freereg1CsvFile.userid(UseridDetail.find(session[:userid_id]).userid).no_timeout.order_by(session[:sort]).all.page(params[:page]).per(batches)
    elsif session[:county].present? && helpers.can_view_files?(session[:role]) && session[:sorted_by] == '; sorted by descending number of errors and then file name'
      @freereg1_csv_files = Freereg1CsvFile.county(session[:chapman_code]).gt(error: 0).order_by(session[:sort]).all.page(params[:page]).per(batches)
    elsif session[:county].present? && helpers.can_view_files?(session[:role])
      @freereg1_csv_files = Freereg1CsvFile.county(session[:chapman_code]).no_timeout.order_by(session[:sort]).all.page(params[:page]).per(batches)
    end
  end

  def locations
    @update_counties_location = 'location.href= "/freereg1_csv_files/update_counties?country=" + this.value'
    @update_places_location = 'location.href= "/freereg1_csv_files/update_places?county=" + this.value'
    @update_churches_location = 'location.href= "/freereg1_csv_files/update_churches?place=" + this.value'
    @update_registers_location = 'location.href= "/freereg1_csv_files/update_registers?church=" + this.value'
  end

  def lock
    @freereg1_csv_file = Freereg1CsvFile.find(params[:id])
    unless Freereg1CsvFile.valid_freereg1_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    controls(@freereg1_csv_file)
    @freereg1_csv_file.lock(session[:my_own])
    flash[:notice] = 'The lock change to all the batches in the file was successful'
    redirect_to freereg1_csv_file_path(@freereg1_csv_file)
  end

  def merge
    @freereg1_csv_file = Freereg1CsvFile.find(params[:id])
    unless Freereg1CsvFile.valid_freereg1_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    redirect_back(fallback_location: freereg1_csv_file_path(@freereg1_csv_file), notice: 'File is currently awaiting processing and should not be edited') && return unless @freereg1_csv_file.can_we_edit?

    controls(@freereg1_csv_file)
    proceed, message = @freereg1_csv_file.merge_batches
    redirect_back(fallback_location: { action: 'show' }, notice: "Merge unsuccessful; #{message}") && return unless proceed

    success = @freereg1_csv_file.calculate_distribution
    @freereg1_csv_file.update_freereg_contents_after_processing

    redirect_back(fallback_location: freereg1_csv_file_path(@freereg1_csv_file), notice: 'The recalculation of the number of records and distribution was unsuccessful') && return unless success

    flash[:notice] = 'The merge of the batches was successful'
    redirect_to freereg1_csv_file_path(@freereg1_csv_file)
  end

  def my_own
    clean_session
    clean_session_for_county
    clean_session_for_syndicate
    get_user_info_from_userid
    session[:my_own] = true
    @who = @first_name
    @sorted_by = ' Ordered by most recent'
    session[:sorted_by] = @sorted_by
    session[:sort] = 'uploaded_date DESC'
    batches = FreeregOptionsConstants::FILES_PER_PAGE
    @freereg1_csv_files = Freereg1CsvFile.userid(session[:userid]).order_by(session[:sort]).all.page(params[:page]).per(batches)
    render 'index'
  end

  def relocate
    @freereg1_csv_file = Freereg1CsvFile.find(params[:id])
    unless Freereg1CsvFile.valid_freereg1_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    redirect_back(fallback_location: freereg1_csv_file_path(@freereg1_csv_file), notice: 'File is currently awaiting processing and should not be edited') && return unless @freereg1_csv_file.can_we_edit?

    session[:return_to] = request.original_url
    controls(@freereg1_csv_file)
    session[:initial_page] = @return_location
    session[:selectcountry] = nil
    session[:selectcounty] = nil
    @records = @freereg1_csv_file.freereg1_csv_entries.count
    max_records = get_max_records(@user)
    redirect_back(fallback_location: freereg1_csv_file_path(@freereg1_csv_file), notice: 'There are too many records for an on-line relocation') && return if @records.present? && @records.to_i >= max_records

    session[:records] = @records
    if session[:role] == 'system_administrator' || session[:role] == 'data_manager'
      @county = session[:county]
      locations
      # setting these means that we are a DM
      session[:selectcountry] = nil
      session[:selectcounty] = nil
      session[:selectplace] = session[:selectchurch] = nil
      @countries = ['England', 'Islands', 'Scotland', 'Wales']
      @counties = []
      @placenames = []
      @churches = []
      @register_types = []
      @selected_place = @selected_church = @selected_register = ''
    else
      # only senior managers can move between counties and countries; coordinators could loose files
      place = @freereg1_csv_file.register.church.place
      session[:selectcountry] = place.country
      session[:selectcounty] = place.chapman_code
      redirect_to(action: 'update_places') && return
    end
  end

  def remove
    # this just removes a batch of records it leaves the entries and search records there to be removed by a rake task
    @freereg1_csv_file = Freereg1CsvFile.find(params[:id])
    unless Freereg1CsvFile.valid_freereg1_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end

    redirect_back(fallback_location: freereg1_csv_file_path(@freereg1_csv_file), notice: 'File is currently awaiting processing and should not be edited') && return unless @freereg1_csv_file.can_we_edit?
    controls(@freereg1_csv_file)
    proceed, message = @freereg1_csv_file.remove_batch
    proceed ? flash[:notice] = 'The removal of the batch entry was successful' : flash[:notice] = message

    if session[:my_own]
      redirect_to my_own_freereg1_csv_file_path
    elsif @return_location.blank?
      redirect_to manage_resource_path(@user)
    else
      redirect_to register_path(@return_location)
    end
  end

  def show
    # show an individual batch
    @freereg1_csv_file = Freereg1CsvFile.find(params[:id])
    unless Freereg1CsvFile.valid_freereg1_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    session[:from] = 'place' if params[:from].present? && params[:from] == 'place'
    controls(@freereg1_csv_file)
    @register = @freereg1_csv_file.register
    @gaps = @freereg1_csv_file.register.gaps_exist?
  end

  def show_zero_startyear_entries
    @freereg1_csv_file = Freereg1CsvFile.find(params[:id])
    unless Freereg1CsvFile.valid_freereg1_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    @freereg1_csv_entries = @freereg1_csv_file.get_zero_year_records
    display_info

    @get_zero_year_records = true
    render 'freereg1_csv_entries/index'
  end

  def update_churches
    if update_churches_not_ok?(params[:place])
      flash[:notice] = 'You made an incorrect place selection '
      redirect_to(relocate_freereg1_csv_file_path(session[:freereg1_csv_file_id])) && return
    else
      get_user_info_from_userid
      locations
      @freereg1_csv_file = Freereg1CsvFile.find(session[:freereg1_csv_file_id])
      @countries = [session[:selectcountry]]
      @counties = [session[:selectcounty]]
      place = Place.id(params[:place]).first
      session[:selectplace] = params[:place]
      @placenames = []
      @placenames << place.place_name
      @churches = place.churches.map{ |a| [a.church_name, a.id] }
      @churches[1] = 'Has no churches' if place.churches.blank?
      @freereg1_csv_file.county == session[:selectcounty] && session[:selectplace] == @freereg1_csv_file.place ? @selected_church = @freereg1_csv_file.church_name : @selected_place = ''
      @selected_place = session[:selectplace]
      @register_types = RegisterType::APPROVED_OPTIONS
      @selected_register = ''
    end
  end

  def update_churches_not_ok?(param)
    result = false
    result = true if param.blank? || param == 'Select Place' || session[:selectcountry].blank? || session[:selectcounty].blank? || session[:freereg1_csv_file_id].blank?
    result
  end

  def update_counties
    if update_counties_not_ok?(params[:country])
      flash[:notice] = 'You made an incorrect country selection '
      redirect_to(relocate_freereg1_csv_file_path(session[:freereg1_csv_file_id])) && return
    else
      get_user_info_from_userid
      locations
      @freereg1_csv_file = Freereg1CsvFile.find(session[:freereg1_csv_file_id])
      @countries = [params[:country]]
      session[:selectcountry] = params[:country]
      @counties = ChapmanCode::CODES[params[:country]].keys
      @placenames = []
      @churches = []
      @register_types = RegisterType::APPROVED_OPTIONS
      @selected_county = @freereg1_csv_file.county
      @selected_place = @selected_church = @selected_register = ''
    end
  end

  def update_counties_not_ok?(param)
    result = false
    result = true if param.blank? || param == 'Select Country'  || session[:freereg1_csv_file_id].blank?
    result
  end

  def update_places
    get_user_info_from_userid
    if (session[:role] == 'system_administrator' || session[:role] == 'data_manager')
      if update_places_not_ok?(params[:county])
        flash[:notice] = 'You made an incorrect county selection '
        redirect_to(relocate_freereg1_csv_file_path(session[:freereg1_csv_file_id])) && return
      end
    end
    locations
    @freereg1_csv_file = Freereg1CsvFile.find(session[:freereg1_csv_file_id])
    @countries = [session[:selectcountry]]
    if session[:selectcounty].blank?
      #means we are a DM selecting the county
      session[:selectcounty] = ChapmanCode::CODES[session[:selectcountry]][params[:county]]
      places = Place.chapman_code(session[:selectcounty]).not_disabled.all.order_by(place_name: 1)
    else
      #we are a CC
      places = Place.chapman_code(session[:selectcounty]).not_disabled.all.order_by(place_name: 1)
    end
    @counties = []
    if @freereg1_csv_file.county == session[:selectcounty]
      @selected_place = @freereg1_csv_file.place
      @selected_church = @freereg1_csv_file.church_name
    else
      @selected_place = @selected_church = ''
    end
    @counties << session[:selectcounty]
    @placenames = places.map { |a| [a.place_name, a.id] }
    @placechurches = Place.chapman_code(session[:selectcounty]).place(@freereg1_csv_file.place).not_disabled.first
    if @placechurches.present?
      @churches = @placechurches.churches.map { |a| [a.church_name, a.id] }
    else
      @churches = []
    end
    @register_types = RegisterType::APPROVED_OPTIONS
    @selected_register = ''
  end

  def update_places_not_ok?(param)
    result = false
    result = true if param.blank? || param == 'Select County' || session[:selectcountry].blank?  || session[:freereg1_csv_file_id].blank?
    result
  end

  def update_registers
    if update_registers_not_ok?(params[:church])
      flash[:notice] = 'You made an incorrect church selection '
      redirect_to(relocate_freereg1_csv_file_path(session[:freereg1_csv_file_id])) && return
    else
      get_user_info_from_userid
      locations
      @freereg1_csv_file = Freereg1CsvFile.find(session[:freereg1_csv_file_id])
      @countries = [session[:selectcountry]]
      @counties = [session[:selectcounty]]
      church = Church.id(params[:church]).first
      session[:selectchurch] = params[:church]
      place = church.place
      @placenames = []
      @placenames << place.place_name
      @churches = []
      @churches << church.church_name
      @register_types = RegisterType::APPROVED_OPTIONS
      @selected_place = session[:selectplace]
      @selected_church = session[:selectchurch]
      @selected_register = ''
    end
  end

  def update_registers_not_ok?(param)
    result = false
    result = true if param.blank? || param == 'Has no churches' || param == 'Select Church' || session[:selectcountry].blank? || session[:selectcounty].blank? || session[:selectplace].blank? || session[:freereg1_csv_file_id].blank?
    result
  end

  def update
    #update the headers
    @freereg1_csv_file = Freereg1CsvFile.find(params[:id])
    unless Freereg1CsvFile.valid_freereg1_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    redirect_back(fallback_location: freereg1_csv_file_path(@freereg1_csv_file), notice: 'File is currently awaiting processing and should not be edited') && return unless @freereg1_csv_file.can_we_edit?
    controls(@freereg1_csv_file)
    case params[:commit]
    when 'Change Userid'
      flash[:notice] = 'Cannot select a blank userid' if params[:freereg1_csv_file][:userid].blank?
      redirect_to(action: 'change_userid') && return if params[:freereg1_csv_file][:userid].blank?

      proceed, message = @freereg1_csv_file.change_owner_of_file(params[:freereg1_csv_file][:userid])
      if proceed
        flash[:notice] = 'The change of userid was successful'
        redirect_to(freereg1_csv_file_path(@freereg1_csv_file)) && return
      else
        flash[:notice] = "The change of userid was unsuccessful: #{message}"
        redirect_to(change_userid_freereg1_csv_file_path(@freereg1_csv_file)) && return
      end
    when 'Submit'
      # lets see if we are moving the file
      @freereg1_csv_file.date_change(params[:freereg1_csv_file][:transcription_date],params[:freereg1_csv_file][:modification_date])
      @freereg1_csv_file.check_locking_and_set(params[:freereg1_csv_file],session)
      @freereg1_csv_file.update_attributes(:alternate_register_name => (params[:freereg1_csv_file][:church_name].to_s + ' ' + params[:freereg1_csv_file][:register_type].to_s ))
      @freereg1_csv_file.update_attributes(freereg1_csv_file_params)
      @freereg1_csv_file.update_attributes(:modification_date => Time.now.strftime('%d %b %Y'))
      @freereg1_csv_file.update_freereg_contents_after_processing
      if @freereg1_csv_file.errors.any?
        flash[:notice] = "The update of the batch was unsuccessful: #{message}"
        render action: 'edit'
        return
      end
      if session[:error_line].present?
        # lets remove the header errors
        @freereg1_csv_file.error = @freereg1_csv_file.error - session[:header_errors]
        session[:error_id].each do |id|
          error = BatchError.find(id)
          @freereg1_csv_file.batch_errors.delete(error) if error.present?
        end
        @freereg1_csv_file.save
        # clean out the session variables
        session[:error_id] = nil
        session[:header_errors] = nil
        session[:error_line] = nil
      else
        session[:type] = 'edit'
        flash[:notice] = 'The update of the batch was successful'
        @current_page = session[:page]
        session[:page] = session[:initial_page]
      end
    when 'Relocate'
      proceed, message = Freereg1CsvFile.file_update_location(@freereg1_csv_file, params[:freereg1_csv_file], session)
      if proceed
        flash[:notice] = 'The relocation of the batch was successful'
      else
        flash[:notice] = message
        redirect_to(action: 'relocate') && return
      end
    end
    redirect_to session[:return_to]
  end

  def unique_names
    @freereg1_csv_file = Freereg1CsvFile.find(params[:object])
    unless Freereg1CsvFile.valid_freereg1_csv_file?(params[:object])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    controls(@freereg1_csv_file)
    @freereg1_csv_entries = @freereg1_csv_file.get_unique_names
  end

  def zero_year
    # get the entries with a zero year
    @freereg1_csv_file = Freereg1CsvFile.find(params[:id])
    unless Freereg1CsvFile.valid_freereg1_csv_file?(params[:id])
      message = 'The file was not correctly linked. Have your coordinator contact the web master'
      redirect_back(fallback_location: new_manage_resource_path, notice: message) && return
    end
    controls(@freereg1_csv_file)
    @freereg1_csv_entries = @freereg1_csv_file.zero_year_entries
    display_info

    @zero_year = true
    render 'freereg1_csv_entries/index'
  end

  private

  def freereg1_csv_file_params
    params.require(:freereg1_csv_file).permit!
  end

  def display_info
    @freereg1_csv_file_id = @freereg1_csv_file.id
    @freereg1_csv_file_name = @freereg1_csv_file.file_name
    @file_owner = @freereg1_csv_file.userid
    @register = @freereg1_csv_file.register
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
