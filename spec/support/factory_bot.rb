RSpec.configure do |config|
  # This lets you call `create(:user)` instead of `FactoryBot.create(:user)`
  config.include FactoryBot::Syntax::Methods
end
