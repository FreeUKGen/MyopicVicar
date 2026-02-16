source 'https://rubygems.org'
# Workaround for mimemagic yanked versions (marcel/activestorage dependency)
# Use a GitHub tag that provides a 0.3.x release so `marcel ~> 0.3.x` is satisfied.
# If your environment doesn't have the system mime database, you may need to
# install `shared-mime-info` (Ubuntu/Debian: `sudo apt-get install shared-mime-info`).
# Try a GitHub tag for the original mimemagic repository (v0.3.10). If this tag
# is unavailable, you can try another fork that exposes a 0.3.x tag.
gem 'mimemagic', git: 'https://github.com/mimemagicrb/mimemagic', tag: 'v0.3.10'

# Some stdlib features were converted to default gems in newer Rubies;
# add explicit dependency to ensure Bundler can provide it when required
# under the Bundler environment (resolves LoadError: cannot load such file -- mutex_m).
gem 'mutex_m'

# Some stdlib features were converted to default gems in newer Rubies and
# may not be available under Bundler unless declared; add `csv` explicitly
# because `config/application.rb` requires it and Ruby 3.4 warns/removes it
# from the default gems.
gem 'csv'

gem 'rails', '5.2'
gem 'tzinfo-data' #needed by windows
gem 'mysql2'
#gem 'refinerycms'
#gem 'refinerycms-authentication-devise'
#gem 'refinerycms-wymeditor'
# We use this version of refinerycms-i18n because of the crash in story 1831. IT MUST BE REMOVED on bump of refinery to version 5
#gem 'refinerycms-i18n', '4.0.2', git: 'https://github.com/refinery/refinerycms-i18n', ref: '30059ea'
# See above
gem 'mongoid'
gem 'mongo'
gem 'execjs'
#gem 'libv8'
gem 'mobvious'
gem 'formtastic'
#gem 'therubyracer', platforms: :ruby # avoid loading on windows
gem 'airbrake'
#  gem 'bcrypt', git: 'https://github.com/codahale/bcrypt-ruby'
gem 'bcrypt'
gem 'text'
gem 'json'
gem 'pry'
gem 'pry-byebug'
gem 'email_veracity'
gem 'unicode'
gem 'kaminari'
gem 'kaminari-mongoid'
gem 'gretel'
gem 'geocoder', '1.3.7' #appears to be a regression in 1.4
gem 'bourbon'
gem 'mail-logger'
gem 'devise'
gem 'devise-encryptable'
gem 'nokogiri', ">= 1.13.6"
gem 'osgb', git: 'https://github.com/FreeUKGen/osgb.git'
gem 'rubyzip'
gem 'zip-zip'
gem 'rspec-rails'
gem 'carrierwave-mongoid', '1.2.0', require: 'carrierwave/mongoid'
gem 'simple_form'
gem 'newrelic_rpm'
gem 'octokit'
gem 'traceroute'
gem 'sass-rails' #,   '~> 3.2.3'
gem 'coffee-rails'#, '~> 3.2.1'
gem 'uglifier'#, '>= 1.0.3'
gem 'jquery-rails'
gem 'font_awesome5_rails'
#gem 'refinerycms-county_pages', :path => 'vendor/extensions'
gem 'rubocop-rails'
gem 'rubocop', '~> 1.23.0', require: false
gem 'browser'
gem 'rails3-jquery-autocomplete'
gem 'jquery-validation-rails', '~> 1.13', '>= 1.13.1'
gem 'rails_autolink'