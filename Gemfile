source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.1"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use sqlite3 as the database for Active Record
gem "sqlite3", ">= 2.1"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# gems which are specific to MyopicVicar application:
gem "mysql2"
gem "mongoid"
gem "mongo"
gem "execjs"
gem "bcrypt"
gem "text"
gem "json"
gem "pry"
gem "pry-byebug"
gem "email_veracity"
gem "unicode"
gem "csv"
gem "carrierwave-mongoid", :require => "carrierwave/mongoid"
gem "airbrake"
gem "formtastic"
gem "kaminari"
gem "kaminari-mongoid"
gem "gretel"
gem "geocoder", "1.3.7" #appears to be a regression in 1.4
gem "bourbon"
gem "mail-logger"
gem "mobvious"
gem "devise"
gem "devise-encryptable"
gem "osgb", git: "https://github.com/FreeUKGen/osgb.git"
gem "simple_form"
gem "rubyzip"
gem "zip-zip"
gem "rspec-rails"
gem "newrelic_rpm"
gem "octokit"
gem "traceroute"
gem "coffee-rails"#, "~> 3.2.1"
gem "uglifier"#, ">= 1.0.3"
gem "jquery-rails"
gem "font_awesome5_rails"
gem "rubocop-rails"
gem "rubocop", "~> 1.23.0", require: false
gem "browser"
gem "jquery-validation-rails", "~> 1.13", ">= 1.13.1"
gem "rails_autolink"
gem "mongoid-grid_fs"


group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end
