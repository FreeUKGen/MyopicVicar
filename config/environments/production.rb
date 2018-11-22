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
MyopicVicar::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_files = false
  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  config.log_level = :info

  # Prepend all log lines with the following tags
  #config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  #config.assets.precompile += %w( search.js )

  # Disable delivery errors, bad email addresses will be ignored
  if config.respond_to?(:action_mailer)
    # config.action_mailer.raise_delivery_errors = false
  end
  config.action_dispatch.ip_spoofing_check = false
  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 0.5
  config.mongodb_collection_temp = File.join(Rails.root,'tmp')
  #Where the collections are stored
  config.mongodb_collection_location = File.join(Rails.root,'db','collections')
  # Date of dataset used
  config.dataset_date = "9 November 2014"

  config.mongodb_bin_location = MyopicVicar::MongoConfig['mongodb_bin_location']
  config.datafiles = MyopicVicar::MongoConfig['datafiles']
  config.dataset_date =  MyopicVicar::MongoConfig['dataset_date'] unless MyopicVicar::MongoConfig['dataset_date'].blank?
  config.datafiles_changeset = MyopicVicar::MongoConfig['datafiles_changeset'] unless MyopicVicar::MongoConfig['datafiles_changeset'].blank?
  config.datafiles_delta = MyopicVicar::MongoConfig['datafiles_delta'] unless MyopicVicar::MongoConfig['datafiles_delta'].blank?
  config.image_server = MyopicVicar::MongoConfig['image_server']
  config.website = MyopicVicar::MongoConfig['website']
  config.image_server_access =  MyopicVicar::MongoConfig['image_server_access']
  config.backup_directory = MyopicVicar::MongoConfig['backup_directory']
  config.github_issues_login = MyopicVicar::MongoConfig['github_issues_login']
  config.github_issues_password = MyopicVicar::MongoConfig['github_issues_password']
  config.github_issues_repo = MyopicVicar::MongoConfig['github_issues_repo']
  config.days_to_retain_search_queries = MyopicVicar::MongoConfig['days_to_retain_search_queries']
  config.sleep = MyopicVicar::MongoConfig['sleep']
  config.emmendation_sleep = MyopicVicar::MongoConfig['emmendation_sleep']
  config.processing_delta = MyopicVicar::MongoConfig['files_for_processing'] unless MyopicVicar::MongoConfig['files_for_processing'].blank?
  config.delete_list = MyopicVicar::MongoConfig['delete_list']
  config.member_open = MyopicVicar::MongoConfig['member_open']
  config.ucf_support = MyopicVicar::MongoConfig['ucf_support']
  config.witness_support = MyopicVicar::MongoConfig['witness_support']
  config.max_search_time = MyopicVicar::MongoConfig['max_search_time']
  config.our_secret_key = MyopicVicar::MongoConfig['our_secret_key']
  config.secret_key_base = MyopicVicar::MongoConfig['secret_key_base']
  config.sendgrid_api_key = MyopicVicar::MongoConfig['sendgrid_api_key']
  config.citation = MyopicVicar::MongoConfig['citation']
  config.dragonfly_secret_code = MyopicVicar::MongoConfig['dragonfly_secret_code']
  #rails 4 changes
  config.eager_load = true
end
