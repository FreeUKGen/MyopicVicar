
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

  protect_from_forgery :with => :reset_session
  before_filter :require_login
  #before_filter :require_cookie_directive
  before_filter :load_last_stat
  before_filter :load_message_flag
  require 'record_type'
  require 'name_role'
  require 'chapman_code'
  require 'userid_role'
  require 'register_type'

  def load_last_stat
    if session[:site_stats].blank?
      time = Time.now
      last_midnight = Time.new(time.year,time.month,time.day)
      #last_midnight = Time.new(2015,10,13)
      @site_stat = SiteStatistic.collection.find({:interval_end => last_midnight}, { 'projection' => { :interval_end => 0, :year => 0, :month => 0, :day => 0, "_id" => 0  }}).first
      if  @site_stat.blank?
        time =  1.day.ago
        last_midnight = Time.new(time.year,time.month,time.day)
        @site_stat = SiteStatistic.collection.find({:interval_end => last_midnight}, { 'projection' => { :interval_end => 0, :year => 0, :month => 0, :day => 0, "_id" => 0  }}).first
      end
      session[:site_stats] = @site_stat
    else
      @site_stat = session[:site_stats]
    end
    @site_stat
  end

  def load_message_flag
    # This tells system there is a message to display
    if session[:message].blank?
      session[:message] = "no"
      session[:message]  = "load" if Refinery::Page.where(:slug => 'message').exists?
    end
  end

  private

  def after_sign_in_path_for(resource_or_scope)
    #empty current session
    cookies.signed[:Administrator] = Rails.application.config.github_issues_password
    cookies.signed[:userid] = current_authentication_devise_user.userid_detail_id
    session[:userid_detail_id] = current_authentication_devise_user.userid_detail_id
    session[:devise] = current_authentication_devise_user.id
    logger.warn "FREEREG::USER current  #{current_authentication_devise_user.userid_detail_id}"
    scope = Devise::Mapping.find_scope!(resource_or_scope)
    home_path = "#{scope}_root_path"
    respond_to?(home_path, true) ? refinery.send(home_path) : main_app.new_manage_resource_path
  end

  def check_for_mobile
    session[:mobile_override] = true if mobile_device?
  end

  def get_max_records(user)
    max_records = FreeregOptionsConstants::MAX_RECORDS_COORDINATOR
    max_records = FreeregOptionsConstants::MAX_RECORDS_DATA_MANAGER if user.person_role == "data_manager"
    max_records = FreeregOptionsConstants::MAX_RECORDS_SYSTEM_ADMINISTRATOR if  user.person_role == "system_administrator"
    max_records
  end

  def get_place_from_file(freereg1_csv_file)
    register = freereg1_csv_file.register
    church = register.church
    place = church.place
    return place
  end

  def get_location_from_file(freereg1_csv_file)
    register = freereg1_csv_file.register
    church = register.church
    place = church.place
    return place, church, register

  end

  def get_places_for_menu_selection
    placenames =  Place.where(:chapman_code => session[:chapman_code],:disabled => 'false',:error_flag.ne => "Place name is not approved").all.order_by(place_name: 1)
    @placenames = Array.new
    placenames.each do |placename|
      @placenames << placename.place_name
    end
  end

  def get_user
    user = cookies.signed[:userid]
    user = UseridDetail.id(user).first
    return user
  end

  def get_user_info_from_userid
    @user = get_user
    unless @user.present?
      flash[:notice] = "You must be logged in to access that action"
      redirect_to new_search_query_path # halts request cycle
    else
      @user_id = @user.id
      @userid = @user.id
      @user_userid = @user.userid
      @first_name = @user.person_forename
      @manager = manager?(@user)
      @roles = UseridRole::OPTIONS.fetch(@user.person_role)
    end
  end

  def  get_user_info(userid,name)
    #old version for compatibility
    @user = get_user
    @first_name = @user.person_forename unless @user.blank?
    @userid = @user.id
    @roles = UseridRole::OPTIONS.fetch(@user.person_role)
  end

  def get_userids_and_transcribers
    @user = get_user
    @userids = UseridDetail.all.order_by(userid_lower_case: 1)
  end

  def go_back(type,record)
    flash[:notice] = "The #{type} document you are trying to access does not exist."
    logger.info "FREEREG:ACCESS ISSUE: The #{type} document #{record} being accessed does not exist."
    redirect_to main_app.new_manage_resource_path and return
  end

  def log_messenger(message)
    log_message = message
    logger.warn(log_message)
  end

  def log_missing_document(message,doc1,doc2)
    log_message = "FREEREG:PHC WARNING: aunable to find a document #{message}\n"
    log_message += "FREEREG:PHC Time.now=\t\t#{Time.now}\n"
    log_message += "FREEREG:PHC #{doc1}\n" if doc1.present?
    log_message += "FREEREG:PHC #{doc2}\n" if doc2.present?
    log_message += "FREEREG:PHC caller=\t\t#{caller.first}\n"
    log_message += "FREEREG:PHC REMOTE_ADDR=\t#{request.env['REMOTE_ADDR']}\n"
    log_message += "FREEREG:PHC REMOTE_HOST=\t#{request.env['REMOTE_HOST']}\n"
    log_message += "FREEREG:PHC HTTP_USER_AGENT=\t#{request.env['HTTP_USER_AGENT']}\n"
    log_message += "FREEREG:PHC REQUEST_URI=\t#{request.env['REQUEST_URI']}\n"
    log_message += "FREEREG:PHC REQUEST_PATH=\t#{request.env['REQUEST_PATH']}\n"

    logger.warn(log_message)
  end

  def log_possible_host_change
    log_message = "FREEREG:PHC WARNING: browser may have jumped across servers mid-session!\n"
    log_message += "FREEREG:PHC Time.now=\t\t#{Time.now}\n"
    log_message += "FREEREG:PHC params=\t\t#{params}\n"
    log_message += "FREEREG:PHC caller=\t\t#{caller.first}\n"
    log_message += "FREEREG:PHC REMOTE_ADDR=\t#{request.env['REMOTE_ADDR']}\n"
    log_message += "FREEREG:PHC REMOTE_HOST=\t#{request.env['REMOTE_HOST']}\n"
    log_message += "FREEREG:PHC HTTP_USER_AGENT=\t#{request.env['HTTP_USER_AGENT']}\n"
    log_message += "FREEREG:PHC REQUEST_URI=\t#{request.env['REQUEST_URI']}\n"
    log_message += "FREEREG:PHC REQUEST_PATH=\t#{request.env['REQUEST_PATH']}\n"

    logger.warn(log_message)
  end

  def manager?(user)
    #sets the manager flag status
    a = true
    a = false if (user.person_role == 'transcriber' || user.person_role == 'researcher' ||  user.person_role == 'technical')
    return a
  end

  def reject_assess(user,action)
    flash[:notice] = "You are not permitted to use this action"
    logger.info "FREEREG:ACCESS ISSUE: The #{user} attempted to access #{action}."
    redirect_to main_app.new_manage_resource_path
    return
  end

  def require_cookie_directive
    #p "cookie"
    if cookies[:cookiesDirective].blank?
      flash[:notice] = 'This website only works if you are willing to explicitly accept cookies. If you did not see the cookie declaration you could be using an obsolete browser or a browser add on that blocks cookie messages'
      redirect_to main_app.new_search_query_path
    end
  end

  def require_login
    if session[:userid_detail_id].nil?
      flash[:notice] = "You must be logged in to access that action"
      redirect_to new_search_query_path  # halts request cycle
    end
  end


  helper_method :mobile_device?
  def mobile_device?
    # Season this regexp to taste. I prefer to treat iPad as non-mobile.
    request.user_agent =~ /Mobile|webOS/ && request.user_agent !~ /iPad/
  end

  helper_method :device_type
  def device_type
    request.env['mobvious.device_type']
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
    session.delete(:redirect_to)
    session.delete(:site_stats)
    session.delete(:message)
    session.delete(:message_base)
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
    session.delete(:syndicate)
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
  end

end
