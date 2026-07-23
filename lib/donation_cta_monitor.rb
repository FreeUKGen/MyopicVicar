# frozen_string_literal: true

require 'selenium-webdriver'
require 'tmpdir'

# Runs every 2 weeks (see lib/tasks/donation_cta_monitor.rake) to confirm the donation
# CTA popup (DonationCampaign.active?, rendered in app/views/layouts/_header.html.erb)
# is actually showing on the live sites during a scheduled campaign window, not just
# that the on/off logic says it should be. Catches two distinct failure modes:
#   - DonationCampaign.active? returns false when it should be true (schedule/config bug)
#   - it returns true, but the popup never opens in a real browser (JS/render bug)
class DonationCtaMonitor
  Result = Struct.new(:site, :url, :expected_active, :popup_open, :screenshot_path, :error, keyword_init: true) do
    def ok?
      error.nil? && (!expected_active || popup_open)
    end
  end

  SITES = {
    'FreeREG' => 'https://www.freereg.org.uk',
    'FreeCEN' => 'https://www.freecen.org.uk'
  }.freeze

  DIALOG_WAIT_SECONDS = 10

  def self.run
    new.run
  end

  def run
    expected_active = DonationCampaign.active?
    SITES.map { |site, url| check_site(site, url, expected_active) }
  end

  private

  def check_site(site, url, expected_active)
    driver = build_driver
    driver.navigate.to(url)
    popup_open = wait_for_dialog(driver)
    screenshot_path = save_screenshot(driver, site)
    Result.new(site: site, url: url, expected_active: expected_active, popup_open: popup_open, screenshot_path: screenshot_path)
  rescue StandardError => e
    Result.new(site: site, url: url, expected_active: expected_active, popup_open: false, screenshot_path: nil, error: "#{e.class}: #{e.message}")
  ensure
    driver&.quit
  end

  def build_driver
    profile_dir = Dir.mktmpdir('donation_cta_check')
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless=new')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--window-size=1400,1000')
    # Fresh, never-used profile per check so the donate_cta_flag_new cookie
    # (which suppresses the popup after a real visitor dismisses it) is never set.
    options.add_argument("--user-data-dir=#{profile_dir}")
    Selenium::WebDriver.for(:chrome, options: options)
  end

  def wait_for_dialog(driver)
    Selenium::WebDriver::Wait.new(timeout: DIALOG_WAIT_SECONDS).until { dialog_open?(driver) }
  rescue Selenium::WebDriver::Error::TimeoutError
    false
  end

  # #myDialog wraps layouts/_donate_cta; cookie_control.js calls showModal() on it,
  # which sets the `open` attribute the moment it's actually visible to a visitor.
  def dialog_open?(driver)
    driver.execute_script("var d = document.getElementById('myDialog'); return !!(d && d.open);")
  end

  def save_screenshot(driver, site)
    path = Rails.root.join('tmp', "donation_cta_#{site.downcase}_#{Time.now.strftime('%Y%m%d_%H%M')}.png")
    driver.save_screenshot(path.to_s)
    path.to_s
  end
end
