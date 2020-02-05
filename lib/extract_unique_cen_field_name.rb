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
      birth_place = FreecenIndividual.distinct(:birth_place)
      verbatim_birth_county = FreecenIndividual.distinct(:verbatim_birth_county)
      verbatim_birth_place = FreecenIndividual.distinct(:verbatim_birth_place)
      diff_birth_verbatim_county = birth_county - verbatim_birth_county
      diff_verbatim_birth_county = verbatim_birth_county - birth_county
      diff_birth_verbatim_place = birth_place - verbatim_birth_place
      diff_verbatim_birth_place = verbatim_birth_place - birth_place
      message_file.puts 'Birth County'
      message_file.puts birth_county
      message_file.puts 'Verbatim Birth County'
      message_file.puts verbatim_birth_county
      message_file.puts 'Birth County NOT in Verbatim Birth County'
      message_file.puts diff_birth_verbatim_county
      message_file.puts 'Verbatim Birth County NOT in Birth County '
      message_file.puts diff_verbatim_birth_county
      message_file.puts 'Birth Place'
      message_file.puts birth_place
      message_file.puts 'Verbatim Birth Place'
      message_file.puts verbatim_birth_place
      message_file.puts 'Birth Place NOT in Verbatim Birth Place'
      message_file.puts diff_birth_verbatim_place
      message_file.puts 'Verbatim Birth Place NOT in Birth Place '
      message_file.puts diff_verbatim_birth_place

      time_elapsed = Time.now - time_start
      p "Finished #{num} places in #{time_elapsed}"
    end
  end
end
