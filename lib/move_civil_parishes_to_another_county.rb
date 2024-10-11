class MoveCivilParishesToAnotherCounty
  def self.slurp_the_csv_file(filename)
    begin
      #we slurp in the full csv file
      array_of_data_lines = CSV.read(filename)
      success = true
    rescue Exception => msg
      success = false
      message = "#{msg}, #{msg.backtrace.inspect}"
      p message
      success = false
    end
    [success, array_of_data_lines]
  end

  def self.process(limit, file_name)
    #The purpose of this clean up utility is to eliminate search records that are unconnected with an entry. Or an entry without a batch
    limit = limit.to_i
    file_name = file_name.to_s
    list = Rails.root.join('tmp', file_name)
    time_start = Time.new
    records = 0
    fixed = 0
    if File.file?(list)
      file_for_warning_messages = "log/#{file_name}.txt"
      FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
      message_file = File.new(file_for_warning_messages, 'w')
      message_file.puts "Move Civil Parishes To Another County with a limit of #{limit}"


      success, array = slurp_the_csv_file(list)

      array.each do |move|
        records += 1
        next if records == 1

        break if records >= limit

        message_file.puts "#{move}"
        number_of_civil_parishes = move.length - 3
        fixed += 1
        original_piece_number = move[1].to_s
        original_chapman_code = move[0].to_s.upcase
        message_file.puts "ERROR: Invalid Chapman Code for original #{original_chapman_code} " unless ChapmanCode.value?(original_chapman_code)
        next unless ChapmanCode.value?(original_chapman_code)

        new_chapman_code = move[2].to_s.upcase
        message_file.puts "ERROR: Invalid Chapman Code for new #{new_chapman_code} " unless ChapmanCode.value?(new_chapman_code)
        next unless ChapmanCode.value?(new_chapman_code)

        year, piece_number, _field = Freecen2Piece.extract_year_and_piece(original_piece_number, original_chapman_code)
        piece = Freecen2Piece.find_by(chapman_code: original_chapman_code, number: piece_number, year: year)
        message_file.puts "ERROR: Piece #{piece_number} not found in #{original_chapman_code} for #{year}" if piece.blank?
        next if piece.blank?

        original_district = piece.freecen2_district
        message_file.puts "ERROR: Piece #{piece_number} does not have a district" if original_district.blank?
        next if original_district.blank?

        original_place = piece.freecen2_place
        message_file.puts "WARNING: Piece #{piece_number} does not have a Freecen2Place; you will need to add one" if original_place.blank?

        parishes = 0
        while parishes < number_of_civil_parishes
          parishes += 1
          original_parish = move[parishes + 2].to_s
          message_file.puts "No civil Parish" if original_parish.blank?
          next if original_parish.blank?

          message_file.puts "Moving #{original_parish} from #{piece.number} in #{original_district.name} in #{original_chapman_code} for #{year} to #{new_chapman_code}"
          puts "Moving #{original_parish} from #{piece.number} in #{original_district.name} in #{original_chapman_code} for #{year} to #{new_chapman_code}"
          check_parish = Freecen2CivilParish.find_by(freecen2_piece_id: piece.id, standard_name: Freecen2Place.standard_place(original_parish))

          if check_parish.blank?
            message_file.puts "ERROR: #{original_parish} is not in the civil parish list for #{piece_number} in #{original_chapman_code}"
            puts "#{original_parish} is not in the civil parish list for #{piece_number} in #{original_chapman_code}"
            next

          end

          if check_parish.freecen_csv_entries.present?
            message_file.puts "ERROR: #{original_parish} has freecen_csv_entries and cannot be moved"
            puts "#{original_parish} has freecen_csv_entries and cannot be moved"
            next

          end
          new_district = Freecen2District.find_by(chapman_code: new_chapman_code, name: original_district.name, year: year)
          if new_district.blank?
            message_file.puts "District #{original_district.name} is not in #{new_chapman_code} for year #{year} so creating"
            new_county = County.find_by(chapman_code: new_chapman_code)
            puts "District #{original_district.name} is not in #{new_chapman_code} for year #{year} so creating"
            new_district = Freecen2District.new(name: original_district.name, chapman_code: new_chapman_code,
                                                year: year, tnaid: original_district.tnaid, standard_name:  original_district.standard_name,
                                                type: original_district.type)
            new_district.save
            new_district.update(freecen2_place_id: original_place.id) if original_place.present?
            new_district.update(county_id: new_county.id) if new_county.present?
            message_file.puts "District #{new_district.name} in #{new_chapman_code} for year #{year} created"
            puts "District #{new_district.name} in #{new_chapman_code} for year #{year} created"
          end
          new_piece_number = piece_number + 'A'
          new_piece = Freecen2Piece.find_by(chapman_code: new_chapman_code, number: new_piece_number, year: year)
          if new_piece.blank?
            message_file.puts "Piece #{new_piece_number} is not in  #{new_district.name}  for #{new_chapman_code} for year #{year} so creating"
            puts "Piece #{new_piece_number} is not in  #{new_district.name}  for #{new_chapman_code} for year #{year} so creating"
            new_piece = Freecen2Piece.new(name: piece.name, chapman_code: new_chapman_code, number: new_piece_number,
                                          year: year, tnaid: original_district.tnaid, standard_name:  piece.standard_name,
                                          code: piece.code, freecen2_district_id: new_district.id, admin_county: new_chapman_code)
            new_piece.save
            new_piece.update(freecen2_place_id: piece.freecen2_place.id) if piece.freecen2_place.present?
            message_file.puts "Piece #{new_piece_number} created for #{new_district.name} in #{new_chapman_code} for year #{year}"
            puts "Piece #{new_piece_number} created for #{new_district.name} in #{new_chapman_code} for year #{year}"
          end
          existing_parishes = []
          new_piece.freecen2_civil_parishes.each do |parish|
            existing_parishes << parish.standard_name
          end
          puts "ERROR: Civil Parish  #{original_parish} already exists in #{new_piece_number} for #{new_district.name} in #{new_chapman_code} for year #{year}" if existing_parishes.include?(Freecen2Place.standard_place(original_parish))
          next if existing_parishes.include?(Freecen2Place.standard_place(original_parish))

          check_parish.update(freecen2_piece_id: new_piece.id, chapman_code: new_chapman_code)
          message_file.puts "#{original_parish} moved to #{new_piece_number} for #{new_district.name} in #{new_chapman_code} for #{year}"
          check_parish.reload
          puts "#{original_parish} moved to #{new_piece_number} for #{new_district.name} in #{new_chapman_code} for #{year}"
          civil_parish_names = new_piece.add_update_civil_parish_list
          new_piece.update(civil_parish_names: civil_parish_names)
          civil_parish_names = piece.add_update_civil_parish_list
          piece.update(civil_parish_names: civil_parish_names)
        end
      end
    end
    time_diff = Time.new - time_start
    average_record = time_diff * 1000 / records
    p 'finished'
    p "#{fixed} fixed in #{records} at average time of #{average_record}"
  end
end
