class ExtractUniqueNames
  require 'chapman_code'
  def self.process(limit)
    file_for_messages = 'log/extract_names_report.log'
    message_file = File.new(file_for_messages, 'w')
    limit = limit.to_i

    puts "Producing report of the population of surnames"
    message_file.puts "Field,Surname,Number of Records\n"
    num = 0
    distinct_register_forenames = []
    distinct_register_surnames = []
    distinct_church_forenames = []
    distinct_church_surnames = []
    distinct_place_forenames = []
    distinct_place_surnames = []
    unique_names = {}
    Places.data_present.each.no_timeout do |place|
      place.churches.each.no_timeout do |church|
        church.registers.each.no_timeout do |register|
          register.freereg1_csv_files.each.no_timeout do |file|
            unique_names = file.get_unique_names
          end
          distinct_register_forenames = unique_names.extract_unique_forenames
          distinct_register_surnames = unique_names.extract_unique_surnames
          register.update(unique_forenames: distinct_register_surnames, unique_surnames: distinct_register_surnames)
          distinct_church_forenames << distinct_register_forenames
          distinct_church_surnames << distinct_register_surnames
        end
        distinct_church_forenames = distinct_church_forenames.uniq
        distinct_church_surnames = distinct_church_surnames.uniq
        church.update(unique_forenames: distinct_church_forenames, unique_surnames: distinct_church_surnames)
        distinct_place_forenames << distinct_place_forenames
        distinct_place_surnames << distinct_place_forenames
      end
      distinct_place_forenames = distinct_place_forenames.uniq
      distinct_place_surnames = distinct_place_forenames.uniq
      place.update(unique_forenames: distinct_place_forenames, unique_surnames: distinct_place_surnames)
      num = num + 1
      break if num == limit
    end



    p "Finished #{limit} records"

  end
end
