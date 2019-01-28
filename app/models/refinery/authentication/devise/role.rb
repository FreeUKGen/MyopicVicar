module Refinery
  module Authentication
    module Devise
      class Role < Refinery::Core::BaseModel

        has_many :roles_users, class_name: 'Refinery::Authentication::Devise::RolesUsers'
        has_many :users, through: :roles_users, class_name: 'Refinery::Authentication::Devise::User'

        before_validation :camelize_title
        validates :title, :uniqueness => true

        def camelize_title(role_title = self.title)
          self.title = role_title.to_s.camelize
        end

        def self.[](title)
          where(:title => title.to_s.camelize).first_or_create!
        end

      end
    end
  end
end
