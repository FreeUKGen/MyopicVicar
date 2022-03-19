task :extract_information_on_birth_place, [:limit] => [:environment] do |t, args|
  file_for_warning_messages = "#{Rails.root}/log/birth_places.csv"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  output_file = File.new(file_for_warning_messages, "w")
  start = Time.now
  output_file.puts 'chapman,birth county,birth place,verbatim birth county, verbatim birth place,location'
  record_number = 0
  found = 0

  ChapmanCode.freecen_birth_codes.each do |chapman|
    p chapman
    next if %w[UNK].include?(chapman)

    Freecen1VldFile.where(dir_name: chapman).no_timeout.each do |file|
      FreecenDwelling.where(freecen1_vld_file_id: file._id).no_timeout.each do |dwelling|
        FreecenIndividual.where(freecen_dwelling_id: dwelling._id).no_timeout.each do |individual|
          record_number += 1
          break if record_number == args.limit.to_i

          next if chapman == individual.birth_county && chapman == individual.verbatim_birth_county && individual.birth_place == '-' && individual.verbatim_birth_place == '-'

          next if individual.birth_place == '-' && individual.verbatim_birth_place == '-'

          standard_verbatim_birth_place = Freecen2Place.standard_place(individual.verbatim_birth_place)

          gaz = Freecen2Place.find_by(chapman_code: individual.verbatim_birth_county, standard_place_name: standard_verbatim_birth_place)

          gaz = Freecen2Place.find_by("alternate_freecen2_place_names.standard_alternate_name" => standard_verbatim_birth_place) if gaz.blank?

          location = gaz.present? ? 'Yes' : 'No'
          found += 1 if location == 'Yes'
          output_file.puts "#{chapman},\"#{individual.birth_county}\",\"#{individual.birth_place}\",\"#{individual.verbatim_birth_county}\",\"#{individual.verbatim_birth_place}\", #{location}"
        end
      end
    end
  end
  elapse = Time.now - start
  p "#{record_number} processed in #{elapse} seconds with #{found} located"
  p "finished"
end
