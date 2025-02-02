class BmdUniqueNames
  class << self
    def process(limit)
      file_for_messages = 'log/bmd_extract_names_report.log'
      message_file = File.new(file_for_messages, 'w')
      limit = limit.to_i
      p 'Producing report of the population of uniq names'
      message_file.puts 'Producing report of unique names'
      num = 0
      time_start = Time.now
      p "Process start time: #{time_start}"
      District.find_in_batches.each do |group|
        p "processing batch"
        group.each do |district|
          birth_records = district.records.where(RecordTypeID: 1)
          birth_records_count = birth_records.count
          marriage_records = district.records.where(RecordTypeID: 3)
          marriage_records_count = marriage_records.count
          death_records = district.records.where(RecordTypeID: 2)
          death_records_count = death_records.count
          birth_unique_names = BestGuess.get_birth_unique_names birth_records
          marriage_unique_names = BestGuess.get_marriage_unique_names marriage_records
          death_unique_names = BestGuess.get_death_unique_names death_records
          if birth_unique_names.present?
            p 'Producing report of the population of birth uniq names'
            distinct_birth_forenames = BmdUniqueNames.extract_unique_forenames(birth_unique_names)
            distinct_birth_surnames = BmdUniqueNames.extract_unique_surnames(birth_unique_names)
            distinct_birth_forenames = distinct_birth_forenames.sort
            distinct_birth_surnames = distinct_birth_surnames.sort
            district_unique_name = DistrictUniqueName.where(district_number: district.DistrictNumber, record_type: 1).first
            if district_unique_name.present?
              district_unique_name.update_attributes(unique_forenames: [], unique_surnames: [], , total_records: 0)
              district_unique_name.update_attributes(unique_forenames: distinct_birth_forenames, unique_surnames: distinct_birth_surnames, total_records: birth_records_count)
            else
              district_unique_name = DistrictUniqueName.new(district_number: district.DistrictNumber, unique_forenames: distinct_birth_forenames, unique_surnames: distinct_birth_surnames, record_type: 1, total_records: birth_records_count)
              district_unique_name.save
            end
          end
          if marriage_unique_names.present?
            p 'Producing report of the population of marriage uniq names'
            distinct_marriage_forenames = BmdUniqueNames.extract_unique_forenames(marriage_unique_names)
            distinct_marriage_surnames = BmdUniqueNames.extract_unique_surnames(marriage_unique_names)
            distinct_marriage_forenames = distinct_marriage_forenames.sort if 
            distinct_marriage_surnames = distinct_marriage_surnames.sort
            district_unique_name = DistrictUniqueName.where(district_number: district.DistrictNumber, record_type: 3).first
            if district_unique_name.present?
               district_unique_name.update_attributes(unique_forenames: [], unique_surnames: [], , total_records: 0)
              district_unique_name.update_attributes(unique_forenames: distinct_marriage_forenames, unique_surnames: distinct_marriage_surnames, total_records: marriage_records_count)
            else
              district_unique_name = DistrictUniqueName.new(district_number: district.DistrictNumber, unique_forenames: distinct_marriage_forenames, unique_surnames: distinct_marriage_surnames, record_type: 3, total_records: marriage_records_count)
              district_unique_name.save
            end
          end
          if death_unique_names.present?
            p 'Producing report of the population of death uniq names'
            distinct_death_forenames = BmdUniqueNames.extract_unique_forenames(death_unique_names)
            distinct_death_surnames = BmdUniqueNames.extract_unique_surnames(death_unique_names)
            distinct_death_forenames = distinct_death_forenames.sort
            distinct_death_surnames = distinct_death_surnames.sort
            district_unique_name = DistrictUniqueName.where(district_number: district.DistrictNumber, record_type: 2).first
            if district_unique_name.present?
               district_unique_name.update_attributes(unique_forenames: [], unique_surnames: [], , total_records: 0)
              district_unique_name.update_attributes(unique_forenames: distinct_death_forenames, unique_surnames: distinct_death_surnames, total_records: death_records_count)
            else
              district_unique_name = DistrictUniqueName.new(district_number: district.DistrictNumber, unique_forenames: distinct_death_forenames, unique_surnames: distinct_death_surnames, record_type: 2,  total_records: death_records_count)
              district_unique_name.save
            end
          end
          message_file.puts "#{district.DistrictNumber}, #{district.DistrictName}"
          num += 1
          break if num == limit
        end
        p "process batch completed"
      end
      time_elapsed = Time.now - time_start
      p "Finished #{num} places in #{time_elapsed}"
      message_file.puts "Finished #{num} places in #{time_elapsed}"
    end

    def extract_unique_forenames(names)
      forenames = []
      names.each_pair do |key, value|
        forenames += value if ["GivenName"].include?(key)
      end
      forenames = forenames.uniq.reject(&:empty?)
      forenames
    end

    def extract_unique_surnames(names)
      surnames = []
      names.each_pair do |key, value|
        surnames += value if ["Mother's Surname", "Surname"].include?(key)
      end
      surnames = surnames.uniq.reject(&:empty?)
      surnames
    end
  end
end
