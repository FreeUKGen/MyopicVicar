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

  protect_from_forgery
  before_filter :require_login
  before_filter :require_cookie_directive
  before_filter :load_last_stat

  require 'record_type'
  require 'name_role'
  require 'chapman_code'
  require 'userid_role'
  require 'register_type'


  def load_last_stat
    @site_stat = SiteStatistic.last
  end

  private

  def check_for_mobile
    session[:mobile_override] = true if mobile_device?
  end

  def require_cookie_directive
    if cookies[:cookiesDirective].blank?
      flash[:notice] = 'This website only works if you are willing to accept cookies. If you did not see the cookie declaration you are likely using an obsolete browser and this website will not function'
      redirect_to main_app.new_search_query_path
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

  def require_login
    if session[:userid].nil?
      flash[:error] = "You must be logged in to access this section"
      redirect_to refinery.login_path # halts request cycle
    end
  end

  def after_sign_in_path_for(resource_or_scope)
    cookies.signed[:Administrator] = Rails.application.config.github_issues_password
    session[:userid_detail_id] = current_authentication_devise_user.userid_detail_id
    #logger.warn("APP: current_refinery_user #{current_refinery_user}")
    #logger.warn("APP: current_refinery_user.userid_detail #{current_refinery_user.userid_detail.id}") unless current_refinery_user.nil? || current_refinery_user.userid_detail.nil?
    scope = Devise::Mapping.find_scope!(resource_or_scope)
    home_path = "#{scope}_root_path"
    respond_to?(home_path, true) ? refinery.send(home_path) : main_app.new_manage_resource_path
  end
  def get_place_id_from_file(freereg1_csv_file)
    register = freereg1_csv_file.register
    church = register.church
    place = church.place
    return place.id
  end
  def get_userid_from_current_authentication_devise_user
    if session[:userid_detail_id].present?
      @user = UseridDetail.id(session[:userid_detail_id]).first
    else
      if current_authentication_devise_user.blank?
        flash[:notice] = 'You are not logged into the system'
        redirect_to refinery.login_path
        return
      else
        @user = UseridDetail.find(current_authentication_devise_user.userid_detail_id)
      end
    end
    @user_id = @user._id
    @userid = @user.userid
    @first_name = @user.person_forename
    @manager = manager?(@user)
    @roles = UseridRole::OPTIONS.fetch(@user.person_role)
    u = Refinery::Authentication::Devise::User.where(:username => @user.userid).first
    session[:userid] = @userid
    session[:user_id] = @user_id
    session[:first_name] = @first_name
    session[:manager] = manager?(@user)
    session[:role] = @user.person_role

  end

  def get_user_info_from_userid
    @userid = session[:userid]
    @user_id = session[:user_id]
    @first_name = session[:first_name]
    @manager = session[:manager]
    @roles = session[:role]
    @user = UseridDetail.where(:userid => session[:userid]).first
    @roles = UseridRole::OPTIONS.fetch(session[:role])
  end

  def  get_user_info(userid,name)
    #old version for compatibility
    @userid = userid
    @user = UseridDetail.where(:userid => @userid).first
    @first_name = @user.person_forename
    @roles = UseridRole::OPTIONS.fetch(@user.person_role)
  end

  def manager?(user)
    #sets the manager flag status
    a = true
    a = false if (user.person_role == 'transcriber' || user.person_role == 'researcher' || user.person_role == 'data_manager' || user.person_role == 'technical')
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

  def log_messenger(message)
    log_message = message
    logger.warn(log_message)
  end

  def get_places_for_menu_selection
    placenames =  Place.where(:chapman_code => session[:chapman_code],:disabled => 'false',:error_flag.ne => "Place name is not approved").all.order_by(place_name: 1)
    @placenames = Array.new
    placenames.each do |placename|
      @placenames << placename.place_name
    end
  end

  def clean_session
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

  def go_back(type,record)
    flash[:notice] = "The #{type} document you are trying to access does not exist."
    logger.info "FREEREG:ACCESS ISSUE: The #{type} document #{record} being accessed does not exist."
    redirect_to main_app.new_manage_resource_path
    return
  end
  def reject_assess(user,action)
    flash[:notice] = "You are not permitted to use this action"
    logger.info "FREEREG:ACCESS ISSUE: The #{user} attempted to access #{action}."
    redirect_to main_app.new_manage_resource_path
    return
  end

end
