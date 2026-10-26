FactoryBot.define do
  factory :register do
    register_name { "Baptism Register" }
    sequence(:register_type) { 'Baptism' }
    # register_type { "baptism" }
    status        { "active" }

    association :church, factory: :church
    # association :church
  end
end
