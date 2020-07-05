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
    params[:freereg1_csv_file] = params[:gap][:freereg1_csv_file]
    display_info
    redirect_back(fallback_location: new_manage_resource_path, notice: 'The linkages were incorrect') &&
      return if @register.blank? || @church.blank? || @place.blank?

    gap = Gap.new(gap_params)
    gap.save
    redirect_back(fallback_location: new_manage_resource_path, notice: "Addition of the Gap failed:  #{gap.errors.full_messages}") &&
      return if gap.errors.any?

    flash[:notice] = 'Addition of Gap was successful'
    redirect_to gaps_path(register: @register, freereg1_csv_file: @freereg1_csv_file)
  end

  def display_info
    return if params[:register].blank?

    @freereg1_csv_file = Freereg1CsvFile.find_by(id: params[:freereg1_csv_file]) if params[:freereg1_csv_file].present?
    @freereg1_csv_file_name = @freereg1_csv_file.file_name if @freereg1_csv_file.present?
    @freereg1_csv_file_id = @freereg1_csv_file.id if @freereg1_csv_file.present?
    @register = Register.find_by(id: params[:register])
    @register_type = RegisterType.display_name(@register.register_type)
    @church = @register.church
    return if @church.blank?

    @church_name = @church.church_name
    @place = @church.place
    return if @place.blank?

    @place_name = @place.place_name
    @county = @place.county
    @chapman_code = @place.chapman_code
    @syndicate = session[:syndicate]
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
    redirect_to gaps_path(register: @register, freereg1_csv_file: @freereg1_csv_file)

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
      @gaps = Gap.where(register_id: @register.id, freereg1_cev_file: @freereg1_csv_file.id).order_by(record_type: 1, start_date: 1).all
    else
      @gaps = Gap.register(@register.id).order_by(record_type: 1, start_date: 1).all
    end
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
    if @freereg1_csv_file.blank?
      @record_types = RecordType::ALL_FREEREG_TYPES
      @record_types = @record_types + ['All'] unless @record_types.include?('All')
    else
      @record_types = @freereg1_csv_file.record_type
    end
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
    params[:freereg1_csv_file] = params[:gap][:freereg1_csv_file] if params[:freereg1_csv_file].blank?

    display_info
    gap = Gap.find(params[:id])
    redirect_back(fallback_location: new_manage_resource_path, notice: 'Attempted to update a non_existent gap') &&
      return if gap.blank?

    proceed = gap.update_attributes(gap_params)
    redirect_back(fallback_location: new_manage_resource_path, notice: "Update failed #{gap.errors.full_messages}") &&
      return unless proceed

    flash[:notice] = 'Update of GAP was successful'
    redirect_to gaps_path(register: @register, freereg1_csv_file: @freereg1_csv_file)

  end

  private

  def gap_params
    params.require(:gap).permit! if params[:_method] != 'put'
  end
end
