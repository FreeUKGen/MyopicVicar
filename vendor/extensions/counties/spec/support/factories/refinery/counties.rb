
FactoryGirl.define do
  factory :county, :class => Refinery::Counties::County do
    sequence(:county) { |n| "refinery#{n}" }
  end
end

