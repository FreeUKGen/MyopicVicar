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
require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'csv'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(assets: %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module MyopicVicar
  module TemplateSet
    FREEREG = 'freereg'
    FREECEN = 'freecen'
    FREEBMD = 'freebmd'
    ALL_APPLICATIONS = [
      FREEREG,
      FREECEN,
      FREEBMD
    ]
  end
  module Servers
    BRAZZA = 'brazza'
    COLOBUS = 'colobus'
    DRILL = 'drill'
    HOWLER = 'howler'
    SAKI = 'saki'
    ALL_SERVERS = [
      BRAZZA,
      COLOBUS,
      DRILL,
      HOWLER,
      SAKI
    ]
  end

  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    app = config_for(:freeukgen_application)
    config.template_set = app['template_set']
    config.advert_key = app['advert_key']
    config.gtm_key = app['gtm_key']
    config.cta_display_status = app['cta_display_status']
    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.assets.enabled = true
    config.assets.version = '1.0'
    # Change the path that assets are served from config.assets.prefix = "/assets"
    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = 'utf-8'

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    config.middleware.use Mobvious::Manager

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql
    # config.assets.paths << Rails.root.join("app", "assets", "fonts")
    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    # Explodes in current rails    config.active_record.whitelist_attributes = true

    # set config.template_set before asset directories are selected
    # TODO: make bimodal
    # config.template_set = TemplateSet::FREECEN
    case MyopicVicar::Application.config.template_set
    when TemplateSet::FREECEN
      config.freexxx_display_name = 'FreeCEN'
      config.assets.paths << Rails.root.join('app', 'assets_freecen')

      config.assets.paths << Rails.root.join('app', 'assets_freecen', 'styles')
      config.assets.paths << Rails.root.join('app', 'assets_freecen', 'javascripts')
    when TemplateSet::FREEREG
      config.freexxx_display_name = 'FreeREG'
      config.assets.paths << Rails.root.join('app', 'assets_freereg')
      config.assets.paths << Rails.root.join('app', 'assets_freereg', 'javascripts')
      config.assets.paths << Rails.root.join('app', 'assets_freereg', 'styles')
    when TemplateSet::FREEBMD
      config.freexxx_display_name = 'FreeBMD'
      config.assets.paths << Rails.root.join('app', 'assets_freebmd')

      config.assets.paths << Rails.root.join('app', 'assets_freebmd', 'styles')
    else
      config.freexxx_display_name = 'FreeREG'
      config.assets.paths << Rails.root.join('app', 'assets_freereg')

      config.assets.paths << Rails.root.join('app', 'assets_freereg', 'styles')
    end

    # Enable the asset pipeline
    config.assets.enabled = true # commented out because already set above
    # Version of your assets, change this if you want to expire all your assets
    # config.assets.version = '1.0' # commented out because already set above

    # config.active_record.whitelist_attributes = true Remove as no longer relevant in rails 4.2
    config.api_only = false

    # make the designer's fonts available for the stylesheets
    config.assets.paths << Rails.root.join('app', 'assets')
    config.assets.paths << Rails.root.join('app', 'assets', 'fonts')

    config.generators do |g|
      g.orm :mongoid
    end

    config.before_configuration do
      env_file = Rails.root.join('config', 'application.yml').to_s
      if File.exist?(env_file)
        YAML.load_file(env_file)[Rails.env].each do |key, value|
          ENV[key.to_s] = value
        end
      end
      mongo_config = Rails.root.join('config', 'mongo_config.yml')
      MyopicVicar::MongoConfig = YAML.load_file(mongo_config)[Rails.env] if File.exist?(mongo_config)
    end
  end
end
