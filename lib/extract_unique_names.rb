class ExtractUniqueNames
  class << self
    def process(limit)
      file_for_messages = 'log/extract_names_report.log'
      message_file = File.new(file_for_messages, 'w')
      limit = limit.to_i
      p 'Producing report of the population of surnames'
      message_file.puts 'Producing report of unique names'
      num = 0
      time_start = Time.now
      Place.data_present.no_timeout.each do |place|
        distinct_place_forenames = []
        distinct_place_surnames = []
        place.churches.no_timeout.each do |church|
          distinct_church_forenames = []
          distinct_church_surnames = []
          church.registers.no_timeout.each do |register|
            distinct_register_forenames = []
            distinct_register_surnames = []
            unique_names = {}
            register.freereg1_csv_files.no_timeout.each do |file|
              unique_names = unique_names.merge(file.get_unique_names) { |key, v1, v2| v1 + v2 }
            end
            distinct_register_forenames = ExtractUniqueNames.extract_unique_forenames(unique_names) if unique_names.present?
            distinct_register_surnames = ExtractUniqueNames.extract_unique_surnames(unique_names) if unique_names.present?
            register.update(unique_forenames: distinct_register_forenames, unique_surnames: distinct_register_surnames) if unique_names.present?
            distinct_church_forenames = distinct_church_forenames + distinct_register_forenames
            distinct_church_surnames = distinct_church_surnames + distinct_register_surnames
          end
          distinct_church_forenames = distinct_church_forenames.uniq
          distinct_church_surnames = distinct_church_surnames.uniq
          church.update(unique_forenames: distinct_church_forenames, unique_surnames: distinct_church_surnames) if distinct_church_forenames.present? || distinct_church_surnames.present?
          distinct_place_forenames = distinct_place_forenames + distinct_church_forenames
          distinct_place_surnames = distinct_place_surnames + distinct_church_surnames
        end
        distinct_place_forenames = distinct_place_forenames.uniq.reject(&:empty?)
        distinct_place_surnames = distinct_place_surnames.uniq.reject(&:empty?)
        place.update_attributes(unique_forenames: distinct_place_forenames, unique_surnames: distinct_place_surnames) if distinct_place_forenames.present? || distinct_place_surnames.present?
        message_file.puts "#{place.id}, #{place.place_name},#{place.chapman_code}" if distinct_place_forenames.present? || distinct_place_surnames.present?
        num = num + 1
        break if num == limit
      end
      time_elapsed = Time.now - time_start
      p "Finished #{num} places in #{time_elapsed}"
    end

    def extract_unique_forenames(names)
      forenames = []
      names.each_pair do |key, value|
        forenames = forenames + value if ["Mother's Forename", "Father's Forename", "Person's Forename", "Burial Person's Forename", "Male Relative's Forename",
                                          "Female Relative's Forename", "Witness Forename", "Groom's Forename", "Bride's Forename", "Groom's Father's Forename",
                                          "Bride's Father's Forename", "Groom's Mother's Forename", "Bride's Mother's Forename"].include?(key)
      end
      forenames = forenames.uniq.reject(&:empty?)
      forenames
    end

    def extract_unique_surnames(names)
      surnames = []
      names.each_pair do |key, value|
        surnames = surnames + value if ["Mother's Surname", "Father's Surname", "Person's Surname", "Burial Person's Surname", "Relative's Surname",
                                        "Female Relative's Surname", "Witness Surname", "Groom's Surname", "Bride's Surname", "Groom's Father's Surname",
                                        "Bride's Father's Surname", "Groom's Mother's Surname", "Bride's Mother's Surname"].include?(key)
      end
      surnames = surnames.uniq.reject(&:empty?)
      surnames
    end
  end
end
