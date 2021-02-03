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
class TnaChangeLogsController < ApplicationController
  def destroy
    file = TnaChangeLog.find(params[:id])
    redirect_back(fallback_location: tna_change_logs_path, notice: 'The file does not exist!') && return if file.blank?


    file.destroy
    flash[:notice] = 'The destruction of the file was successful'
    redirect_to tna_change_logs_path
  end

  def download
    file = TnaChangeLog.find(params[:id])
    redirect_back(fallback_location: select_userid_attic_files_path, notice: 'The file does not exist!') && return if file.blank?

    my_file = File.join(Rails.application.config.datafiles, file.userid_detail.userid, '.attic', file.name)
    redirect_back(fallback_location: select_userid_attic_files_path, notice: 'The physical file does not exist!') && return unless File.exist?(my_file)

    flash[:notice] = 'Download commenced'
    flash.keep
    send_file(my_file, filename: file.name) && return
  end

  def select_userid
    get_user_info_from_userid
    @attic_file = TnaChangeLog.new
    @options = UseridDetail.get_userids_for_selection('all')
    @prompt = 'Please select a userid:'
    @location = 'location.href= "/attic_files/?userid=" + this.value'
  end

  def index

    @changes = TnaChangeLog.all.order_by(tna_collection: 1, chapman_code: 1, year: 1)

  end

  def show
    # show an individual batch
    @change = TnaChangeLog.find(params[:id])
  end
end
