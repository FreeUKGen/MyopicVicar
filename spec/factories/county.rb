FactoryBot.define do
  factory :county do
    sequence(:chapman_code) { |n| "Chap_#{n}" }
    county_coordinator { "coord_userid" }
  end
end
