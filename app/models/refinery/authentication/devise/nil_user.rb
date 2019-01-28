require 'refinery/core/nil_user'

module Refinery
  module Authentication
    module Devise
      class NilUser < Refinery::Core::NilUser

        def plugins
          Refinery::Plugins.new
        end

        def has_role?(role)
          false
        end

        def has_plugin?(name)
          false
        end

        def can_edit?(user)
          false
        end

        def landing_url
          Refinery::Core.backend_path
        end

      end
    end
  end
end
