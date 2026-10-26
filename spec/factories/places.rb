FactoryBot.define do
  factory :place do
    sequence(:place_name) { |n| "Guildford#{n}" }
    # place_name   { "Norfolk" }
    chapman_code { "NFK" }
    country      { "England" }
    county       { "Norfolk" }
    data_present { true }
    latitude     { "52.6309" }
    longitude    { "1.2974" }
    ucf_list     { {} }
    # new  fields for ucf
    # ucf_list_updated_at    { nil }
    # ucf_list_record_count  { 0 }
    # ucf_list_file_count    { 0 }

    # trait :with_data do
    #   after(:create) do |place|
    #     create(:freereg1_csv_file, place_name: place.place_name)
    #   end
    # end
    
    trait :with_ucf_records do
      transient do
        record_groups_count { 1 }
        records_per_group   { 2 }
      end

      after(:build) do |place, evaluator|
        ucf_list = {}

        evaluator.record_groups_count.times do
          group_key = SecureRandom.hex(12)
          ucf_list[group_key] = Array.new(evaluator.records_per_group) { BSON::ObjectId.new }
        end

        place.ucf_list = ucf_list
      end
    end

    trait :with_ucf_data do
      transient do
        record_count { 5 }   # total records across all files
        file_count   { 2 }   # number of files
      end

      after(:build) do |place, evaluator|
        place.ucf_list = {}

        # Distribute record_count across file_count files
        counts = Array.new(evaluator.file_count, evaluator.record_count / evaluator.file_count)
        remainder = evaluator.record_count % evaluator.file_count
        remainder.times { |i| counts[i] += 1 }

        evaluator.file_count.times do |i|
          file_id = BSON::ObjectId.new
          record_ids = Array.new(counts[i]) { BSON::ObjectId.new }

          # MongoDB requires string keys
          place.ucf_list[file_id.to_s] = record_ids
        end
      end
    end

  end
end
