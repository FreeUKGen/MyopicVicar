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

  # Browsers request these at the site root; when Apache forwards to Rails (file missing
  # or not served), avoid RoutingError noise in Errbit.
  BROWSER_ROOT_STATIC_FILES = %w[
    favicon.ico
    apple-touch-icon.png
    apple-touch-icon-precomposed.png
    favicon-16x16.png
    favicon-32x32.png
    safari-pinned-tab.svg
    site.webmanifest
    browserconfig.xml
  ].freeze

  def donate
  end

  def volunteer
  end

  # Catch-all action to render pages dynamically based on path
  def show
    if request.path.start_with?('/assets/')
      head :not_found
      return
    end

    page_path = params[:path] || params[:id]

    if well_known_request?(page_path)
      serve_well_known(page_path)
      return
    end

    if sensitive_path_request?(page_path, request.path)
      head :not_found
      return
    end

    if (static_response = serve_browser_root_static(page_path))
      static_response
      return
    end

    view_name = page_path.to_s
    current_site = MyopicVicar::Application.config.template_set
    site_view_file = Rails.root.join('app', 'views', 'pages', current_site, "#{view_name}.html.erb")

    if File.exist?(site_view_file)
      render template: "pages/#{current_site}/#{view_name}", layout: 'application'
    else
      shared_view_file = Rails.root.join('app', 'views', 'pages', "#{view_name}.html.erb")
      if File.exist?(shared_view_file)
        render template: "pages/#{view_name}", layout: 'application'
      else
        Rails.logger.info("FREEBMD:PAGES: Page not found: #{page_path}")
        head :not_found
      end
    end
  end

  private

  # CMS slugs are not dot-paths (.git, .env, etc.). .well-known is handled above.
  def sensitive_path_request?(page_path, full_path)
    [page_path, full_path].compact.any? do |p|
      path = p.to_s.delete_prefix('/')
      path.include?('..') || path.split('/').any? { |segment| segment.start_with?('.') }
    end
  end

  def serve_browser_root_static(page_path)
    basename = File.basename(page_path.to_s)
    return unless BROWSER_ROOT_STATIC_FILES.include?(basename)

    public_file = Rails.root.join('public', basename)
    if File.exist?(public_file)
      send_file public_file, disposition: 'inline'
    else
      head :not_found
    end
  end

  # Google (Android App Links), Apple, etc. probe /.well-known/* — not CMS pages.
  def well_known_request?(page_path)
    page_path.to_s.start_with?('.well-known/') || page_path.to_s == '.well-known'
  end

  def serve_well_known(page_path)
    public_file = Rails.root.join('public', page_path.to_s)
    if File.exist?(public_file)
      send_file public_file, disposition: 'inline'
    else
      head :not_found
    end
  end
end
