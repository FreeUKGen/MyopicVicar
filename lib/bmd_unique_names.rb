class BmdUniqueNames
  class << self
    def process(district=nil)
      district = district
      file_for_messages = 'log/bmd_extract_names_report.log'
      num = 0
      time_start = Time.now

      File.open(file_for_messages, 'w') do |message_file|
        log_message(message_file, 'Producing report of unique names')
        log_message(message_file, "Process start time: #{time_start}")
        if district.present?
          district = District.where(DistrictName: district).first
          log_message(message_file, "Processing batch for district: #{district.DistrictName}")
          process_names_for_district(district, message_file)
          log_message(message_file, "Process batch completed for district: #{district.DistrictName}")
        else
          District.find_in_batches(batch_size: 1000) do |group|
            log_message(message_file, "Processing batch")
            group.each do |district|
              process_names_for_district(district, message_file)
            end
            log_message(message_file, "Process batch completed")
          end
        end
        time_elapsed = Time.now - time_start
      end
    end

    private

    def process_names_for_district(district, message_file)
      record_types = { 1 => 'birth', 3 => 'marriage', 2 => 'death' }
      record_types.each do |record_type_id, record_type|
        records = district.records.where(RecordTypeID: record_type_id)
        unique_names = BestGuess.send("get_#{record_type}_unique_names", records)
        next unless unique_names.present?

        log_message(message_file, "Processing #{record_type} unique names")
        distinct_forenames = extract_unique_names(unique_names, "GivenName")
        distinct_surnames = extract_unique_names(unique_names, "AssociateName", "Surname")
        update_or_create_district_unique_name(district, record_type_id, distinct_forenames, distinct_surnames, records.count)
      end
      log_message(message_file, "#{district.DistrictNumber}, #{district.DistrictName}")
    end

    def update_or_create_district_unique_name(district, record_type_id, forenames, surnames, total_records)
      district_unique_name = DistrictUniqueName.find_or_initialize_by(district_number: district.DistrictNumber, record_type: record_type_id)
      district_unique_name.update(unique_forenames: forenames, unique_surnames: surnames, total_records: total_records)
    end

    def extract_unique_names(names, *fields)
      names.values_at(*fields).compact.flatten.reject(&:empty?).map(&:downcase).uniq.sort
    end

    def log_message(file, message)
      puts message
      file.puts message
    end
  end
end