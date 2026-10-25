# spec/support/capybara.rb
require "capybara/rails"
require "capybara/rspec"
require "selenium/webdriver"

Capybara.register_driver :remote_chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    "goog:chromeOptions" => {
      "args" => [
        "--headless=new",
        "--disable-gpu",
        "--no-sandbox",
        "--disable-dev-shm-usage",
        "--window-size=1440,900"
      ]
    }
  )

  Capybara::Selenium::Driver.new(
    app,
    browser: :remote,
    url: ENV.fetch("SELENIUM_REMOTE_URL"),
    capabilities: capabilities
  )
end

Capybara.default_driver = :rack_test
Capybara.javascript_driver = :remote_chrome
Capybara.default_max_wait_time = 5
