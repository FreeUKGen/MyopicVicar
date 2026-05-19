# frozen_string_literal: true

# Controls Big Give / donation CTA vs default Publift behaviour without editing ERB every campaign.
#
# Priority:
#   1. ENV["DONATION_CAMPAIGN_ACTIVE"] if set (true/false)
#   2. MyopicVicar::MongoConfig (loaded from config/mongo_config.yml) if any donation_campaign_* key exists
#   3. Automatic biweekly weekends when (2) does not apply (see below)
#   4. ENV["DONATION_CAMPAIGN_DISABLE_FALLBACK"]=true — skip (3), e.g. staging
#
# Biweekly weekend schedule (when not using mongo):
#   Donate CTA is ON only on Saturday and Sunday, on alternating weekends.
#   Example: ON Apr 4–5, OFF Apr 11–12, ON Apr 18–19, OFF Apr 25–26, …
#   Set BIWEEKLY_ANCHOR_SATURDAY to the Saturday that starts the first "ON" weekend; after that,
#   no config changes are needed (same code keeps alternating forever).
#
# Optional mongo_config.yml keys: donation_campaign_active, donation_campaign_starts_at, donation_campaign_ends_at
# (see config/mongo_config.example.yml header).
#
# When active: show donate CTA dialog, load per-app fuse_tag JS, do not load async fuse script in <head>.
# When inactive: hide CTA, load async fuse script in <head>, do not load per-app fuse_tag JS.
module DonationCampaign
  module_function

  # First Saturday of an "ON" weekend. Update only if you need to realign the pattern.
  # Apr 4 2026 is a Saturday — use as first campaign weekend when deploying before that date.
  BIWEEKLY_ANCHOR_SATURDAY = Date.new(2026, 4, 4)

  MONGO_DONATION_KEYS = %w[
    donation_campaign_starts_at
    donation_campaign_ends_at
    donation_campaign_active
  ].freeze

  def active?
    if ENV['DONATION_CAMPAIGN_ACTIVE'].present?
      return truthy?(ENV['DONATION_CAMPAIGN_ACTIVE'])
    end

    if mongo_configures_donation?
      return active_from_mongo_config?
    end

    return false if truthy?(ENV['DONATION_CAMPAIGN_DISABLE_FALLBACK'])

    fallback_biweekly_weekend_active?
  end

  def mongo_configures_donation?
    cfg = mongo_cfg
    return false unless cfg

    MONGO_DONATION_KEYS.any? { |k| cfg.key?(k) }
  end

  def active_from_mongo_config?
    cfg = mongo_cfg
    return false unless cfg
    starts = cfg['donation_campaign_starts_at'].presence || cfg[:donation_campaign_starts_at]
    ends = cfg['donation_campaign_ends_at'].presence || cfg[:donation_campaign_ends_at]
    if starts.present? && ends.present?
      zone = Time.zone
      start_t = zone.parse(starts.to_s).beginning_of_day
      end_t = zone.parse(ends.to_s).end_of_day
      return false if end_t < start_t

      now = Time.now.in_time_zone(zone)
      return now >= start_t && now <= end_t
    end

    flag = cfg['donation_campaign_active']
    flag = cfg[:donation_campaign_active] if flag.nil?
    truthy?(flag)
  end

  # Saturday/Sunday only, every other weekend, forever, aligned to BIWEEKLY_ANCHOR_SATURDAY.
  def fallback_biweekly_weekend_active?
    return false if BIWEEKLY_ANCHOR_SATURDAY.nil?

    today = Time.zone.today
    sat = weekend_saturday(today)
    return false if sat.nil?

    weeks = ((sat - BIWEEKLY_ANCHOR_SATURDAY).to_i / 7)
    return false if weeks.negative?

    weeks.even?
  end

  def mongo_cfg
    return nil unless defined?(MyopicVicar::MongoConfig) && MyopicVicar::MongoConfig.is_a?(Hash)

    MyopicVicar::MongoConfig
  end
  private_class_method :mongo_cfg

  # Saturday that begins the current weekend, or nil if today is Mon–Fri.
  def weekend_saturday(date)
    case date.wday
    when 6 then date # Saturday
    when 0 then date - 1 # Sunday -> previous Saturday
    end
  end

  def truthy?(value)
    return false if value.nil?
    return true if value == true

    s = value.to_s.strip.downcase
    %w[1 true yes on].include?(s)
  end
end
