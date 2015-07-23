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

  
  def mobile_device?
   # Season this regexp to taste. I prefer to treat iPad as non-mobile.
   request.user_agent =~ /Mobile|webOS/ && request.user_agent !~ /iPad/
  end

  helper_method :mobile_device?


  def require_login
    if session[:userid].nil?
      flash[:error] = "You must be logged in to access this section"
      redirect_to refinery.login_path # halts request cycle
    end
  end

  def after_sign_in_path_for(resource_or_scope)
    @user = current_refinery_user.userid_detail
    scope = Devise::Mapping.find_scope!(resource_or_scope)
    home_path = "#{scope}_root_path"
    respond_to?(home_path, true) ? refinery.send(home_path) : main_app.new_manage_resource_path
  end
  def  get_user_info_from_userid
     if session[:userid].nil?
        if current_refinery_user.nil?
          redirect_to refinery.login_path
          return
        else
          @user = current_refinery_user.userid_detail
        end
     else
       @user = UseridDetail.where(:userid => session[:userid]).first
     end
     @userid = @user._id
     @first_name = @user.person_forename
     @manager = manager?(@user)
     @roles = UseridRole::OPTIONS.fetch(@user.person_role)
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
    a = false
    a = true if (user.person_role == 'technical' || user.person_role == 'system_administrator' || user.person_role == 'country_coordinator'  || user.person_role == 'county_coordinator'  || user.person_role == 'volunteer_coordinator' || user.person_role == 'syndicate_coordinator')
  end


  def log_possible_host_change
    log_message = "PHC WARNING: browser may have jumped across servers mid-session!\n"
    log_message += "PHC Time.now=\t\t#{Time.now}\n"
    log_message += "PHC params=\t\t#{params}\n"
    log_message += "PHC caller=\t\t#{caller.first}\n"
    log_message += "PHC REMOTE_ADDR=\t#{request.env['REMOTE_ADDR']}\n"
    log_message += "PHC REMOTE_HOST=\t#{request.env['REMOTE_HOST']}\n"
    log_message += "PHC HTTP_USER_AGENT=\t#{request.env['HTTP_USER_AGENT']}\n"
    log_message += "PHC REQUEST_URI=\t#{request.env['REQUEST_URI']}\n"
    log_message += "PHC REQUEST_PATH=\t#{request.env['REQUEST_PATH']}\n"
    
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
    session.delete(:place_name) 
    session.delete(:church_name) 
    session.delete(:sort) 
    session.delete(:csvfile) 
    session[:my_own] = false
    session.delete(:freereg) 
    session.delete(:edit) 

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
    session.delete(:my_own_index_page)
    session.delete(:error_index_page)
    session.delete(:descending_index_page)
    session.delete(:acsending_index_page)

end
def clean_session_for_syndicate
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
  end
  
end
