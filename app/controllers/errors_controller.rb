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
require 'socket'

class ErrorsController < ActionController::Base
  layout false

  def not_found
    render file: Rails.root.join('public', '404.html'), layout: false, status: :not_found
  end

  def unprocessable_entity
    render file: Rails.root.join('public', '422.html'), layout: false, status: :unprocessable_entity
  end

  def internal_server_error
    @error_url = error_url
    @userid = userid
    @server_hostname = Socket.gethostname

    log_error_details

    render status: :internal_server_error
  end

  private

  def error_url
    original_url = request.env['action_dispatch.original_url']
    return original_url if original_url.present?

    original_path = request.env['action_dispatch.original_path'].presence
    original_fullpath = request.env['ORIGINAL_FULLPATH'].presence || request.env['action_dispatch.original_fullpath'].presence
    fullpath = original_path.present? ? original_path_with_query(original_path) : original_fullpath
    fullpath = request.original_fullpath if fullpath.blank?

    if fullpath.match?(/\Ahttps?:\/\//)
      fullpath
    else
      "#{request.protocol}#{request.host_with_port}#{fullpath}"
    end
  end

  def original_path_with_query(original_path)
    return original_path if request.query_string.blank?

    "#{original_path}?#{request.query_string}"
  end

  def userid
    userid_detail_id = session[:userid_detail_id].presence || cookies.signed[:userid].presence
    return if userid_detail_id.blank?

    userid_detail = UseridDetail.id(userid_detail_id).first
    userid_detail.present? ? userid_detail.userid : userid_detail_id
  rescue StandardError
    userid_detail_id
  end

  def log_error_details
    exception = request.env['action_dispatch.exception']
    exception_class = exception.present? ? exception.class.name : 'Unavailable'
    exception_message = exception.present? ? exception.message : 'Unavailable'

    Rails.logger.error(
      "500 ERROR: URL=#{@error_url} USERID=#{@userid || 'Unavailable'} " \
      "CLIENT_IP=#{client_ip} SERVER_HOSTNAME=#{@server_hostname} " \
      "EXCEPTION_CLASS=#{exception_class} EXCEPTION_MESSAGE=#{exception_message}"
    )
  end

  def client_ip
    request.remote_ip.presence || request.remote_addr.presence || 'Unavailable'
  end
end
