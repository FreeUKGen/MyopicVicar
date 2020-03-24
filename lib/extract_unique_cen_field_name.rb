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
      invalid_birth_county = []
      codes = ChapmanCode.values + ['ENG', 'IRL', 'SCT', 'WAL']
      birth_county.each do |county|
        num = num + 1
        break if num == limit
        verbatim_birth_place = FreecenIndividual.where(birth_county: county).distinct(:verbatim_birth_place)
        birth_place = FreecenIndividual.where(birth_county: county).distinct(:birth_place)
        invalid_birth_county << county unless codes.include?(county)

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
      message_file.puts 'Invalid Birth Counties'
      message_file.puts invalid_birth_county
      birth_individuals = {}
      invalid_birth_county.each do |invalid_county|
        birth_individuals[invalid_county] = FreecenIndividual.where(birth_county: invalid_county).count
      end
      invalid_files = {}
      unique_invalid_files = []
      invalid_birth_county.each do |invalid_county|
        files = []
        FreecenIndividual.where(birth_county: invalid_county).each do |ind|
          vld = ind.freecen1_vld_entry
          vld_file = vld.freecen1_vld_file if vld.present?
          file_name = vld_file.file_name if vld_file.present?
          files << file_name unless files.include?(file_name)
        end
        invalid_files[invalid_county] = files
        unique_invalid_files = unique_invalid_files + files
      end
      unique_invalid_files = unique_invalid_files.uniq
      extended_file_list = []
      unique_invalid_files.each do |bad_file|
        vld_file = Freecen1VldFile.find_by(file_name: bad_file)
        piece = FreecenPiece.find_by(piece_number: vld_file.piece.to_i, year: vld_file.full_year) if vld_file.present?
        if piece.present?
          extended_file_list << "#{bad_file} #{piece.chapman_code} #{piece.year} #{piece.district_name} #{piece.piece_number}"
        end
      end
      message_file.puts 'Invalid Individuals'
      message_file.puts birth_individuals
      message_file.puts 'Invalid files'
      message_file.puts invalid_files
      message_file.puts 'Unique invalid files'
      message_file.puts extended_file_list

      # .................................Repeat for Verbatum.......................................................
      invalid_birth_county = []
      codes = ChapmanCode.values + ['ENG', 'IRL', 'SCT', 'WAL']
      verbatim_birth_county.each do |county|
        num = num + 1
        break if num == limit
        # verbatim_birth_place = FreecenIndividual.where(birth_county: county).distinct(:verbatim_birth_place)
        # birth_place = FreecenIndividual.where(birth_county: county).distinct(:birth_place)
        invalid_birth_county << county unless codes.include?(county)

      end
      #message_file.puts 'Invalid Verbatim Birth Counties'
      #message_file.puts invalid_birth_county
      birth_individuals = {}
      invalid_birth_county.each do |invalid_county|
        birth_individuals[invalid_county] = FreecenIndividual.where(birth_county: invalid_county).count
      end
      invalid_files = {}
      unique_invalid_files = []
      invalid_birth_county.each do |invalid_county|
        files = []
        FreecenIndividual.where(birth_county: invalid_county).each do |ind|
          vld = ind.freecen1_vld_entry
          vld_file = vld.freecen1_vld_file if vld.present?
          file_name = vld_file.file_name if vld_file.present?
          files << file_name unless files.include?(file_name)
        end
        invalid_files[invalid_county] = files
        unique_invalid_files = unique_invalid_files + files
      end
      unique_invalid_files = unique_invalid_files.uniq
      extended_file_list = []
      unique_invalid_files.each do |bad_file|
        vld_file = Freecen1VldFile.find_by(file_name: bad_file)
        piece = FreecenPiece.find_by(piece_number: vld_file.piece.to_i, year: vld_file.full_year) if vld_file.present?
        if piece.present?
          extended_file_list << "#{bad_file} #{piece.chapman_code} #{piece.year} #{piece.district_name} #{piece.piece_number}"
        end
      end
      message_file.puts 'Individuals with invalid Verbatim Birth'
      message_file.puts birth_individuals
      message_file.puts 'Invalid files'
      message_file.puts invalid_files
      message_file.puts 'Unique invalid files'
      message_file.puts extended_file_list


      time_elapsed = Time.now - time_start
      p "Finished #{num} places in #{time_elapsed}"
    end
  end
end
