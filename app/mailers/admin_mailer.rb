# frozen_string_literal: true

# Internal-only notifications for site operators, distinct from UserMailer's
# member/transcriber-facing emails.
class AdminMailer < ActionMailer::Base
  default from: 'FreeUKGen Donation CTA Monitor <no-reply@freeukgenealogy.org.uk>'
  layout false

  # Update RECIPIENTS with the real addresses before relying on this in production.
  RECIPIENTS = [
    'vinosrik@gmail.com',
    'ceo@freeukgenealogy.org.uk' # placeholder - replace with the actual CEO address
  ].freeze

  # results: Array of DonationCtaMonitor::Result
  def donation_cta_check(results)
    @results = results
    @all_ok = results.all?(&:ok?)
    @checked_at = Time.now

    results.each do |result|
      next unless result.screenshot_path && File.exist?(result.screenshot_path)

      attachments["#{result.site}.png"] = File.read(result.screenshot_path)
    end

    subject = @all_ok ? "✅ Donation CTA confirmed live (#{@checked_at.strftime('%Y-%m-%d')})" : "⚠️ Donation CTA ALERT (#{@checked_at.strftime('%Y-%m-%d')})"
    mail(to: RECIPIENTS, subject: subject)
  end
end
