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
  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Configure static asset server for tests with Cache-Control for performance

  config.static_cache_control = "public, max-age=3600"

  # Log error messages when you accidentally call methods on nil
  config.whiny_nils = true
  config.assets.raise_runtime_errors = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  if config.respond_to?(:action_mailer)
    config.action_mailer.delivery_method = :test
  end

  # Raise exception on mass assignment protection for Active Record models

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr

  config.mongodb_bin_location = MyopicVicar::MongoConfig['mongodb_bin_location']
  config.datafiles = MyopicVicar::MongoConfig['datafiles']
  config.dataset_date =  MyopicVicar::MongoConfig['dataset_date'] unless MyopicVicar::MongoConfig['dataset_date'].blank?
  config.datafiles_changeset = MyopicVicar::MongoConfig['datafiles_changeset'] unless MyopicVicar::MongoConfig['datafiles_changeset'].blank?
  config.datafiles_delta = MyopicVicar::MongoConfig['datafiles_delta'] unless MyopicVicar::MongoConfig['datafiles_delta'].blank?
  config.website = MyopicVicar::MongoConfig['website']
  config.backup_directory = MyopicVicar::MongoConfig['backup_directory']
  config.github_login = 'FreeUKGenIssues'
  config.github_password = ENV["GITHUB_WORD"]
  config.github_repo = 'FreeUKGen/FreeUKRegProductIssues'
  config.days_to_retain_search_queries = 90
  config.sleep = MyopicVicar::MongoConfig['sleep']
  config.emmendation_sleep = MyopicVicar::MongoConfig['emmendation_sleep']
  config.processing_delta = MyopicVicar::MongoConfig['files_for_processing'] unless MyopicVicar::MongoConfig['files_for_processing'].blank?
  config.delete_list = MyopicVicar::MongoConfig['delete_list']
  config.member_open = MyopicVicar::MongoConfig['member_open']
  config.github_user = MyopicVicar::MongoConfig['github_user']
  config.github_password = MyopicVicar::MongoConfig['github_password']
  config.ucf_support = MyopicVicar::MongoConfig['ucf_support']
  config.witness_support = MyopicVicar::MongoConfig['witness_support']
  config.max_search_time = MyopicVicar::MongoConfig['max_search_time']
  config.our_secret_key = MyopicVicar::MongoConfig['our_secret_key']
  config.secret_key_base = MyopicVicar::MongoConfig['secret_key_base']
  config.sendgrid_api_key = MyopicVicar::MongoConfig['sendgrid_api_key']
  #rails 4 changes
  config.eager_load = false
  #config.active_record.mass_assignment_sanitizer = :strict
  config.serve_static_files = true
  config.assets.compile = true
  config.assets.compress = false
  config.assets.debug = false
  config.assets.digest = false
  config.dragonfly_secret_code = MyopicVicar::MongoConfig['dragonfly_secret_code']

end
