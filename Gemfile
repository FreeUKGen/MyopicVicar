source 'http://rubygems.org'

gem 'rails', '= 3.1.3'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# MongoDB
gem 'bson_ext'
gem 'mongo_mapper' #, :git => 'https://github.com/jnunemaker/mongomapper.git', :branch => 'rails3'

# ImageMagick
gem 'rmagick'

# should move rspec to group below
#gem 'rspec-rails'
gem 'rails3-generators'

gem 'rubyzip'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger (ruby-debug for Ruby 1.8.7+, ruby-debug19 for Ruby 1.9.2+)
# gem 'ruby-debug'
# gem 'ruby-debug19', :require => 'ruby-debug'

# Bundle the extra gems:
# gem 'bj'
# gem 'nokogiri'
gem 'sqlite3-ruby', :require => 'sqlite3'
# gem 'aws-s3', :require => 'aws/s3'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
# group :development, :test do
#   gem 'webrat'
# end

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_girl_rails'
end

# Needed for the new asset pipeline
group :assets do
  gem 'sass-rails',   "~> 3.1.5"
  gem 'coffee-rails', "~> 3.1.1"
  gem 'uglifier',     ">= 1.0.3"
end
 
# jQuery is the default JavaScript library in Rails 3.1
gem 'jquery-rails'