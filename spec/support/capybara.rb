require 'capybara/rspec'

RSpec.configure do |config|
  # Include Capybara DSL so you can use `visit`, `fill_in`, etc.
  config.include Capybara::DSL, type: :feature
end
