require 'factory_bot_rails'

# This lets you use `create(:user)` / `build(:post)` instead of `FactoryBot.create(:user)`
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
