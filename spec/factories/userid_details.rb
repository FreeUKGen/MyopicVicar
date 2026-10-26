FactoryBot.define do
  factory :userid_detail do
    active { 'true' }
    sequence(:email_address) { |n| "user#{n}@example.com" }
    email_address_last_confirmned { Time.now }
    # email_address_last_confirmned { '2025-09-25 19:28:59' }
    password { 'password1234' }
    password_confirmation { 'password1234' }
    person_role { 'transcriber' }
    sequence(:person_forename) { |n| "forename#{n}" }
    # person_forename { 'arron' }
    sequence(:person_surname) { |n| "surname#{n}" }
    # person_surname { 'summers' }
    skill_level { 'Unspecified' }
    syndicate { 'SyndicateA' }
    sequence(:userid) { |n| "user#{n}" }
    # userid {"user1"}

    # optional
    county_groups { ["DEV"] }
    email_address_valid { true }
    no_processing_messages { false }
  end
end
