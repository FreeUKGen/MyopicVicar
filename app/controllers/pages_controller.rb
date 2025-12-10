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
class PagesController < ApplicationController
  skip_before_action :require_login
  
  def donate
    
  end

  def volunteer
    
  end
  
  # Catch-all action to render pages dynamically based on path
  def show
    # Get the page path from params (everything after the route)
    page_path = params[:path] || params[:id]
    
    # Convert path to view file name
    # Handle both "about" and "help/getting-started" style paths
    view_name = page_path.to_s
    
    # Get current site (template_set)
    current_site = MyopicVicar::Application.config.template_set
    
    # Check if the view file exists in site-specific directory first
    site_view_file = Rails.root.join('app', 'views', 'pages', current_site, "#{view_name}.html.erb")
    
    if File.exist?(site_view_file)
      # Render from site-specific directory
      render template: "pages/#{current_site}/#{view_name}", layout: 'application'
    else
      # Fallback to shared pages directory (for backward compatibility)
      shared_view_file = Rails.root.join('app', 'views', 'pages', "#{view_name}.html.erb")
      if File.exist?(shared_view_file)
        render template: "pages/#{view_name}", layout: 'application'
      else
        raise ActionController::RoutingError, "Page not found: #{page_path}"
      end
    end
  end
end