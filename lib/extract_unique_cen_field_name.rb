class ExtractUniqueCenFieldName
  class << self
    def process(limit)
      file_for_messages = 'log/extract_cen_names_report.log'
      message_file = File.new(file_for_messages, 'w')
      limit = limit.to_i
      p 'Producing report of the unique field names'
      message_file.puts 'Producing report of the unique field names'
      num = 0
      time_start = Time.now

      birth_county = FreecenIndividual.distinct(:birth_county)
      verbatim_birth_county = FreecenIndividual.distinct(:verbatim_birth_county)
      diff_birth_verbatim_county = birth_county - verbatim_birth_county
      diff_verbatim_birth_county = verbatim_birth_county - birth_county
      message_file.puts "Birth County #{birth_county.length} values "
      message_file.puts birth_county.inspect
      message_file.puts "Verbatim Birth County #{verbatim_birth_county.length} values "
      message_file.puts verbatim_birth_county.inspect
      message_file.puts "Birth County NOT in Verbatim Birth County #{diff_birth_verbatim_county.length} values "
      message_file.puts diff_birth_verbatim_county.inspect
      message_file.puts "Verbatim Birth County NOT in Birth County #{diff_verbatim_birth_county.length} values "
      message_file.puts diff_verbatim_birth_county.inspect

      birth_county.each do |county|
        num = num + 1
        break if num == limit
        verbatim_birth_place = FreecenIndividual.where(birth_county: county).distinct(:verbatim_birth_place)
        birth_place = FreecenIndividual.where(birth_county: county).distinct(:birth_place)


        diff_birth_verbatim_place = birth_place - verbatim_birth_place
        diff_verbatim_birth_place = verbatim_birth_place - birth_place
        message_file.puts "county #{county}"
        message_file.puts "Birth Place #{birth_place.length} values "
        message_file.puts birth_place.inspect
        message_file.puts "Verbatim Birth Place #{verbatim_birth_place.length} values "
        message_file.puts verbatim_birth_place.inspect
        message_file.puts "Birth Place NOT in Verbatim Birth Place #{diff_birth_verbatim_place.length} values "
        message_file.puts diff_birth_verbatim_place.inspect
        message_file.puts "Verbatim Birth Place NOT in Birth Place #{diff_verbatim_birth_place.length} values "
        message_file.puts diff_verbatim_birth_place.inspect
      end
      time_elapsed = Time.now - time_start
      p "Finished #{num} places in #{time_elapsed}"
    end
  end
end
