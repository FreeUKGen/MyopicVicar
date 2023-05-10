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
class ManageCountiesController < ApplicationController
  require 'freecen_constants'

  def batches_with_errors
    get_user_info_from_userid
    @county = session[:county]
    @who = @user.person_forename
    @sorted_by = '; sorted by descending number of errors and then file name'
    session[:sorted_by] = @sorted_by
    session[:sort] = 'error DESC, file_name ASC'
    session[:selection] = 'errors'
    case appname_downcase
    when 'freereg'
      redirect_to freereg1_csv_files_path
    when 'freecen'
      redirect_to freecen_csv_files_path
    end
  end

  def being_validated
    get_user_info_from_userid
    @county = session[:county]
    @who = @user.person_forename
    @sorted_by = '; being validated'
    session[:sorted_by] = @sorted_by
    session[:sort] = 'file_name ASC'
    session[:selection] = 'validation'
    case appname_downcase
    when 'freereg'
      redirect_to freereg1_csv_files_path
    when 'freecen'
      redirect_to freecen_csv_files_path
    end
  end

  def county_content_report
    # not yet implemented for CEN
    get_user_info_from_userid
    userid = @user.userid
    chapman_code = session[:chapman_code]
    pid1 = Kernel.spawn("bundle exec rake reports:report_on_files_for_each_register_church_place[#{chapman_code},#{userid}] --trace")

    Process.detach pid1
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Request submitted') && return
  end

  def create
    redirect_back(fallback_location: new_manage_resource_path, notice: 'You did not selected anything') && return if params[:manage_county].blank? || params[:manage_county][:chapman_code].blank?

    session[:chapman_code] = params[:manage_county][:chapman_code]
    @county = ChapmanCode.has_key(session[:chapman_code])
    session[:county] = @county
    redirect_to(action: 'select_action') && return
  end

  def display_by_ascending_uploaded_date
    get_user_info_from_userid
    @county = session[:county]
    @who = @user.person_forename
    @sorted_by = '; sorted by ascending date of uploading'
    session[:sorted_by] = @sorted_by
    session[:sort] = 'uploaded_date ASC'
    case appname_downcase
    when 'freereg'
      redirect_to freereg1_csv_files_path
    when 'freecen'
      redirect_to freecen_csv_files_path
    end
  end

  def display_by_descending_uploaded_date
    get_user_info_from_userid
    @county = session[:county]
    @who = @user.person_forename
    @sorted_by = '; sorted by descending date of uploading'
    session[:sorted_by] = @sorted_by
    session[:sort] = 'uploaded_date DESC'
    case appname_downcase
    when 'freereg'
      redirect_to freereg1_csv_files_path
    when 'freecen'
      redirect_to freecen_csv_files_path
    end
  end

  def display_by_filename
    get_user_info_from_userid
    @county = session[:county]
    @who = @user.person_forename
    @sorted_by = '; sorted alphabetically by file name'
    session[:sorted_by] = @sorted_by
    session[:sort] = 'file_name ASC'
    session[:selection] = 'all'
    case appname_downcase
    when 'freereg'
      redirect_to freereg1_csv_files_path
    when 'freecen'
      redirect_to freecen_csv_files_path
    end
  end

  def display_by_userid_filename
    get_user_info_from_userid
    @county = session[:county]
    @who = @user.person_forename
    @sorted_by = '; sorted by userid then alphabetically by file name'
    session[:sorted_by] = @sorted_by
    session[:sort] = 'userid_lower_case ASC, file_name ASC'
    session[:selection] = 'all'
    case appname_downcase
    when 'freereg'
      redirect_to freereg1_csv_files_path
    when 'freecen'
      redirect_to freecen_csv_files_path
    end
  end

  def display_by_zero_date
    # not applicable for CEN
    get_user_info_from_userid
    @county = session[:county]
    session[:zero_action] = 'Main County Action'
    @who = @user.person_forename
    @sorted_by = '; selects files with zero date records then alphabetically by userid and file name'
    session[:sorted_by] = @sorted_by
    session[:sort] = 'userid_lower_case ASC, file_name ASC'
    session[:selection] = 'zero'
    @freereg1_csv_files = Freereg1CsvFile.county(session[:chapman_code]).datemin('0').no_timeout.order_by(session[:sort])
    render 'freereg1_csv_files/index'
  end

  def files
    get_user_info_from_userid
    @county = session[:county]
    case appname_downcase
    when 'freereg'
      @freereg1_csv_files = Freereg1CsvFile.where(county: session[:chapman_code], file_name: params[:params]).all
      if @freereg1_csv_files.length == 1
        file = Freereg1CsvFile.where(county: session[:chapman_code], file_name: params[:params]).first
        redirect_to(freereg1_csv_file_path(file)) && return
      else
        redirect_to(freereg1_csv_files_path) && return
      end
    when 'freecen'
      @freecen_csv_files = FreecenCsvFile.where(county: session[:chapman_code], file_name: params[:params]).all
      if @freecen_csv_files.length == 1
        file = FreecenCsvFile.where(county: session[:chapman_code], file_name: params[:params]).first
        redirect_to(freecen_csv_files_path(file)) && return
      else
        redirect_to(freecen_csv_files_path) && return
      end
    end
  end

  def get_counties_for_selection
    @counties = @user.county_groups
    @countries = @user.country_groups
    if %w[volunteer_coordinator contacts_coordinator data_manager master_county_coordinator system_administrator documentation_coordinator SNDManager
          CENManager REGManager country_coordinator executive_director project_manager].include?(@user.person_role)
      @countries = []
      counties = County.application_counties
      counties.each do |county|
        @countries << county.chapman_code
      end
    end
    if @countries.present?
      @counties = [] if @counties.blank?
      @countries.each do |county|
        @counties << county if @counties.blank?
        @counties << county unless @counties.include?(county)
      end
    end
    @counties = @counties.compact if @counties.present?
    @counties.sort! if @counties.present?
  end

  def incorporated
    get_user_info_from_userid
    @county = session[:county]
    @who = @user.person_forename
    @sorted_by = '; incorporated'
    session[:sorted_by] = @sorted_by
    session[:sort] = 'file_name ASC'
    session[:selection] = 'incorporated'
    case appname_downcase
    when 'freereg'
      redirect_to freereg1_csv_files_path
    when 'freecen'
      redirect_to freecen_csv_files_path
    end
  end

  def index
    redirect_to action: 'new'
  end

  def manage_completion_submitted_image_group
    # not applicable for CEN
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Your other actions cleared the county information, please select county again') && return if session[:chapman_code].blank?

    get_user_info_from_userid
    session.delete(:from_source)
    session[:image_group_filter] = 'completion_submitted'
    @source, @group_ids, @group_id = ImageServerGroup.group_ids_sort_by_place(session[:chapman_code], 'completion_submitted')            # not sort by place, unallocated groups
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No Allocate Request Image Groups exists') && return if @source.blank? || @group_ids.blank? || @group_id.blank?

    @county = session[:county]
    # for 'Accept All Groups As Completed'
    @completed_groups = []
    @group_ids.each {|x| @completed_groups << x[0]}
    @dummy = @completed_groups[0]
    render 'image_server_group_completion_submitted'
  end

  def manage_image_group
    # not applicable for CEN
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Your other actions cleared the county information, please select county again') && return if session[:chapman_code].blank?

    get_user_info_from_userid
    clean_session_for_managed_images
    session[:image_group_filter] = 'all'
    @source, @group_ids, @group_id = ImageServerGroup.group_ids_sort_by_place(session[:chapman_code])                   # not sort by place, all groups
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No Allocate Request Image Groups exists') && return if @source.blank? || @group_ids.blank? || @group_id.blank?

    @county = session[:county]
    render 'image_server_group_all'
  end

  def manage_unallocated_image_group
    # not applicable for CEN
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Your other actions cleared the county information, please select county again') && return if session[:chapman_code].blank?

    get_user_info_from_userid
    session.delete(:from_source)
    session[:image_group_filter] = 'unallocate'
    @source, @group_ids, @group_id = ImageServerGroup.group_ids_sort_by_place(session[:chapman_code], 'unallocate')            # not sort by place, unallocated groups
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No Allocate Request Image Groups exists') && return if @source.blank? || @group_ids.blank? || @group_id.blank?

    @county = session[:county]
    render 'image_server_group_unallocate'
  end

  def manage_allocate_request_image_group
    # not applicable for CEN
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Your other actions cleared the county information, please select county again') && return if session[:chapman_code].blank?

    get_user_info_from_userid
    session.delete(:from_source)
    session[:image_group_filter] = 'allocate request'
    @source, @group_ids, @group_id = ImageServerGroup.group_ids_sort_by_place(session[:chapman_code], 'allocate request')            # not sort by place, unallocated groups
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No Allocate Request Image Groups exists') && return if @source.blank? || @group_ids.blank? || @group_id.blank?

    @county = session[:county]
    render 'image_server_group_allocate_request'
  end

  def manage_sources
    # not applicable for CEN
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Your other actions cleared the county information, please select county again') && return if session[:chapman_code].blank?

    get_user_info_from_userid
    clean_session_for_images
    session[:manage_user_origin] = 'manage county'
    @source_ids, @source_id = Source.get_source_ids(session[:chapman_code])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No Sources exist') && return if @source_ids.blank? || @source_id.blank?

    @county = session[:county]
    render 'sources_list_all'
  end

  def new
    # get county to be used
    clean_session_for_county
    clean_session_for_images
    session.delete(:county)
    session.delete(:chapman_code)
    session.delete(:stats_year)
    session[:manage_user_origin] = 'manage county'
    get_user_info_from_userid
    get_counties_for_selection
    number_of_counties = 0
    number_of_counties = @counties.length if @counties.present?
    redirect_back(fallback_location: new_manage_resource_path, notice: 'You do not have any counties to manage') && return if number_of_counties.zero?

    if number_of_counties == 1
      session[:chapman_code] = @counties[0]
      @county = ChapmanCode.has_key(@counties[0])
      session[:county] = @county
      redirect_to(action: 'select_action') && return
    else
      @options = @counties
      @prompt = 'Please select one'
      @manage_county = ManageCounty.new
      @location = 'location.href= "/manage_counties/" + this.value +/selected/'
    end
  end

  def offline_reports
    # not available for CEN
    get_user_info_from_userid
    @chapman_code = session[:chapman_code]
    @county = session[:county]
  end

  def place_range
    session[:character] = params[:params] if params[:params].present?
    redirect_back(fallback_location: new_manage_resource_path, notice: 'You did not make a range selection') && return if session[:character].blank?

    @character = session[:character]
    @county = session[:county]
    get_user_info_from_userid
    @active = session[:active_place]
    if session[:active_place]
      @all_places = Place.chapman_code(session[:chapman_code]).not_disabled.data_present.all.order_by(place_name: 1)
    else
      @all_places = Place.chapman_code(session[:chapman_code]).not_disabled.all.order_by(place_name: 1)
    end
    @places = []
    @all_places.each do |place|
      @places << place if place.place_name =~ ::Regexp.new(/^[#{@character}]/)
    end
    # TODO at some point consider place/churches/registers hash
  end

  def places
    get_user_info_from_userid
    @county = session[:county]
    session.delete(:search_names)
    @places = Place.where(chapman_code: session[:chapman_code], place_name: params[:params], disabled: 'false').all
    if @places.length == 1
      place = Place.where(chapman_code: session[:chapman_code], place_name: params[:params], disabled: 'false').first
      redirect_to(place_path(place)) && return
    else
      render 'places/index'
    end
  end

  def places_with_unapproved_names
    get_user_info_from_userid
    session[:select_place] = true
    @manage_county = ManageCounty.new
    @county = session[:county]
    session.delete(:search_names)
    @places = []
    Place.where(chapman_code: session[:chapman_code], disabled: 'false', error_flag: 'Place name is not approved').order_by(place_name: 1).each do |place|
      @places << place.place_name
    end
    redirect_back(fallback_location: new_manage_resource_path, notice: 'There are no such places') && return if @places.blank?

    @options = @places
    @location = 'location.href= "/manage_counties/places?params=" + this.value'
    @prompt = 'Select Place'
    render '_form_for_selection'
  end

  def review_a_specific_batch
    get_user_info_from_userid
    @manage_county = ManageCounty.new
    @county = session[:county]
    session.delete(:search_names)
    @files = {}
    case appname_downcase
    when 'freereg'
      Freereg1CsvFile.county(session[:chapman_code]).order_by(file_name: 1).each do |file|
        @files["#{file.file_name}:#{file.userid}"] = file._id if file.file_name.present?
      end
      @location = 'location.href= "/freereg1_csv_files/" + this.value'
    when 'freecen'
      FreecenCsvFile.chapman_code(session[:chapman_code]).order_by(file_name: 1).each do |file|
        @files["#{file.file_name}:#{file.userid}"] = file._id if file.file_name.present?
      end
      @location = 'location.href= "/freecen_csv_files/" + this.value'
    end
    @options = @files
    @prompt = 'Select batch'
    render '_form_for_selection'
  end

  def selected
    session[:chapman_code] = params[:id]
    @county = ChapmanCode.has_key(session[:chapman_code])
    session[:county] = @county
    redirect_to action: 'select_action'
  end

  def selection
    redirect_to action: 'new'
  end

  def select_action
    clean_session_for_county
    get_user_info_from_userid
    @county = session[:county]
    @manage_county = ManageCounty.new
    @options = UseridRole::COUNTY_MANAGEMENT_OPTIONS
    @prompt = 'Select Action?'
  end

  def show
    redirect_to action: 'new'
  end

  def sort_image_group_by_place
    # not applicable for CEN
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Your other actions cleared the county information, please select county again') && return if session[:chapman_code].blank?

    get_user_info_from_userid
    session.delete(:from_source)
    session[:image_group_filter] = 'place'
    @source, @group_ids, @group_id = ImageServerGroup.group_ids_sort_by_place(session[:chapman_code], 'all')       # sort by place, all groups
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No requested Sources exists') && return if @source_ids.blank? || @source_id.blank? || @group_id.blank?

    @county = session[:county]
    render 'image_server_group_by_place'
  end

  def sort_image_group_by_syndicate
    # not applicable for CEN
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Your other actions cleared the county information, please select county again') && return if session[:chapman_code].blank?

    get_user_info_from_userid
    session.delete(:from_source)
    session[:image_group_filter] = 'syndicate'
    @county = session[:county]
    @source, @group_ids, @syndicate = ImageServerGroup.group_ids_sort_by_syndicate(session[:chapman_code])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No Image Groups Allocated by Syndicate for County ' + @county) && return if @source_ids.blank? || @source_id.blank? || @group_id.blank?

    render 'image_server_group_by_syndicate'
  end

  def uninitialized_source_list
    # not applicable for CEN
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Your other actions cleared the county information, please select county again') && return if session[:chapman_code].blank?

    get_user_info_from_userid
    session.delete(:from_source)
    session[:image_group_filter] = 'uninitialized'
    @source_ids, @source_id = Source.get_unitialized_source_list(session[:chapman_code])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'No Uninitialized Sources') && return if @source_ids.blank?

    @county = session[:county]
    render 'uninitialized_source_list'
  end

  def upload_batch
    redirect_to new_csvfile_path
  end

  def work_all_places
    get_user_info_from_userid
    session[:active_place] = false
    work_places_core
  end

  def work_places_core
    show_alphabet = ManageCounty.records(session[:chapman_code], session[:show_alphabet])
    redirect_to(places_path) && return if show_alphabet.zero?

    session[:show_alphabet] = show_alphabet
    @active = session[:active_place]
    @manage_county = ManageCounty.new
    @county = session[:county]
    session[:show_alphabet] = show_alphabet
    @options = FreeregOptionsConstants::ALPHABETS[show_alphabet]
    @location = 'location.href= "/manage_counties/place_range?params=" + this.value'
    @prompt = 'Select Place Range'
    render '_form_for_range_selection'
  end

  def work_with_active_places
    get_user_info_from_userid
    session[:active_place] = true
    work_places_core
  end

  def work_with_specific_place
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Your other actions cleared the county information, please select county again') && return if session[:chapman_code].blank?

    get_user_info_from_userid
    session[:select_place] = true
    @manage_county = ManageCounty.new
    @county = session[:county]
    @places = []
    Place.where(chapman_code: session[:chapman_code], disabled: 'false').order_by(place_name: 1).each do |place|
      @places << place.place_name
    end
    @options = @places
    @location = 'location.href= "/manage_counties/places?params=" + this.value'
    @prompt = 'Select Place'
    render '_form_for_selection'
  end

  def select_year
    # not applicable for REG
    @manage_county = ManageCounty.new
    @county = session[:county]
    @chapman_code = session[:chapman_code]
    @rec_types = Freecen::CENSUS_YEARS_ARRAY
    @options = @rec_types
    @location = 'location.href= "/manage_counties/piece_statistics?params=" + this.value'
    @prompt = 'Select Year'
    render '_form_for_selection'
  end

  def piece_statistics
    # not applicable for REG
    @chapman_code = session[:chapman_code]
    @rec_type = params[:params]
    @freecen_piece = FreecenPiece.where(chapman_code: @chapman_code, year: @rec_type)
  end
end
