class ExtractCollectionUniqueNames
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
            if unique_names.present?
              distinct_register_forenames = ExtractCollectionUniqueNames.extract_unique_forenames(unique_names)
              distinct_register_surnames = ExtractCollectionUniqueNames.extract_unique_surnames(unique_names)
              distinct_register_forenames = distinct_register_forenames.sort
              distinct_register_surnames = distinct_register_surnames.sort
              register_unique_name = RegisterUniqueName.find_by(register_id: register.id)
              if register_unique_name.present?
                register_unique_name.update_attributes(unique_forenames: distinct_register_forenames, unique_surnames: distinct_register_surnames)
              else
                register_unique_name = RegisterUniqueName.new(register_id: register.id, unique_forenames: distinct_register_forenames, unique_surnames: distinct_register_surnames)
                register_unique_name.save
              end
            end
            distinct_church_forenames += distinct_register_forenames
            distinct_church_surnames += distinct_register_surnames
          end
          distinct_church_forenames = distinct_church_forenames.uniq.sort
          distinct_church_surnames = distinct_church_surnames.uniq.sort
          church_unique_name = ChurchUniqueName.find_by(church_id: church.id)
          if distinct_church_forenames.present? || distinct_church_surnames.present?
            if church_unique_name.present?
              church_unique_name.update_attributes(unique_forenames: distinct_church_forenames, unique_surnames: distinct_church_surnames)
            else
              church_unique_name = ChurchUniqueName.new(church_id: church.id, unique_forenames: distinct_church_forenames, unique_surnames: distinct_church_surnames)
              church_unique_name.save
            end
          end
          distinct_place_forenames += distinct_church_forenames
          distinct_place_surnames += distinct_church_surnames
        end
        distinct_place_forenames = distinct_place_forenames.uniq.reject(&:empty?).sort
        distinct_place_surnames = distinct_place_surnames.uniq.reject(&:empty?).sort
        place_unique_name = PlaceUniqueName.find_by(place_id: place.id)
        if distinct_place_forenames.present? || distinct_place_surnames.present?
          if place_unique_name.present?
            place_unique_name.update_attributes(unique_forenames: distinct_place_forenames, unique_surnames: distinct_place_surnames)
          else
            place_unique_name = PlaceUniqueName.new(place_id: place.id, unique_forenames: distinct_place_forenames, unique_surnames: distinct_place_surnames)
            place_unique_name.save
          end
        end
        message_file.puts "#{place.id}, #{place.place_name},#{place.chapman_code}" if distinct_place_forenames.present? || distinct_place_surnames.present?
        num += 1
        break if num == limit
      end
      time_elapsed = Time.now - time_start
      p "Finished #{num} places in #{time_elapsed}"
      message_file.puts "Finished #{num} places in #{time_elapsed}"
    end

    def extract_unique_forenames(names)
      forenames = []
      names.each_pair do |key, value|
        forenames += value if ["Mother's Forename", "Father's Forename", "Person's Forename", "Burial Person's Forename", "Male Relative's Forename",
                               "Female Relative's Forename", "Witness Forename", "Groom's Forename", "Bride's Forename", "Groom's Father's Forename",
                               "Bride's Father's Forename", "Groom's Mother's Forename", "Bride's Mother's Forename"].include?(key)
      end
      forenames = forenames.uniq.reject(&:empty?)
      forenames
    end

    def extract_unique_surnames(names)
      surnames = []
      names.each_pair do |key, value|
        surnames += value if ["Mother's Surname", "Father's Surname", "Person's Surname", "Burial Person's Surname", "Relative's Surname",
                              "Female Relative's Surname", "Witness Surname", "Groom's Surname", "Bride's Surname", "Groom's Father's Surname",
                              "Bride's Father's Surname", "Groom's Mother's Surname", "Bride's Mother's Surname"].include?(key)
      end
      surnames = surnames.uniq.reject(&:empty?)
      surnames
    end
  end
end
