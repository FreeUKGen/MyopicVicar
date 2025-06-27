
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
# limitations under the License.
#

class ApplicationController < ActionController::Base
  rescue_from ActionController::UnknownFormat, with: :missing_template
  protect_from_forgery :with => :reset_session, prepend: true
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :require_login
  before_action :load_last_stat
  before_action :load_message_flag
  require 'record_type'
  require 'name_role'
  require 'chapman_code'
  require 'userid_role'
  require 'register_type'
  require 'quarter_details'
  require 'freebmd_data_problem'
  require 'constant'
  require 'gdpr_countries'
  require 'application_text'
  helper_method :appname, :appname_upcase, :appname_downcase, :mobile_device?, :device_type
  def appname
    MyopicVicar::Application.config.freexxx_display_name
  end

  def appname_upcase
    appname.upcase
  end

  def appname_downcase
    appname.downcase
  end

  def load_last_stat
    if session[:site_stats].blank?
      case appname.downcase
      when 'freereg'
        time = Time.now
        last_midnight = Time.new(time.year, time.month, time.day)
        @site_stat = SiteStatistic.collection.find({ interval_end: last_midnight }, 'projection' => { interval_end: 0, year: 0, month: 0, day: 0, _id: 0 }).first
        if @site_stat.blank?
          time = 1.day.ago
          last_midnight = Time.new(time.year, time.month, time.day)
          @site_stat = SiteStatistic.collection.find({ interval_end: last_midnight }, 'projection' => { interval_end: 0, year: 0, month: 0, day: 0, _id: 0 }).first
        end
        session[:site_stats] = @site_stat
      when 'freecen'
        site_stat = Freecen2SiteStatistic.order_by(interval_end: -1).first
        session[:site_stats] = {}
        session[:site_stats][:searches] = site_stat.present? ? site_stat.searches : 0
        session[:site_stats][:records] = site_stat.present? ? site_stat.records[:total][:total][:search_records] : 0
        session[:site_stats][:added] = site_stat.present? && site_stat.records[:total][:total][:added_vld_entries].present? &&
          site_stat.records[:total][:total][:added_csv_individuals_incorporated].present? ? (site_stat.records[:total][:total][:added_vld_entries] +
                                                                                             site_stat.records[:total][:total][:added_csv_individuals_incorporated]) : 0
        @site_stat = session[:site_stats]
      when 'freebmd'
        database_name = FREEBMD_DB["database"]
        @site_stat = RecordStatistic.where(database_name: database_name)
        today = Time.now
        last_month = today - 1.month
        end_date = Time.now.beginning_of_month
        start_date = last_month.beginning_of_month
        @search_count = SearchQuery.where(c_at: start_date..end_date).count
      end
    else
      @site_stat = session[:site_stats]
    end
    @site_stat
  end

  def load_message_flag
    # This tells system there is a message to display
      session[:message] = 'no' if session[:message].blank?
      session[:message] = 'load' if Refinery::Page.present? && Refinery::Page.where(slug: 'message').exists?
  end

  private

  def after_sign_in_path_for(resource_or_scope)
    cookies.signed[:Administrator] = Rails.application.config.github_issues_password
    cookies.signed[:userid] = current_authentication_devise_user.userid_detail_id
    session[:userid_detail_id] = current_authentication_devise_user.userid_detail_id
    session[:devise] = current_authentication_devise_user.id
    logger.warn "#{appname_upcase}::USER current  #{current_authentication_devise_user.username}"
    scope = Devise::Mapping.find_scope!(resource_or_scope)
    home_path = "#{scope}_root_path"
    respond_to?(home_path, true) ? refinery.send(home_path) : main_app.new_manage_resource_path
  end

  def check_for_mobile
    session[:mobile_override] = true if mobile_device?
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in) do |user_params|
      user_params.permit(:login, :userid_detail_id, :reset_password_token, :reset_password_sent_at, :username, :password, :email)
    end
    devise_parameter_sanitizer.permit(:account_update) do |user_params|
      user_params.permit(:login, :userid_detail_id, :reset_password_token, :reset_password_sent_at, :username, :password, :email)
    end
    devise_parameter_sanitizer.permit(:sign_up) do |user_params|
      user_params.permit(:login, :userid_detail_id, :reset_password_token, :reset_password_sent_at, :username, :password, :email)
    end
  end

  def get_location_from_file(freereg1_csv_file)
    register = freereg1_csv_file.register
    church = register.church
    place = church.place
    [place, church, register]
  end

  def get_max_records(user)
    max_records = FreeregOptionsConstants::MAX_RECORDS_COORDINATOR
    max_records = FreeregOptionsConstants::MAX_RECORDS_DATA_MANAGER if user.person_role == 'data_manager'
    max_records = FreeregOptionsConstants::MAX_RECORDS_SYSTEM_ADMINISTRATOR if user.person_role == 'system_administrator'
    max_records
  end

  def get_place_from_file(freereg1_csv_file)
    register = freereg1_csv_file.register
    church = register.church
    place = church.place
    place
  end

  def get_places_for_menu_selection
    placenames =  Place.where(chapman_code: session[:chapman_code], disabled: 'false', :error_flag.ne => 'Place name is not approved').all.order_by(place_name: 1)
    @placenames = []
    placenames.each do |placename|
      @placenames << placename.place_name
    end
  end

  def get_user
    user = cookies.signed[:userid]
    user = UseridDetail.id(user).first
    user
  end

  def get_user_info_from_userid
    @user = get_user
    if @user.blank?
      flash[:notice] = 'You must be logged in to access that action'
      redirect_to(new_search_query_path) && return # halts request cycle
    else
      @user_id = @user.id
      @userid = @user.id
      @user_userid = @user.userid
      @first_name = @user.person_forename
      @manager = manager?(@user)
      @roles = UseridRole::OPTIONS.fetch(@user.person_role)
    end
  end

  def get_user_info_if_present
    @user = get_user
    if @user.present?
      @user_id = @user.id
      @userid = @user.id
      @user_userid = @user.userid
      @first_name = @user.person_forename
      @last_name = @user.person_surname
      @manager = manager?(@user)
      @roles = UseridRole::OPTIONS.fetch(@user.person_role)
    end
  end

  def get_user_info(userid, name)
    # old version for compatibility
    @user = get_user
    @first_name = @user.person_forename if @user.present?
    @userid = @user.id
    @roles = UseridRole::OPTIONS.fetch(@user.person_role)
  end

  def get_userids_and_transcribers
    @user = get_user
    @userids = UseridDetail.all.order_by(userid_lower_case: 1)
  end

  def go_back(type, record)
    flash[:notice] = "The #{type} document you are trying to access does not exist."
    logger.info "#{appname_upcase}:ACCESS ISSUE: The #{type} document #{record} being accessed does not exist."
    redirect_to(main_app.new_manage_resource_path) && return
  end

  def log_messenger(message)
    log_message = message
    logger.warn(log_message)
  end

  def log_missing_document(message, doc1, doc2)
    log_message = "#{appname_upcase}:PHC WARNING: aunable to find a document #{message}\n"
    log_message += "#{appname_upcase}:PHC Time.now=\t\t#{Time.now}\n"
    log_message += "#{appname_upcase}:PHC #{doc1}\n" if doc1.present?
    log_message += "#{appname_upcase}:PHC #{doc2}\n" if doc2.present?
    log_message += "#{appname_upcase}:PHC caller=\t\t#{caller.first}\n"
    log_message += "#{appname_upcase}:PHC REMOTE_ADDR=\t#{request.env['REMOTE_ADDR']}\n"
    log_message += "#{appname_upcase}:PHC REMOTE_HOST=\t#{request.env['REMOTE_HOST']}\n"
    log_message += "#{appname_upcase}:PHC HTTP_USER_AGENT=\t#{request.env['HTTP_USER_AGENT']}\n"
    log_message += "#{appname_upcase}:PHC REQUEST_URI=\t#{request.env['REQUEST_URI']}\n"
    log_message += "#{appname_upcase}:PHC REQUEST_PATH=\t#{request.env['REQUEST_PATH']}\n"

    logger.warn(log_message)
  end

  def log_possible_host_change
    log_message = "#{appname_upcase}:PHC WARNING: browser may have jumped across servers mid-session!\n"
    log_message += "#{appname_upcase}:PHC Time.now=\t\t#{Time.now}\n"
    log_message += "#{appname_upcase}:PHC params=\t\t#{params}\n"
    log_message += "#{appname_upcase}:PHC caller=\t\t#{caller.first}\n"
    log_message += "#{appname_upcase}:PHC REMOTE_ADDR=\t#{request.env['REMOTE_ADDR']}\n"
    log_message += "#{appname_upcase}:PHC REMOTE_HOST=\t#{request.env['REMOTE_HOST']}\n"
    log_message += "#{appname_upcase}:PHC HTTP_USER_AGENT=\t#{request.env['HTTP_USER_AGENT']}\n"
    log_message += "#{appname_upcase}:PHC REQUEST_URI=\t#{request.env['REQUEST_URI']}\n"
    log_message += "#{appname_upcase}:PHC REQUEST_PATH=\t#{request.env['REQUEST_PATH']}\n"

    logger.warn(log_message)
  end

  def manager?(user)
    #sets the manager flag status
    a = true
    a = false if user.person_role == 'transcriber' || user.person_role == 'researcher' || user.person_role == 'technical'
    a
  end

  def missing_template
    logger.warn("#{appname_upcase}:We encountered an unsupported format #{params}")
    flash[:notice] = 'You requested the display of the page in an unsupported format'
    redirect_to new_search_query_path
  end

  def reject_access(user, action)
    flash[:notice] = 'You are not permitted to use this action'
    logger.info "#{appname_upcase}:ACCESS ISSUE: The #{user} attempted to access #{action}."
    redirect_to(main_app.new_manage_resource_path) && return
  end

  def require_login
    if session[:userid_detail_id].nil?
      flash[:notice] = "You must be logged in to access that action"
      redirect_to(new_search_query_path) && return  # halts request cycle
    end
  end

  def scotland_county?(chapman)
    codes = ChapmanCode.remove_codes(ChapmanCode::CODES)
    codes = codes["Scotland"].values
    result = codes.include?(chapman) ? true : false
    result
  end

  def device_type
    request.env['mobvious.device_type']
  end

  def mobile_device?
    # Season this regexp to taste. I prefer to treat iPad as non-mobile.
    request.user_agent =~ /Mobile|webOS/ && request.user_agent !~ /iPad/
  end

  def clean_session
    session.delete(:manage_user_origin)
    session.delete(:freereg1_csv_file_id)
    session.delete(:freereg1_csv_file_name)
    session.delete(:county)
    session.delete(:chapman_code)
    session.delete(:place_name)
    session.delete(:church_name)
    session.delete(:sort)
    session.delete(:csvfile)
    session[:my_own] = false
    session.delete(:freereg)
    session.delete(:edit)
    session.delete(:sorted_by)
    session.delete(:physical_index_page)
    session.delete(:character)
    session.delete(:edit_userid)
    session.delete(:who)
    session.delete(:edit_freecen_pieces)
    session.delete(:redirect_to)
    session.delete(:site_stats)
    session.delete(:message)
    session.delete(:message_base)
    session.delete(:syndicate)
    session.delete(:archived_contacts)
    session.delete(:message_id)
    session.delete(:original_message_id)
    session.delete(:query)
    session.delete(:search_names)
    session[:stats_view] = false
    session.delete(:stats_year)
    session.delete(:stats_todate)
    session.delete(:stats_recs)
    session.delete(:contents_id)
    session.delete(:contents_county_description)
    session.delete(:contents_place_description)
  end

  def clean_session_for_county
    session.delete(:freereg1_csv_file_id)
    session.delete(:freereg1_csv_file_name)
    session.delete(:place_name)
    session.delete(:church_name)
    session.delete(:sort)
    session.delete(:csvfile)
    session[:my_own] = false
    session.delete(:freereg)
    session.delete(:edit)
    session.delete(:sort)
    session.delete(:sorted_by)
    session.delete(:viewed)
    session.delete(:active_place)
    session.delete(:page)
    session.delete(:parameters)
    session.delete(:place_id)
    session.delete(:id)
    session.delete(:church_id)
    session.delete(:register_id)
    session.delete(:register_name)
    session.delete(:county_id)
    session.delete(:placeid)
    session.delete(:place)
    session.delete(:error_line)
    session.delete(:error_id)
    session.delete(:return_to)
    session.delete(:header_errors)
    session.delete(:type)
    session.delete(:place_index_page)
    session.delete(:entry_index_page)
    session.delete(:files_index_page)
    session.delete(:character)
    session.delete(:show_alphabet)
    session.delete(:edit_userid)
    session.delete(:record)
    session.delete(:current_page)
    session.delete(:edit_freecen_pieces)
    session.delete(:query)
    session.delete(:zero_action)
    session.delete(:place)
    session.delete(:church)
    session.delete(:register)
    session.delete(:search_names)
    session.delete(:type)
    session[:stats_view] = false
    session.delete(:stats_year)
    session.delete(:stats_todate)
    session.delete(:stats_recs)
  end

  def clean_session_for_images
    session.delete(:manage_user_origin)
    session.delete(:image_group_filter)
    session.delete(:source_id)
    session.delete(:my_own)
    session.delete(:image_server_group_id)
    session.delete(:assignment_filter_list)
    session.delete(:assignment_list_type)
    session.delete(:image_group_filter)
    session.delete(:from_source)
    session.delete(:list_user_assignments)
  end

  def clean_session_for_managed_images
    session.delete(:image_server_group_id)
    session.delete(:assignment_filter_list)
    session.delete(:assignment_list_type)
    session.delete(:image_group_filter)
    session.delete(:from_source)
    session.delete(:list_user_assignments)
  end

  def clean_session_for_syndicate
    session.delete(:freereg1_csv_file_id)
    session.delete(:freereg1_csv_file_name)
    session.delete(:place_name)
    session.delete(:church_name)
    session.delete(:sort)
    session.delete(:active)
    session.delete(:csvfile)
    session[:my_own] = false
    session.delete(:freereg)
    session.delete(:edit)
    session.delete(:sort)
    session.delete(:sorted_by)
    session.delete(:viewed)
    session.delete(:active_place)
    session.delete(:page)
    session.delete(:parameters)
    session.delete(:place_id)
    session.delete(:id)
    session.delete(:church_id)
    session.delete(:register_id)
    session.delete(:register_name)
    session.delete(:county_id)
    session.delete(:placeid)
    session.delete(:place)
    session.delete(:error_line)
    session.delete(:error_id)
    session.delete(:return_to)
    session.delete(:header_errors)
    session.delete(:type)
    session.delete(:userid_id)
    session.delete(:place_index_page)
    session.delete(:entry_index_page)
    session.delete(:files_index_page)
    session.delete(:user_index_page)
    session.delete(:character)
    session.delete(:show_alphabet)
    session.delete(:edit_userid)
    session.delete(:record)
    session.delete(:select_place)
    session.delete(:current_page)
    session.delete(:edit_freecen_pieces)
    session.delete(:query)
    session.delete(:zero_action)
    session.delete(:county)
    session.delete(:place)
    session.delete(:church)
    session.delete(:register)
    session.delete(:search_names)
  end
end
