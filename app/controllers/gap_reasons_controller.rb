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
class GapReasonsController < ApplicationController
  def create
    redirect_back(fallback_location: gap_reasons_path, notice: 'There was no parameter selected') && return if gap_reason_params[:reason].blank?

    @gap_reason = GapReason.new(gap_reason_params)
    @gap_reason.save
    redirect_back(fallback_location: gap_reasons_path, notice: "The creation of the new GAP reason was unsuccessful because #{@gap_reason.errors.messages}") && return if @gap_reason.errors.any?

    flash[:notice] = 'The creation of the new GAP reason was successful'
    redirect_to(gap_reasons_path) && return
  end

  def destroy
    @gap_reason = GapReason.find(params[:id])
    redirect_back(fallback_location: gap_reasons_path, notice: 'The gap reason was not found') && return if @gap_reason.blank?

    @gap_reason.delete
    flash[:notice] = 'The destruction of the GAP reason was successful'
    redirect_to(gap_reasons_path) && return
  end

  def edit
    @gap_reason = GapReason.find(params[:id])
    redirect_back(fallback_location: gap_reasons_path, notice: 'The gap reason was not found') && return if @gap_reason.blank?

    get_user_info_from_userid
  end

  def index
    get_user_info_from_userid
    @gap_reasons = GapReason.all.order_by(reason: 1)
  end

  def new
    get_user_info_from_userid
    reject_access(@user, 'gap_reason') unless session[:role] == 'system_administrator'
    @gap_reason = GapReason.new
  end

  def show
    @gap_reason = GapReason.find(params[:id])
    redirect_back(fallback_location: gap_reasons_path, notice: 'The gap reason was not found') && return if @gap_reason.blank?

    get_user_info_from_userid
  end

  def update
    @gap_reason = GapReason.find(params[:id])
    redirect_back(fallback_location: gap_reasons_path, notice: 'The gap reason was not found') && return if @gap_reason.blank?

    get_user_info_from_userid
    proceed = @gap_reason.update_attributes(gap_reason_params)
    redirect_back(fallback_location: gap_reasons_path, notice: "The gap reason was not not updated because #{@gap_reason.errors.messages}") && return unless proceed

    flash[:notice] = 'The creation of the new gap reason was successful'
    redirect_to(gap_reasons_path) && return if proceed
  end

  private

  def gap_reason_params
    params.require(:gap_reason).permit!
  end
end
