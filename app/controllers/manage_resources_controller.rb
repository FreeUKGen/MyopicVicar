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
class ManageResourcesController < ApplicationController
  require "county"
  require 'userid_role'
  skip_before_action :require_login, only: [:logout]

  def create
    #@user = UseridDetail.where(:userid => params[:manage_resource][:userid] ).first
    session[:userid] = @user.userid
    session[:first_name] = @user.person_forename
    session[:manager] = manager?(@user)
    redirect_to manage_resource_path(@user)
  end

  def index
    redirect_to :new
  end

  def is_ok_to_render_actions?
    continue = true
    @user = get_user
    @user_roles = get_user_roles
    if @user.present?
      if @user.blank?
        logger.warn "FREEREG::USER userid not found in session #{session[:userid_detail_id]}" if appname_downcase == 'freereg'
        logger.warn "FREECEN::USER userid not found in session #{session[:userid_detail_id]}" if appname_downcase == 'freecen'
        flash[:notice] = 'Your userid was not found in the system (if you believe this to be a mistake please contact your coordinator)'
        continue = false
      end
    else
      logger.warn 'FREEREG::USER no userid cookie' if appname_downcase == 'freereg'
      logger.warn 'FREECEN::USER no userid cookie' if appname_downcase == 'freecen'
      flash[:notice] = 'We did not find your userid cookie. Do you have them disabled?'
      continue = false
    end
    case
    when @user.blank?
      continue = false
    when !@user.active
      flash[:notice] = 'You are not active, if you believe this to be a mistake please contact your coordinator'
      continue = false
    when @user.person_role == "researcher" || @user.person_role == 'pending'
      flash[:notice] = "You are not currently permitted to access the system as your functions are still under development"
      continue = false
    when !Rails.application.config.member_open && !(@user.person_role == "system_administrator" || @user.person_role == 'technical')
      #we set the mongo_config.yml member open flag. true is open. false is closed We do allow technical people in
      flash[:notice] = "The system is presently undergoing maintenance and is unavailable"
      continue = false
    end
    set_session if continue
    continue
  end

  def load(userid_id)
    @first_name = session[:first_name]
    @user = get_user
  end

  def logout
    @message = flash[:notice]
    cookies.delete :userid
    cookies.delete :remember_authentication_devise_user_token
    reset_session
  end

  def new
    session[:host] = request.host
    case
    when !is_ok_to_render_actions?
      stop_processing
    when @user.need_to_confirm_email_address?
      redirect_to '/userid_details/confirm_email_address'
    when user_is_computer?
      go_to_computer_code
    else
      clean_session
      clean_session_for_syndicate
      clean_session_for_county
      clean_session_for_images
      Refinery::Page.where(slug: 'transcriber-agreement-acceptance').exists? ?
        @acceptance = Refinery::Page.where(slug: 'transcriber-agreement-acceptance').first.parts.first.body.html_safe : @acceptance = ''
      Refinery::Page.where(slug: 'information-for-members').exists? ?
        @page = Refinery::Page.where(slug: 'information-for-members').first.parts.first.body.html_safe : @page = ''
      @manage_resources = ManageResource.new
      render 'actions'
    end
  end

  def pages
    current_authentication_devise_user = Refinery::Authentication::Devise::User.where(:id => session[:devise]).first
    redirect_to '/cms/refinery/pages'
  end

  def selection
    if UseridRole::OPTIONS_TRANSLATION.has_key?(params[:option])
      value = UseridRole::OPTIONS_TRANSLATION[params[:option]]
      redirect_to value
    else
      flash[:notice] = 'Invalid option'
      redirect_back fallback_location: { action: 'new' }
    end
  end

  def set_session
    @user_id = @user._id
    @userid = @user.userid
    @first_name = @user.person_forename if @user.present?
    @manager = manager?(@user)
    @roles = UseridRole::OPTIONS.fetch(@user.person_role)
    session[:userid] = @userid
    session[:user_id] = @user_id
    session[:first_name] = @first_name
    session[:manager] = manager?(@user)
    session[:role] = @user.person_role
    logger.warn "FREEREG::USER user #{@user.userid}"  if appname_downcase == 'freereg'
    logger.warn "FREECEN::USER user #{@user.userid}"  if appname_downcase == 'freecen'
  end

  def show
    load(params[:id])
    flash[:notice] = 'Invalid option'
    redirect_back fallback_location: { action: 'new' }
  end

  def stop_processing
    redirect_to(logout_manage_resources_path) && return
  end

  def update
  end

  def user_is_computer?
    @user.person_role == 'computer' ? result = true : result = false
    result
  end

  private

  def go_to_computer_code
    redirect_to(new_transreg_user_path) && return
  end
end
