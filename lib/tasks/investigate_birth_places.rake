desc "Look for unique birth places"
require 'chapman_code'

task :investigate_birth_places, %i[chapman year lim] => :environment do |_t, args|
  file_for_warning_messages = 'log/birth_places.csv'
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  message_file = File.new(file_for_warning_messages, 'w')
  message_file.puts 'Code,Year,File,Type,Verb Code, Verb Place, Verb Valid, Alt Code, Alt Place, Alt Valid, Notes'
  chapman_code = args.chapman.to_s
  limit = args.lim.to_i
  year = args.year.to_s
  file_count = 0
  p "Starting birth place analysis for #{chapman_code} in #{year} with a limit of #{limit} file(s)"
  files = Freecen1VldFile.where(dir_name: chapman_code, full_year: year).order_by(updated_at: 1)
  birth_places = []
  p files.length
  files.each do |file|
    file_count += 1
    next if file_count > limit

    p "Processing #{file.file_name}"
    entries = Freecen1VldEntry.where(freecen1_vld_file_id: file.id)
    individuals = FreecenIndividual.where(freecen1_vld_file_id: file.id)
    p entries.length
    p individuals.length
    if individuals.length.positive?
      individuals.each do |individual|
        compute_duplicate(birth_places, individual, 'individual', file.file_name)
      end
    else
      entries.each do |entry|
        compute_duplicate(birth_places, entry, 'entry', file.file_name)
      end
    end
  end
  birth_places.each do |place|
    line = ''
    line << "#{chapman_code},"
    line << "#{year},"
    line << "#{place[:file_name]},"
    line << "#{place[:type]},"
    line << "#{place[:verb_county]},"
    line << "\"#{place[:verb_place]}\","
    line << "#{place[:verb_place_valid]},"
    line << "#{place[:alt_county]},"
    line << "\"#{place[:alt_place]}\","
    line << "#{place[:alt_place_valid]},"
    line << "\"#{place[:notes]}\","
    message_file.puts line
  end
  p birth_places
  p 'Finished'
end

def self.add_to_collection(birth_places, birth_place)
  result = true
  birth_places.each do |place|
    if place[:verb_county] == birth_place[:verb_county] && place[:verb_place] == birth_place[:verb_place] &&
        place[:alt_county] == birth_place[:alt_county] && place[:alt_place] == birth_place[:alt_place]
      result = false
      break
    end
  end
  result
end

def self.check_valid?(county, place)
  return true if place == '-'

  return true if place == ''

  return true if place.blank?

  Freecen2Place.valid_place_name?(county, place)
end

def self.compute_duplicate(birth_places, entry, type, file_name)
  duplicate = {}
  duplicate[:file_name] = file_name
  duplicate[:verb_county] = entry.verbatim_birth_county
  duplicate[:verb_place] = entry.verbatim_birth_place
  duplicate[:alt_county] = entry.birth_county
  duplicate[:alt_place] = entry.birth_place
  duplicate[:notes] = entry.notes
  duplicate[:type] = type
  duplicate[:verb_place_valid] = check_valid?(duplicate[:verb_county], duplicate[:verb_place])
  duplicate[:alt_place_valid] = check_valid?(duplicate[:alt_county], duplicate[:alt_place])
  birth_places << duplicate if add_to_collection(birth_places, duplicate)
end
