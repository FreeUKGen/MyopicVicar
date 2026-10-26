FactoryBot.define do
  factory :church do
    sequence(:church_name) { |n| "St. Mary Church #{n}" }
    # church_name { "St Mary" }
    place_name  { "Norfolk" }
    location    { "Norfolk" }

    association :place, factory: :place
    # association :place
  end
end
