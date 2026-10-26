FactoryBot.define do
  factory :search_record do
    transcript_names do
      [{ 'first_name' => 'Wm', 'last_name' => 'Smith', 'type' => 'primary' }]
    end
    search_names do
      [{
        'first_name' => 'wm',
        'last_name' => 'smith',
        'origin' => SearchRecord::Source::TRANSCRIPT,
        'type' => SearchRecord::PersonType::PRIMARY
      }]
    end
  end
end
