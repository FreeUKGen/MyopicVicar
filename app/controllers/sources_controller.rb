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
class SourcesController < ApplicationController
  require 'freereg_options_constants'

  def access_image_server
    @user = get_user
    (session[:manage_user_origin] != 'manage county' && session[:chapman_code].blank?) ? chapman_code = 'all' : chapman_code = session[:chapman_code]
    website = Source.create_manage_image_server_url(@user.userid, session[:role], chapman_code)
    redirect_to(website) && return
  end

  def create
    display_info
    redirect_back(fallback_location: root_path, notice: 'Attempting to create with an incomplete source') && return if @register.blank? ||
      @church.blank? || @place.blank? || @source.blank?

    source = Source.where(register_id: params[:source][:register_id]).first
    redirect_back(fallback_location: root_path, notice: 'Attempting to create without the required parameters') && return if source.blank?

    register = source.register
    redirect_back(fallback_location: root_path, notice: 'Attempting to create without the required parameters') && return if register.blank?

    source = Source.new(source_params)
    source.save
    redirect_back(fallback_location: root_path, notice: "Addition of Source was unsuccessful because #{source.errors.messages}") && return if source.errors.any?

    register.sources << source
    register.save
    flash[:notice] = 'Addition of Source was successful'
    redirect_to index_source_path(source.register)
  end

  def destroy
    display_info
    source = Source.id(params[:id]).first
    redirect_back(fallback_location: root_path, notice: 'Attempting to create with an incomplete source') && return if @register.blank? ||
      @church.blank? || @place.blank? || @source.blank? || source.blank?

    redirect_back(fallback_location: root_path, notice: 'Only system_administrator and data_manager is allowed to delete source') and return unless ['system_administrator', 'data_manager'].include? session[:role]

    get_user_info(session[:userid], session[:first_name])
    begin
      source.destroy
      flash[:notice] = 'Deletion of source was successful'
      session.delete(:source_id)
      redirect_to index_source_path(source.register)
    rescue Mongoid::Errors::DeleteRestriction
      logger.info 'Logged Error for Source Delete'
      logger.debug source.source_name + ' is not empty'
      redirect_back(fallback_location: root_path, notice: source.source_name + ' IS NOT EMPTY, CAN NOT BE DELETED')
    end
  end

  def display_info
    @source = Source.find(session[:source_id]) if @source.blank?
    @register = Register.find(session[:register_id]) if session[:register_id].present?
    
    return if @register.blank? || @source.blank?

    @register_type = RegisterType.display_name(@register.register_type)
    @church = Church.find(session[:church_id]) if session[:church_id].present?
    return if @church.blank?

    @church_name = session[:church_name]
    @county = session[:county]
    @place_name = session[:place_name]
    @place = @church.place
    return if @place.blank?

    @county = @place.county
    @place_name = @place.place_name
    @user = get_user
  end

  def edit
    load(params[:id])
    redirect_back(fallback_location: root_path, notice: 'Attempting to edit an incomplete source') && return if @register.blank? ||
      @church.blank? || @place.blank? || @source.blank?
  end

  def flush
    display_info
    @source = Source.id(params[:id]).first
    redirect_back(fallback_location: root_path, notice: 'Attempting to flush an incomplete source') && return if @register.blank? ||
      @church.blank? || @place.blank? || @source.blank?

    @source_id = Source.get_propagate_source_list(@source)
  end

  def index
    params[:id] = session[:register_id] if params[:id].blank?
    @source = Source.where(register_id: params[:id]).all
    display_info
    redirect_back(fallback_location: root_path, notice: 'Attempting to display an incomplete source') && return if @register.blank? ||
      @church.blank? || @place.blank? || @source.blank?
   
    if @source.count == 1
      case @source.first.source_name
      when 'Image Server'
        redirect_to(source_path(id: @source.first.id)) && return

      when 'other server1'
        redirect_to(controller: 'server1', action: 'show', source_name: 'other server1') && return

      when 'other server2'
        #            redirect_to :controller=>'server2', :action=>'show', :source_name=>'other server1'
      end
    end
  end

  def initialize_status
    display_info
    redirect_back(fallback_location: root_path, notice: 'Attempting to initialize an incomplete source') && return if @register.blank? ||
      @church.blank? || @place.blank? || @source.blank?

    allow_initialize = ImageServerGroup.check_all_images_status_before_initialize_source(params[:id])
    redirect_back(fallback_location: root_path, notice: 'Source can be initialized only when all image groups status is unset') && return unless allow_initialize
  end

  def load(source_id)
    @source = Source.find(source_id)
    return if @source.blank?

    session[:source_id] = @source.id
    @register = @source.register
    return if @register.blank?

    @register_type = RegisterType.display_name(@register.register_type)
    session[:register_id] = @register.id
    session[:register_name] = @register_type
    @church = @register.church
    return if @church.blank?

    @church_name = @church.church_name
    session[:church_name] = @church_name
    session[:church_id] = @church.id
    @place = @church.place
    return if @place.blank?

    session[:place_id] = @place.id
    @place_name = @place.place_name
    session[:place_name] = @place_name
    @county = @place.county
    session[:county] = @county
    @user = get_user
  end

  def new
    display_info
    redirect_back(fallback_location: root_path, notice: 'Attempting to show an incomplete source') && return if @register.blank? ||
      @church.blank? || @place.blank? || @source.blank?

    @source_new = Source.new
    name_array = Source.where(register_id: session[:register_id]).pluck(:source_name)
    redirect_back(fallback_location: root_path) && return if name_array.blank?

    @list = FreeregOptionsConstants::SOURCE_NAME - name_array
  end

  def show
    load(params[:id])
    redirect_back(fallback_location: root_path, notice: 'Attempting to show an incomplete source') && return if @register.blank? ||
      @church.blank? || @place.blank? || @source.blank?

    # sessions used for breadcrumb
    session[:image_group_filter] = params[:image_group_filter] if params[:image_group_filter].present?
    session[:assignment_filter_list] = params[:assignment_filter_list] if params[:assignment_filter_list].present?
    # indicate image group display comes from Source or filters under 'All Sources' directly
    session[:from_source] = true
  end

  def update
    source = Source.find(params[:id])
    redirect_back(fallback_location: root_path, notice: 'Attempting to update an incomplete source') && return if source.blank?

    if source_params[:choice] == '1'                        # to propagate Source
      Source.update_for_propagate(params)
      flash[:notice] = 'Update of source was successful'
    elsif source_params[:initialize_status].present?        # to initialize Source
      ImageServerGroup.initialize_all_images_status_under_source(params[:id], source_params[:initialize_status])
      flash[:notice] = 'Successfully initialized source'
    else                                                    # to edit Source
      params[:source].delete(:choice)
      result = source.update_attributes(source_params)
      flash[:notice] = 'Update of source was successful' if result
      flash[:notice] = "Update failed a validation test #{source.errors.messages}" unless result
      redirect_to edit_source_path(source) && return unless result
    end
    flash.keep(:notice)
    redirect_to index_source_path(source.register)
  end

  private

  def source_params
    params.require(:source).permit!
  end
end
