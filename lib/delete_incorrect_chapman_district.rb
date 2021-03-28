class DeleteIncorrectChapmanDistrict
  def self.process(chapman_code)
    incorrect_chapman = chapman_code.to_s
    file_for_messages = Rails.root.join('log', "delete_incorrect_chapman_districts_#{incorrect_chapman}.log")
    message_file = File.new(file_for_messages, 'w')
    message_file.puts "Processing incorrect chapman code #{incorrect_chapman}"
    Freecen2District.where(chapman_code: incorrect_chapman).no_timeout.each do |district|
      district.freecen2_pieces.no_timeout.each do |piece|
        piece.freecen2_civil_parishes.no_timeout.each(&:delete)
        piece.delete
      end
      district.delete
    end
    message_file.puts "Finished"
  end
end
