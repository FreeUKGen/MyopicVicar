# spec/support/config/capybara_config.rb
require 'capybara/rspec'

RSpec.configure do |config|
  # Regular feature specs should use the app default driver configured in
  # spec/support/capybara.rb. This keeps the setup in one place and avoids
  # conflicting driver configuration between support files.
  config.include Capybara::DSL, type: :feature
end
