class DeleteIncorrectTnaDistrict
  def self.process(incorrect_distict)
    incorrect_distict = incorrect_distict.to_s
    file_for_messages = Rails.root.join('log', "delete_incorrect_tna_districts_#{incorrect_distict}.log")
    message_file = File.new(file_for_messages, 'w')
    message_file.puts "Processing incorrect districts #{incorrect_distict}"
    district = Freecen2District.find_by(_id: incorrect_distict)
    chapman_code = district.chapman_code
    district.freecen2_pieces.no_timeout.each do |piece|
      piece.freecen2_civil_parishes.no_timeout.each(&:delete)
      piece.delete
    end
    district.delete
    message_file.puts "Finished"
    UserMailer.forced_district_deletion(chapman_code, district.name, district.year).deliver_now
  end
end
