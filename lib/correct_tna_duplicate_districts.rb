class CorrectTnaDuplicateDistricts
  def self.process(len, year, chapman_code)
    limit = len.to_i
    year = year.to_s
    chapman_code = chapman_code.to_s
    file_for_messages = 'log/correct_tna_duplicate_districts.log'
    message_file = File.new(file_for_messages, 'w')
    message_file.puts "Processing #{limit} districts for #{year} in #{chapman_code}"
    number = 0
    corrected = 0
    districts = Freecen2District.where(year: year, chapman_code: chapman_code).order_by(name: 1).distinct(:name)
    districts.each do |district|
      number += 1
      break if number >= limit

      duplicates = Freecen2District.where(year: year, chapman_code: chapman_code, name: district).all
      duplicates.count
      next if duplicates.count == 1

      duplicates.each_with_index do |duplicate, index|
        @new_district_id = duplicate.id if index == 0
        next if index == 0

        corrected += 1
        piece = duplicate.freecen2_pieces
        piece[0].update_attributes(freecen2_district_id: @new_district_id)
        duplicate.delete
        message_file.puts " #{duplicate.name},  #{piece.name}, #{piece.number}"
      end
    end
    message_file.puts "Processed #{number} districts and corrected #{corrected}"
    p "Processed #{number} districts and corrected #{corrected}"
  end
end
