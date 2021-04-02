class DeleteIncorrectChapmanDistrict
  def self.process(chapman_code, year)
    incorrect_chapman = chapman_code.to_s
    file_for_messages = Rails.root.join('log', "delete_incorrect_chapman_districts_#{incorrect_chapman}.log")
    message_file = File.new(file_for_messages, 'w')
    message_file.puts "Processing incorrect chapman code #{incorrect_chapman}"
    Freecen2District.where(chapman_code: incorrect_chapman, year: year).no_timeout.each do |district|
      district.freecen2_pieces.no_timeout.each do |piece|
        Freecen2CivilParish.delete_all(freecen2_piece_id: piece.id)
      end
      Freecen2Piece.delete_all(freecen2_district_id: district.id)
      district.delete
    end
    message_file.puts "Finished"
  end
end
