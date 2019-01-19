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
class GapsController < ApplicationController
  def create
    display_info
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The linkages were incorrect') && return if @source.blank? ||
      @register.blank? || @church.blank? || @place.blank?

    gap = Gap.new(gap_params)
    gap.save
    redirect_back(fallback_location: new_manage_resource_path, notice: "Addition of the Gap failed:  #{gap.errors.full_messages}") && return if gap.errors.any?

    flash[:notice] = 'Addition of Gap was successful'
    redirect_to index_gap_path(@source)
  end

  def display_info
    return if session[:source_id].blank?

    @source = Source.find(session[:source_id])
    return if @source.blank?

    session[:source_id] = @source.id
    @register = @source.register
    return if @register.blank?

    session[:register_id] = @register.id
    @register_type = RegisterType.display_name(@register.register_type)
    session[:church_id] = @register.church_id
    @church = Church.find(session[:church_id])
    return if @church.blank?

    @church_name = @church.church_name
    session[:church_name] = @church_name
    @place = @church.place
    return if @place.blank?

    @place_name = @place.place_name
    session[:place_name] = @place_name
    @county = @place.county
    @chapman_code = @place.chapman_code
    session[:county] = @county
    session[:chapman_code] = @syndicate if session[:chapman_code].blank? && @syndicate.present?
    @user = get_user
  end

  def destroy
    display_info
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The linkages were incorrect') && return if @source.blank? ||
      @register.blank? || @church.blank? || @place.blank?

    gap = Gap.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The gap does not exist') && return if gap.blank?

    source = gap.source
    gap.destroy

    flash[:notice] = 'Deletion of GAP was successful'
    redirect_to index_gap_path(source)
  end

  def edit
    display_info
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The linkages were incorrect') && return if @source.blank? ||
      @register.blank? || @church.blank? || @place.blank?

    @gap = Gap.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Attempted to edit a non_existent gap') && return if @gap.blank?
  end

  def index
    display_info
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The linkages were incorrect') && return if @source.blank? ||
      @register.blank? || @church.blank? || @place.blank?

    params[:id] = session[:source_id] if params[:id].blank?

    @gap = Gap.where(source_id: params[:id]).all
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Attempted to display non_existent gaps') && return if @gap.blank?

    redirect_to gap_path(@gap.first.id) if @gap.count == 1
  end

  def new
    display_info
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The linkages were incorrect') && return if @source.blank? ||
      @register.blank? || @church.blank? || @place.blank?

    @reason = GapReason.all.pluck(:reason).sort
    @gap = Gap.new
  end

  def show
    display_info
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The linkages were incorrect') && return if @source.blank? ||
      @register.blank? || @church.blank? || @place.blank?

    @gap = Gap.find(params[:id])

    redirect_back(fallback_location: new_manage_resource_path, notice: 'Attempted to display non_existent gaps') && return if @gap.blank?
  end

  def update
    gap = Gap.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Attempted to update a non_existent gap') && return if gap.blank?

    proceed = gap.update_attributes(gap_params)
    redirect_back(fallback_location: new_manage_resource_path, notice: "Update failed #{gap.errors.full_messages}") && return unless proceed

    flash[:notice] = 'Update of GAP was successful'
    redirect_to index_gap_path(gap.source)
  end

  private

  def gap_params
    params.require(:gap).permit! if params[:_method] != 'put'
  end
end
