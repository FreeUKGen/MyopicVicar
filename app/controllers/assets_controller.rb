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
class AssetsController < ApplicationController

  def index
    flash[:notice] = "There are no assets for #{params[:id]}"
    redirect_to main_app.new_manage_resource_path
  end

  def show
    file = resource_file
    if file
      send_file file, disposition: 'inline'
    else
      flash[:notice] = "There are no assets for #{params[:id]}"
      redirect_to main_app.new_manage_resource_path
    end
  end

  private

  # Handbooks and other documents in app/assets_<app>/resources are linked as /assets/<file name> without a
  # fingerprint, but Sprockets 4 does not precompile them, so the request reaches here instead (#1909)
  def resource_file
    dir = Rails.root.join('app', "assets_#{appname_downcase}", 'resources')
    path = dir.join(File.basename(Rack::Utils.unescape_path(request.path)))
    path if path.dirname == dir && path.file?
  end
end
