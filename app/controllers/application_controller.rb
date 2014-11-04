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

 require 'record_type'
 require 'name_role'
 require 'chapman_code'
 require 'userid_role'
 require 'register_type'
 def clean_session
  session[:freereg1_csv_file_id] = nil
  session[:freereg1_csv_file_name] = nil
  session[:county] = nil
  session[:place_name] = nil
  session[:church_name] = nil
  session[:sort] = nil  
  session[:csvfile] = nil
  session[:my_own] = nil
  session[:role] = nil
  session[:freereg] = nil
  session[:edit] = nil
  
end

private

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
   if @user.person_role == 'system_administrator' || (@user.person_role == 'technical' && @user.active)
    respond_to?(home_path, true) ? refinery.send(home_path) : refinery.admin_root_path
  else
    respond_to?(home_path, true) ? refinery.send(home_path) : main_app.manage_resources_path
  end
end
def  get_user_info(userid,name)
  @userid = userid
  @first_name = name
  @user = UseridDetail.where(:userid => @userid).first
end
def manager?(user)
  #sets the manager flag status
  a = false
  a = true if (user.person_role == 'technical' || user.person_role == 'system_administrator' || user.person_role == 'country_coordinator'  || user.person_role == 'county_coordinator'  || user.person_role == 'volunteer_coordinator' || user.person_role == 'syndicate_coordinator')
end


end