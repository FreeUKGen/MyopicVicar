FactoryBot.define do
  factory :emendation_type do
    sequence(:name) { |n| "Emendation type #{n}" }
    target_field { :first_name }
    origin { SearchRecord::Source::TRANSCRIPT }
  end

  factory :emendation_rule do
    sequence(:original) { |n| "original#{n}" }
    sequence(:replacement) { |n| "replacement#{n}" }
    association :emendation_type
  end
end
