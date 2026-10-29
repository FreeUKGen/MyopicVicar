source "https://rubygems.org"

ruby "3.3.12"

gem "rails", "~> 7.2.2"

# gem 'refinerycms'
# gem 'refinerycms-authentication-devise'
# gem 'refinerycms-wymeditor'
# We use this version of refinerycms-i18n because of the crash in story 1831. IT MUST BE REMOVED on bump of refinery to version 5
# gem 'refinerycms-i18n', '4.0.2', git: 'https://github.com/refinery/refinerycms-i18n', ref: '30059ea'
# See above
# gem 'refinerycms-county_pages', :path => 'vendor/extensions'
#
# gem 'bcrypt', git: 'https://github.com/codahale/bcrypt-ruby'
# gem 'libv8'
# gem 'therubyracer', platforms: :ruby # avoid loading on windows

gem "airbrake"
gem "bcrypt"
gem "bourbon"
gem "browser"
gem "carrierwave", "~> 2.1.0"
gem "carrierwave-mongoid", "~> 1.5", require: "carrierwave/mongoid"
gem "csv"
gem "devise"
gem "devise-encryptable"
gem "email_veracity"
gem "execjs"
gem "faraday-retry"
gem "font_awesome5_rails"
gem "formtastic"
gem "geocoder", "1.3.7" # appears to be a regression in 1.4
gem "gretel"
gem "jquery-rails"
gem "json", "< 3.0" # for Rails/Sprockets compatibility, to be updated when using propshaft
gem "kaminari"
gem "kaminari-mongoid"
gem "logger", "1.6.0"
gem "mail-logger"
gem "mime-types", "~> 3.5.0"
gem "mobvious"
gem "mongo"
gem "mongoid"
gem "mongo_session_store", "~> 3.2"
gem "mysql2"
gem "net-imap"
gem "net-pop"
gem "net-smtp"
gem "newrelic_rpm"
gem "nokogiri", ">= 1.13.6"
gem "octokit"
gem "osgb", git: "https://github.com/FreeUKGen/osgb.git"
gem "puma"
gem "rubyzip"
gem "simple_form"
gem "text"
gem "traceroute"
gem "tzinfo-data" # needed by windows
gem "unicode"
gem "zip-zip"

# Deprecated (still included for Rails/Sprockets compatibility
gem "coffee-rails"
gem "mimemagic", "~> 0.4.3"
gem "sass-rails"
gem "uglifier"

group :development, :test do
  gem "pry", ">= 0.14.2"
  gem "pry-byebug"
  gem "rubocop"
  gem "rubocop-rails"
end

group :development do
end

group :test do
  gem "rspec-rails"
end
