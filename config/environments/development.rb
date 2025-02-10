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

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  config.log_level = :info
  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  if config.respond_to?(:action_mailer)
    config.action_mailer.raise_delivery_errors = false
  end

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin
  config.serve_static_files = true

  # Turning Source Maps On, disables concatenation and preprocessing of assets
  # config.assets.debug = true    # for assets pipeline debugging
  config.assets.debug = false

  # Enable live sprockets assets pipeline compilation
  # config.assets.compile = true    # for assets pipeline debugging
  config.assets.compile = false

  # Turning Digests (fingerprinting) On
  # config.assets.digest = false    # for assets pipeline debugging
  config.assets.digest = true

  # Enables additional runtime error checking.
  # Minimize unexpected behaviour when deploying to `production`
  # config.assets.raise_runtime_errors = true   # for assets pipeline debugging
  config.assets.raise_runtime_errors = false

  # Raise an Error When an Asset is Not Found
  # config.assets.unknown_asset_fallback = false    # default, for assets pipeline debugging
  config.assets.unknown_asset_fallback = true

  # Do not compress assets
  config.assets.compress = false

  # Raise exception on mass assignment protection for Active Record models
  config.assets.check_precompiled_asset = false
  config.assets.skip_pipelines = true

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)

  #where to store the collections PlaceChurch
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
  config.website = MyopicVicar::MongoConfig['website']
  config.image_server = MyopicVicar::MongoConfig['image_server']
  config.image_server_access =  MyopicVicar::MongoConfig['image_server_access']
  config.backup_directory = MyopicVicar::MongoConfig['backup_directory']
  config.github_issues_login = MyopicVicar::MongoConfig['github_issues_login']
  config.github_issues_password = MyopicVicar::MongoConfig['github_issues_password']
  config.github_issues_access_token = MyopicVicar::MongoConfig['github_issues_access_token']
  config.github_issues_repo = MyopicVicar::MongoConfig['github_issues_repo']
  config.days_to_retain_search_queries = MyopicVicar::MongoConfig['days_to_retain_search_queries']
  config.days_to_retain_messages = MyopicVicar::MongoConfig['days_to_retain_messages']
  config.sleep = MyopicVicar::MongoConfig['sleep']
  config.emmendation_sleep = MyopicVicar::MongoConfig['emmendation_sleep']
  config.processing_delta = MyopicVicar::MongoConfig['files_for_processing'] unless MyopicVicar::MongoConfig['files_for_processing'].blank?
  config.delete_list = MyopicVicar::MongoConfig['delete_list']
  config.member_open = MyopicVicar::MongoConfig['member_open']
  config.vld_file_locations = MyopicVicar::MongoConfig['vld_file_locations']
  config.fc1_coverage_stats = MyopicVicar::MongoConfig['fc1_coverage_stats'] unless MyopicVicar::MongoConfig['fc1_coverage_stats'].blank?
  config.fc_parms_upload_dir = MyopicVicar::MongoConfig['fc_parms_upload_dir'] unless MyopicVicar::MongoConfig['fc_parms_upload_dir'].blank?
  config.fc_update_processor_status_file = MyopicVicar::MongoConfig['fc_update_processor_status_file'] unless MyopicVicar::MongoConfig['fc_update_processor_status_file'].blank?
  config.wildcard_support = MyopicVicar::MongoConfig['wildcard_support'] unless MyopicVicar::MongoConfig['wildcard_support'].blank?
  config.ucf_support = MyopicVicar::MongoConfig['ucf_support']
  config.witness_support = MyopicVicar::MongoConfig['witness_support']
  config.max_search_time = MyopicVicar::MongoConfig['max_search_time']
  config.our_secret_key = MyopicVicar::MongoConfig['our_secret_key']
  config.secret_key_base = MyopicVicar::MongoConfig['secret_key_base']
  config.sendgrid_api_key = MyopicVicar::MongoConfig['sendgrid_api_key']
  config.citation = MyopicVicar::MongoConfig['citation']
  config.eager_load = false
  config.dragonfly_secret_code = MyopicVicar::MongoConfig['dragonfly_secret_code']
  config.register_embargo_list = MyopicVicar::MongoConfig['register_embargo_list']
  config.freecen2_place_cache = MyopicVicar::MongoConfig['freecen2_place_cache']

end
