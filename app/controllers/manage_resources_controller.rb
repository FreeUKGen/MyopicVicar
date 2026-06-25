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
    @user_roles = member_roles_for(@user)
    requested_role = params[:user_role].presence || params[:current_role].presence
    @current_role = authorized_member_role(@user, requested_role, session[:role])
    @session_role = @current_role
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
    when @current_role == "researcher" || @current_role == 'pending'
      flash[:notice] = "You are not currently permitted to access the system as your functions are still under development"
      continue = false
    when !Rails.application.config.member_open && !(@current_role == "system_administrator" || @current_role == 'technical')
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
    force_global_sign_out
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
      @manage_resources = ManageResource.new
      render 'actions'
    end
  end

  def pages
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
    @roles = UseridRole.action_sidebar_roles(@current_role)
    session[:userid] = @userid
    session[:user_id] = @user_id
    session[:first_name] = @first_name
    session[:manager] = manager?(@user)
    session[:role] = @current_role
    logger.warn "FREEREG::USER user #{@user.userid}" if appname_downcase == 'freereg'
    logger.warn "FREECEN::USER user #{@user.userid}" if appname_downcase == 'freecen'
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
    @current_role == 'computer'
  end

  private

  def go_to_computer_code
    redirect_to(new_transreg_user_path) && return
  end
end
