# spec/support/capybara.rb
require 'capybara/rails'
require 'capybara/rspec'

begin
  require 'selenium/webdriver'
rescue LoadError
  warn 'selenium-webdriver not available; JS driver remains disabled until it is installed.'
end

# Default for standard feature specs and page-level checks.
Capybara.default_driver = :rack_test
Capybara.default_max_wait_time = 5

# JavaScript-capable browser driver for explicit js: true tests.
if defined?(Selenium::WebDriver)
  Capybara.register_driver :remote_chrome do |app|
    capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
      'goog:chromeOptions' => {
        'args' => [
          '--headless=new',
          '--disable-gpu',
          '--no-sandbox',
          '--disable-dev-shm-usage',
          '--window-size=1440,900'
        ]
      }
    )

    Capybara::Selenium::Driver.new(
      app,
      browser: :remote,
      url: ENV.fetch('SELENIUM_REMOTE_URL'),
      capabilities: capabilities
    )
  end

  Capybara.javascript_driver = :remote_chrome
end
