# spec/support/config/capybara_config.rb
require 'capybara/rspec'

RSpec.configure do |config|
  # System specs use Capybara
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :remote_chrome
  end

  # Include Capybara DSL so you can use `visit`, `fill_in`, etc.
  config.include Capybara::DSL, type: :feature
end
