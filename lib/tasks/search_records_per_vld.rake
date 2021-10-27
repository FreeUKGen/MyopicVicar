
task :search_records_per_vld => :environment do
  file_for_warning_messages = "log/search_records_per_vld.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages)) unless File.exist?(file_for_warning_messages)
  message_file = File.new(file_for_warning_messages, "w")
  p 'Starting'
  num = 0
  Freecen1VldFile.each do |vld|
    num += 1
    p num
    piece = FreecenPiece.find_by(_id: vld.freecen_piece_id)
    place = Place.find_by(_id: piece.place_id) if piece.present?
    message_file.puts "#{place.chapman_code}, #{place.place_name}, #{piece.num_individuals}" if piece.present? && place.present?
  end
  p "finished"
end
