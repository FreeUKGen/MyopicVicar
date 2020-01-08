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
    params[:register] = params[:gap][:register]
    display_info
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The linkages were incorrect') &&
      return if @register.blank? || @church.blank? || @place.blank?

    gap = Gap.new(gap_params)
    gap.save
    redirect_back(fallback_location: new_manage_resource_path, notice: "Addition of the Gap failed:  #{gap.errors.full_messages}") &&
      return if gap.errors.any?

    flash[:notice] = 'Addition of Gap was successful'
    redirect_to gaps_path(register: @register)
  end

  def display_info
    return if params[:register].blank?

    @freereg1_csv_file = Freereg1CsvFile.find_by(id: params[:file]) if params[:file].present?
    @register = Register.find_by(id: params[:register])
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
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The linkages were incorrect') &&
      return if @register.blank? || @church.blank? || @place.blank?

    gap = Gap.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The gap does not exist') &&
      return if gap.blank?

    gap.destroy

    flash[:notice] = 'Deletion of GAP was successful'
    redirect_to gaps_path(register: @register)
  end

  def edit
    display_info
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The linkages were incorrect') &&
      return if @register.blank? || @church.blank? || @place.blank?

    reasons = GapReason.order_by(reason: 1).all
    @reasons = []
    reasons.each do |reason|
      @reasons << reason.reason
    end
    @record_types = RecordType::ALL_FREEREG_TYPES
    @record_types = @record_types + ['All'] unless @record_types.include?('All')
    @gap = Gap.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Attempted to edit a non_existent gap') &&
      return if @gap.blank?
  end

  def index
    display_info
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The linkages were incorrect') &&
      return if @register.blank? || @church.blank? || @place.blank?

    if @freereg1_csv_file.present?
      @gaps = []
      Gap.register(@register.id).each do |gap|
        @gaps << gap if gap.record_type == 'All' || gap.record_type == @freereg1_csv_file.record_type
      end
    else
      @gaps = Gap.register(@register.id).all
    end
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Attempted to display non_existent gaps') &&
      return if @gaps.blank?

    redirect_to gap_path(@gaps.first.id, register: @register) if @gaps.count == 1
  end

  def new
    display_info
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The linkages were incorrect') &&
      return if @register.blank? || @church.blank? || @place.blank?

    reasons = GapReason.order_by(reason: 1).all
    @reasons = []
    reasons.each do |reason|
      @reasons << reason.reason
    end
    @record_types = RecordType::ALL_FREEREG_TYPES
    @record_types = @record_types + ['All'] unless @record_types.include?('All')
    @gap = Gap.new
  end

  def show
    display_info
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The linkages were incorrect') &&
      return if @register.blank? || @church.blank? || @place.blank?

    @gap = Gap.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Attempted to display non_existent gaps') &&
      return if @gap.blank?
  end

  def update
    params[:register] = params[:gap][:register]
    display_info
    gap = Gap.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Attempted to update a non_existent gap') &&
      return if gap.blank?

    proceed = gap.update_attributes(gap_params)
    redirect_back(fallback_location: new_manage_resource_path, notice: "Update failed #{gap.errors.full_messages}") &&
      return unless proceed

    flash[:notice] = 'Update of GAP was successful'
    redirect_to gaps_path(register: @register)
  end

  private

  def gap_params
    params.require(:gap).permit! if params[:_method] != 'put'
  end
end
