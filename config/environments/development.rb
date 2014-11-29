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

  
  # Do not compress assets
  config.assets.compress = false
   
  # Expands the lines which load the assets
  config.assets.debug = false


  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict
   
  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  config.active_record.auto_explain_threshold_in_seconds = 0.5
  #where to store the collections PlaceChurch
  config.mongodb_collection_temp = File.join(Rails.root,'tmp')
  #Where the collections are stored
  config.mongodb_collection_location = File.join(Rails.root,'db','collections')
  # Date of dataset used
  config.dataset_date = "3 September 2014"


  # Machine-specific options
  if File.exist? "/raid/freereg2/backups"
    # we are on vervet
    #location of the mongo binary folder
    config.mongodb_bin_location = "/usr/local/bin/" 
    #where do we store the Mongodb database 
    config.datafiles = "/raid-test/freereg2/users"
    #static website to be used for emails and github issue URLs
    config.website = "http://test2.freereg.org.uk"
    #directory to put backups in
    config.backup_directory = "/raid/freereg2/backups"
    
  elsif File.exist? '/home/benwbrum/dev/clients/freeukgen'
    # we are on Ben's development laptop
    #location of the mongo binary folder
    config.mongodb_bin_location = "/usr/bin/" 
    #where do we store the Mongodb database 
    config.datafiles = "/home/benwbrum/dev/clients/freeukgen/freereg1_data/full/tar6"
    #static website to be used for emails and github issue URLs
    config.website = "http://localhost:3000"
    #directory to put backups in
    config.backup_directory = File.join(Rails.root, 'tmp', 'backups')

  elsif File.exist? '/home/benwbrum/dev/freereg'
    # we are on Ben's server
    #location of the mongo binary folder
    config.mongodb_bin_location = "/usr/bin/" 
    #where do we store the Mongodb database 
    config.datafiles = "/media/data/slow/dev/freeukgen/old_data/freereg/tarC"
    #static website to be used for emails and github issue URLs
    config.website = "http://mv.aspengrovefarm.com"
    #directory to put backups in
    config.backup_directory = File.join(Rails.root, 'tmp', 'backups')

  elsif File.exist? "d:/mongodb/bin/"
    # we are on Kirk's system
    #location of the mongo binary folder
    config.mongodb_bin_location = "d:/mongodb/bin/"
    #where do we store the Mongodb database
    config.datafiles = 'c:/freereg12/'
    #static website to be used for emails and github issue URLs
    config.website = "http://localhost:3000"
    #directory to put backups in
    config.backup_directory = File.join(Rails.root, 'tmp', 'backups')
  elsif File.exist? "C:/MongoDB/bin/"
    # we are on Mike's system
    #location of the mongo binary folder
    config.mongodb_bin_location = "C:/MongoDB/bin/"
    #where do we store the Mongodb database
    config.datafiles = 'J:/GitRepository/freereg2'
    #static website to be used for emails and github issue URLs
    config.website = "http://localhost:3000"
    #directory to put backups in
    config.backup_directory = File.join(Rails.root, 'tmp', 'backups')
  else
    #who knows where we are!!!!!we don't
  end
  
    
  config.github_login = 'FreeUKGenIssues'
  config.github_password = nil
  config.github_repo = 'FreeUKGen/FreeUKGenProductIssues'

end
