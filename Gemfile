source 'https://rubygems.org'

# ------------------------------------------------------------
# Core Framework
# ------------------------------------------------------------
gem 'rails'

# ------------------------------------------------------------
# Database & ODM
# ------------------------------------------------------------
gem 'mongo'                    # MongoDB driver
gem 'mongoid'                  # ODM for MongoDB
gem 'carrierwave-mongoid', require: 'carrierwave/mongoid' # File uploads with Mongoid
gem 'kaminari-mongoid'         # Pagination for Mongoid
gem 'kaminari'                 # Pagination core

gem 'mysql2'                   # For CMS (RefineryCMS)

# ------------------------------------------------------------
# Authentication & Authorization
# ------------------------------------------------------------
gem 'devise'
gem 'devise-encryptable'
gem 'bcrypt'

# ------------------------------------------------------------
# CMS (RefineryCMS)
# ------------------------------------------------------------
gem 'refinerycms'
gem 'refinerycms-authentication-devise'
gem 'refinerycms-wymeditor'

# Temporary fix: refinerycms-i18n pinned due to crash in story 1831
# MUST BE REMOVED when upgrading Refinery to v5
gem 'refinerycms-i18n', '4.0.2',
    git: 'https://github.com/refinery/refinerycms-i18n',
    ref: '30059ea'

# Custom Refinery extension
gem 'refinerycms-county_pages', path: 'vendor/extensions'

# ------------------------------------------------------------
# Frontend & Assets
# ------------------------------------------------------------
gem 'sass-rails'
gem 'coffee-rails'
gem 'bourbon'                  # Sass mixins
gem 'font_awesome5_rails'
gem 'jquery-rails'
gem 'uglifier'                 # JS compressor

# ------------------------------------------------------------
# Utilities & Enhancements
# ------------------------------------------------------------
gem 'airbrake'                 # Error reporting
gem 'browser'                  # Browser detection
gem 'email_veracity'           # Email validation
gem 'execjs'                   # JS runtime
gem 'formtastic'               # Form builder
gem 'geocoder', '1.3.7'        # Geocoding (locked due to regression in 1.4)
gem 'gretel'                   # Breadcrumbs
gem 'json'
gem 'mail-logger'
gem 'mobvious'                 # Mobile device detection
gem 'newrelic_rpm'             # Performance monitoring
# gem 'nokogiri', '>= 1.13.6'
gem 'octokit'                  # GitHub API client
gem 'osgb', git: 'https://github.com/FreeUKGen/osgb.git'
gem 'rubyzip'
gem 'simple_form'
gem 'text'
gem 'traceroute'               # Detect unused routes
gem 'tzinfo-data'              # Required for Windows
gem 'unicode'
gem 'zip-zip'

# ------------------------------------------------------------
# Development & Test
# ------------------------------------------------------------
group :development, :test do
  gem 'pry'
  gem 'pry-byebug'
  gem 'rspec-rails', '~> 3.1'
end

# ------------------------------------------------------------
# Development Only
# ------------------------------------------------------------
group :development do
  # gem 'rubocop', '~> 1.23.0', require: false
  gem 'rubocop-rails'
end

# ------------------------------------------------------------
# Test Only
# ------------------------------------------------------------
group :test do
  # Add test-only gems here if needed
end
