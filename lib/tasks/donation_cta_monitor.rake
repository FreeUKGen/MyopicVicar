# frozen_string_literal: true

namespace :donation_campaign do
  desc "Confirm the donation CTA popup is actually rendering on the live sites and email a screenshot report. Intended to run every 2 weeks (see crontab)."
  task check_and_notify: :environment do
    expected_active = DonationCampaign.active?
    unless expected_active
      puts "DonationCampaign.active? is false today (#{Time.zone.today}) - nothing to confirm, skipping."
      next
    end

    results = DonationCtaMonitor.run
    results.each do |result|
      status = result.error.presence || (result.ok? ? 'OK' : 'NOT SHOWING AS EXPECTED')
      puts "#{result.site}: expected_active=#{result.expected_active} popup_open=#{result.popup_open} status=#{status}"
    end

    AdminMailer.donation_cta_check(results).deliver_now
    puts results.all?(&:ok?) ? 'Confirmation email sent.' : 'ALERT email sent - see results above.'
  end
end
