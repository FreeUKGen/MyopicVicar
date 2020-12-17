class CorrectTnaDuplicateDistricts
  def self.process(len, year, chapman_code)
    limit = len.to_i
    year = year.to_s
    chapman_code = chapman_code.to_s
    file_for_messages = Rails.root.join('log', 'correct_tna_duplicate_districts.log')
    @number_of_line = 0
    message_file = File.new(file_for_messages, 'w')
    message_file.puts "Processing #{limit} districts for #{year} in #{chapman_code}"
    codes = []
    if chapman_code == 'ALL'
      codes = ChapmanCode.values
    else
      codes << chapman_code
    end
    p codes
    number = 0
    corrected = 0
    codes.each do |code|
      message_file.puts  "Processing #{code}"
      p "Processing #{code}"
      districts = Freecen2District.where(year: year, chapman_code: code).order_by(name: 1).distinct(:name)
      districts.each do |district|
        number += 1
        break if number >= limit

        duplicates = Freecen2District.where(year: year, chapman_code: code, name: district).all
        duplicates.count
        next if duplicates.count == 1

        duplicates.each_with_index do |duplicate, index|
          @new_district_id = duplicate.id if index.zero?
          next if index.zero?

          corrected += 1
          duplicate.freecen2_pieces.each do |piece|
            piece.update_attributes(freecen2_district_id: @new_district_id)
            message_file.puts " #{duplicate.name},  #{piece.name}, #{piece.number}"
          end
          duplicate.delete

        end
      end
    end
    message_file.puts "Processed #{number} districts and corrected #{corrected}"
    p "Processed #{number} districts and corrected #{corrected}"
  end
end
