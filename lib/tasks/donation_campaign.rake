# frozen_string_literal: true

namespace :donation_campaign do
  desc "Print whether DonationCampaign.active? is true (ENV > mongo keys > biweekly Sat–Sun fallback)"
  task status: :environment do
    active = DonationCampaign.active?
    puts "DonationCampaign.active? => #{active}"
    if ENV['DONATION_CAMPAIGN_ACTIVE'].present?
      puts "Source: ENV['DONATION_CAMPAIGN_ACTIVE']=#{ENV['DONATION_CAMPAIGN_ACTIVE'].inspect}"
    elsif DonationCampaign.mongo_configures_donation?
      puts 'Source: mongo_config.yml (donation_* keys present)'
      cfg = MyopicVicar::MongoConfig
      puts "donation_campaign_starts_at: #{cfg['donation_campaign_starts_at'].inspect}"
      puts "donation_campaign_ends_at:   #{cfg['donation_campaign_ends_at'].inspect}"
      puts "donation_campaign_active:    #{cfg['donation_campaign_active'].inspect}"
    else
      anchor = DonationCampaign::BIWEEKLY_ANCHOR_SATURDAY
      puts "Source: biweekly weekends (Sat–Sun only, alternating weeks)"
      puts "BIWEEKLY_ANCHOR_SATURDAY: #{anchor.inspect}"
      puts "Today (#{Time.zone.today}): weekend Saturday = #{DonationCampaign.weekend_saturday(Time.zone.today).inspect}"
      puts "Fallback disabled? #{ENV['DONATION_CAMPAIGN_DISABLE_FALLBACK'].inspect}"
    end
  end
end
