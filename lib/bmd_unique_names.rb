class BmdUniqueNames
  class << self
    def process(limit)
      file_for_messages = 'log/bmd_extract_names_report.log'
      message_file = File.open(file_for_messages, 'w')
      limit = limit.to_i
      log_message(message_file, 'Producing report of unique names')
      num = 0
      time_start = Time.now
      log_message(message_file, "Process start time: #{time_start}")

      District.find_in_batches(batch_size: 1000) do |group|
        log_message(message_file, "Processing batch")
        group.each do |district|
          process_names_for_district(district, message_file)
          num += 1
          break if num == limit
        end
        log_message(message_file, "Process batch completed")
      end

      time_elapsed = Time.now - time_start
      log_message(message_file, "Finished #{num} places in #{time_elapsed}")
      message_file.close
    end

    private

    def process_names_for_district(district, message_file)
      record_types = { 1 => 'birth', 3 => 'marriage', 2 => 'death' }
      record_types.each do |record_type_id, record_type|
        records = district.records.where(RecordTypeID: record_type_id)
        unique_names = BestGuess.send("get_#{record_type}_unique_names", records)
        next unless unique_names.present?

        log_message(message_file, "processing #{record_type} unique names")
        distinct_forenames = extract_unique_forenames(unique_names).sort
        distinct_surnames = extract_unique_surnames(unique_names).sort
        update_or_create_district_unique_name(district, record_type_id, distinct_forenames, distinct_surnames, records.count)
      end
      log_message(message_file, "#{district.DistrictNumber}, #{district.DistrictName}")
    end

    def update_or_create_district_unique_name(district, record_type_id, forenames, surnames, total_records)
      district_unique_name = DistrictUniqueName.find_or_initialize_by(district_number: district.DistrictNumber, record_type: record_type_id)
      district_unique_name.update(unique_forenames: forenames, unique_surnames: surnames, total_records: total_records)
    end

    def extract_unique_forenames(names)
      names.values_at("GivenName").compact.flatten.uniq.reject(&:empty?)
    end

    def extract_unique_surnames(names)
      names.values_at("Mother's Surname", "Surname").compact.flatten.uniq.reject(&:empty?)
    end

    def log_message(file, message)
      p message
      file.puts message
    end
  end
end