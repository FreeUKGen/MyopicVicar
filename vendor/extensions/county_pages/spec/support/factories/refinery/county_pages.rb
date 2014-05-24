
FactoryGirl.define do
  factory :county_page, :class => Refinery::CountyPages::CountyPage do
    sequence(:name) { |n| "refinery#{n}" }
  end
end

