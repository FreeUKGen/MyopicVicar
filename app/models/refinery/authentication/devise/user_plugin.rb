module Refinery
  module Authentication
    module Devise
      class UserPlugin < Refinery::Core::BaseModel

        belongs_to :user

      end
    end
  end
end
