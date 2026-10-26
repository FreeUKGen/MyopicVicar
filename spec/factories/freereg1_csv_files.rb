FactoryBot.define do
  factory :freereg1_csv_file do
    chapman_code { 'SUR' }
    church_name { 'St. Mary' }
    country { 'England' }
    county { 'SUR' }
    datemax { "1900" }
    datemin { "1800" }
    error { 0 }
    sequence(:file_name) { |n| "freereg_baptisms_#{n}.csv" }
    place { 'Guildford' }
    processed { true }
    record_type { RecordType::BAPTISM }
    register_type { 'Baptism' }
    search_record_version { '1' }
    ucf_list { [] }
    ucf_updated { nil }
    sequence(:userid) { |n| "volunteer_#{n}" }
    userid_lower_case { userid.downcase }

    association :register, factory: :register

    trait :baptism_file do
      record_type { RecordType::BAPTISM }
      register_type { 'Baptism' }
    end

    trait :burial_file do
      record_type { RecordType::BURIAL }
      register_type { 'Burial' }
      sequence(:file_name) { |n| "freereg_burials_#{n}.csv" }
    end

    trait :marriage_file do
      record_type { RecordType::MARRIAGE }
      register_type { 'Marriage' }
      sequence(:file_name) { |n| "freereg_marriages_#{n}.csv" }
    end

    trait :with_baptism_entries do
      after(:create) do |file|
        create_list(:freereg1_csv_entry, 3, :baptism, freereg1_csv_file: file)
      end
    end

    trait :with_burial_entries do
      record_type { RecordType::BURIAL }
      after(:create) do |file|
        create_list(:freereg1_csv_entry, 2, :burial, freereg1_csv_file: file)
      end
    end

    trait :with_marriage_entries do
      record_type { RecordType::MARRIAGE }
      after(:create) do |file|
        create_list(:freereg1_csv_entry, 2, :marriage, freereg1_csv_file: file)
      end
    end

    trait :with_search_records do
      after(:create) do |file|
        file.freereg1_csv_entries.each do |entry|
          create(:search_record, freereg1_csv_entry: entry, freereg1_csv_file: file)
        end
      end
    end

    trait :locked_by_transcriber do
      locked_by_transcriber { true }
    end

    trait :locked_by_coordinator do
      locked_by_coordinator { true }
    end

    trait :with_errors do
      error { 5 }
      after(:create) do |file|
        create_list(:batch_error, 2, freereg1_csv_file: file)
      end
    end
  end
end
