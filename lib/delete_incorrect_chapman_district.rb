class DeleteIncorrectChapmanDistrict
  def self.process(chapman_code)
    incorrect_chapman = chapman_code.to_s
    file_for_messages = Rails.root.join('log', "delete_incorrect_chapman_districts_#{incorrect_chapman}.log")
    message_file = File.new(file_for_messages, 'w')
    message_file.puts "Processing incorrect chapman code #{incorrect_chapman}"
    Freecen2District.where(chapman_code: incorrect_chapman).no_timeout.each do |district|
      FreecenPiece.where(freecen2_district_id: district.id).no_timeout.each do |piece|
        FreecenCivilParish.where(freecen2_piece_id: piece.id).no_timeout.each(&:delete)
        piece.delete
      end
      district.delete
    end
    message_file.puts "Finished"
  end
end
