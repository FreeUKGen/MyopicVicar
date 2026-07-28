#!/usr/bin/env ruby
# frozen_string_literal: true

# Standalone donation CTA monitor, run by .github/workflows/donation_cta_monitor.yml
# on GitHub-hosted runners - deliberately NOT part of the Rails app (that app runs
# Ruby 2.6.0 in production/staging, has no native Chrome/chromedriver package
# available, and Selenium 4.1.0 - the last version compatible with that Ruby -
# predates Selenium Manager's auto driver management). GitHub's runners have a
# modern Ruby and Chrome pre-installed, sidestepping all of that.
#
# Confirms the donation CTA popup (driven by DonationCampaign.active? in
# lib/donation_campaign.rb) is actually showing on the live sites during a
# scheduled campaign weekend, and emails a screenshot report.
#
# The biweekly on/off date math below is intentionally reimplemented rather than
# read from the Rails app: a monitor that shares the exact same code as the thing
# it's checking can't catch a bug in that shared code. Keep BIWEEKLY_ANCHOR_SATURDAY
# in sync with lib/donation_campaign.rb by hand if that ever changes.
#
# KNOWN LIMITATION: this does not know about manual overrides via
# config/mongo_config.yml or ENV['DONATION_CAMPAIGN_ACTIVE'] on the real server -
# that file is gitignored and unreachable from here. If someone manually turns the
# campaign on/off outside the biweekly schedule, this script won't know and may
# raise a false alert (or stay quiet when it shouldn't).

require 'date'
require 'selenium-webdriver'
require 'mail'
require 'tmpdir'

BIWEEKLY_ANCHOR_SATURDAY = Date.new(2026, 4, 4)

SITES = {
  'FreeREG' => 'https://www.freereg.org.uk',
  'FreeCEN' => 'https://www.freecen.org.uk'
}.freeze

# Update with the real CEO address before relying on this.
RECIPIENTS = [
  'vinosrik@gmail.com',
  'ceo@freeukgenealogy.org.uk' # placeholder
].freeze

DIALOG_WAIT_SECONDS = 10

Result = Struct.new(:site, :url, :popup_open, :screenshot_path, :error, keyword_init: true) do
  def ok?
    error.nil? && popup_open
  end
end

def expected_active?(today = Date.today)
  sat =
    case today.wday
    when 6 then today
    when 0 then today - 1
    else return false
    end
  weeks = (sat - BIWEEKLY_ANCHOR_SATURDAY).to_i / 7
  return false if weeks.negative?

  weeks.even?
end

def build_driver
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless=new')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1400,1000')
  # Fresh profile per run so the popup's dismissal cookie is never set.
  options.add_argument("--user-data-dir=#{Dir.mktmpdir('donation_cta_check')}")
  Selenium::WebDriver.for(:chrome, options: options)
end

# #myDialog wraps layouts/_donate_cta; cookie_control.js calls showModal() on it,
# which sets the `open` attribute the moment it's actually visible to a visitor.
def dialog_open?(driver)
  driver.execute_script("var d = document.getElementById('myDialog'); return !!(d && d.open);")
end

def wait_for_dialog(driver)
  Selenium::WebDriver::Wait.new(timeout: DIALOG_WAIT_SECONDS).until { dialog_open?(driver) }
rescue Selenium::WebDriver::Error::TimeoutError
  false
end

def check_site(site, url)
  driver = build_driver
  driver.navigate.to(url)
  popup_open = wait_for_dialog(driver)
  screenshot_path = File.join(Dir.pwd, "donation_cta_#{site.downcase}.png")
  driver.save_screenshot(screenshot_path)
  Result.new(site: site, url: url, popup_open: popup_open, screenshot_path: screenshot_path)
rescue StandardError => e
  Result.new(site: site, url: url, popup_open: false, screenshot_path: nil, error: "#{e.class}: #{e.message}")
ensure
  driver&.quit
end

def send_email(results)
  all_ok = results.all?(&:ok?)
  checked_at = Time.now
  subject =
    if all_ok
      "✅ Donation CTA confirmed live (#{checked_at.strftime('%Y-%m-%d')})"
    else
      "⚠️ Donation CTA ALERT (#{checked_at.strftime('%Y-%m-%d')})"
    end

  rows = results.map do |r|
    status = (r.error && !r.error.empty?) ? r.error : (r.ok? ? 'OK' : 'NOT SHOWING AS EXPECTED')
    "<tr><td>#{r.site}</td><td>#{r.url}</td><td>#{r.popup_open ? 'Yes' : 'No'}</td><td>#{status}</td></tr>"
  end.join

  Mail.defaults do
    delivery_method :smtp, {
      address: 'smtp.gmail.com',
      port: 587,
      user_name: ENV.fetch('GMAIL_USERNAME'),
      password: ENV.fetch('GMAIL_PASSWORD'),
      authentication: 'plain',
      enable_starttls_auto: true
    }
  end

  Mail.deliver do
    to RECIPIENTS
    from "FreeUKGen Donation CTA Monitor <#{ENV.fetch('GMAIL_USERNAME')}>"
    subject subject

    html_part do
      content_type 'text/html; charset=UTF-8'
      body <<~HTML
        <p><strong>#{all_ok ? 'Donation CTA confirmed live' : 'Donation CTA ALERT'}</strong> — checked #{checked_at.strftime('%Y-%m-%d %H:%M %Z')}.</p>
        <table cellpadding="6" cellspacing="0" border="1" style="border-collapse:collapse;">
          <tr><th>Site</th><th>URL</th><th>Popup opened</th><th>Status</th></tr>
          #{rows}
        </table>
        <p>Screenshots of each homepage are attached.</p>
      HTML
    end

    results.each do |r|
      next unless r.screenshot_path && File.exist?(r.screenshot_path)

      add_file(filename: "#{r.site}.png", content: File.read(r.screenshot_path, mode: 'rb'))
    end
  end
end

unless ENV['FORCE_CHECK'] == 'true' || expected_active?
  puts "Not an expected active weekend (#{Date.today}) per the biweekly schedule - nothing to confirm, exiting."
  puts "(set FORCE_CHECK=true to run anyway, e.g. for testing)"
  exit 0
end

results = SITES.map { |site, url| check_site(site, url) }
results.each { |r| puts "#{r.site}: popup_open=#{r.popup_open} error=#{r.error.inspect}" }

send_email(results)
puts results.all?(&:ok?) ? 'Confirmation email sent.' : 'ALERT email sent - see results above.'
