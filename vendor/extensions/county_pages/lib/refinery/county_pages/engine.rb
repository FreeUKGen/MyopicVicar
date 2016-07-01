module Refinery
  module CountyPages
    class Engine < Rails::Engine
      extend Refinery::Engine
      isolate_namespace Refinery::CountyPages

      engine_name :refinery_county_pages

      initializer "register refinerycms_county_pages plugin" do
        Refinery::Plugin.register do |plugin|
          plugin.name = "county_pages"
          plugin.url = proc { Refinery::Core::Engine.routes.url_helpers.county_pages_admin_county_pages_path }
          plugin.pathname = root
        end
      end

      config.after_initialize do
        Refinery.register_extension(Refinery::CountyPages)
      end
    end
  end
end
