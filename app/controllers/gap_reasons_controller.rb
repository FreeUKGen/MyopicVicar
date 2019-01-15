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
    if gap_reason_params[:reason].blank?
      flash[:notice] = 'You must enter a field '
      redirect_to :back and return
    end

    @gap_reason  = GapReason.new(gap_reason_params)
    @gap_reason.save

    if @gap_reason.errors.any?
      flash[:notice] = "The creation of the new GAP reason was unsuccessful because #{@gap_reason.errors.messages}"
      get_userids_and_transcribers
      redirect_to :back and return
    end

    flash[:notice] = 'The creation of the new GAP reason was successful'
    redirect_to :action => 'index' and return
  end

  def destroy
    @gap_reason = GapReason.id(params[:id]).first
    if @gap_reason.blank?
      go_back("gap_reason",params[:id])
    end

    @gap_reason.delete

    flash[:notice] = 'The destruction of the GAP reason was successful'
    redirect_to :action => 'index' and return
  end

  def edit
    get_user_info_from_userid

    @gap_reason = GapReason.id(params[:id]).first

    go_back("denomination",params[:id]) if @gap_reason.blank?
  end

  def index
    get_user_info_from_userid
    @gap_reasons = GapReason.all.order_by(reason: 1)
  end

  def new
    get_user_info_from_userid
    reject_access(@user,"gap_reason") unless @user.person_role == 'system_administrator'
    @gap_reason = GapReason.new
  end

  def show
    get_user_info_from_userid
    @gap_reason = GapReason.id(params[:id]).first

    go_back("gap_reason",params[:id]) if @gap_reason.blank?
  end

  def update
    get_user_info_from_userid
    @gap_reason = GapReason.id(params[:id]).first

    go_back("denomination",params[:id]) if @gap_reason.blank?

    @gap_reason.update_attributes(gap_reason_params )

    flash[:notice] = 'The creation of the new denomination was successful'
    redirect_to :action => 'index' and return
  end

  private
  def gap_reason_params
    params.require(:gap_reason).permit!
  end

end
