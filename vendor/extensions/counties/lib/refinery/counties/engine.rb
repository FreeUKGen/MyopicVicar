module Refinery
  module Counties
    class Engine < Rails::Engine
      extend Refinery::Engine
      isolate_namespace Refinery::Counties

      engine_name :refinery_counties

      initializer "register refinerycms_counties plugin" do
        Refinery::Plugin.register do |plugin|
          plugin.name = "counties"
          plugin.url = proc { Refinery::Core::Engine.routes.url_helpers.counties_admin_counties_path }
          plugin.pathname = root
          plugin.activity = {
            :class_name => :'refinery/counties/county',
            :title => 'county'
          }
          
        end
      end

      config.after_initialize do
        Refinery.register_extension(Refinery::Counties)
      end
    end
  end
end
