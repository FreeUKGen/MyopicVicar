desc "Get a list of partial piece CSV files"
task :list_partial_piece_csvfiles => :environment do

  file_for_warning_messages = "log/partial_piece_csvfiles.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
  message_file = File.new(file_for_warning_messages, "w")
  p "Started Partial Piece CSV files List"
  message_file.puts  "Started Partial Piece CSV files List"
  partial_files = 0
  message_file.puts  "Chapman Code,County Coordinator,Email,CSV File Name,Date Incorporated"
  FreecenCsvFile.where(:incorporated => 'true').all.order_by(chapman_code: 1, file_name: 1).each do |file|
    piece = Freecen2Piece.find_by(_id: file.freecen2_piece_id)
    if file.is_whole_piece(piece).blank? && piece.status.blank?
      partial_files += 1
      cnty = County.where(:chapman_code => file.chapman_code)
      coord = cnty.coordinator_name(file.chapman_code)
      email = cnty.coordinator_email_address(file.chapman_code)
      incorp_date = file.incorporated_date.to_datetime.strftime("%d/%b/%Y %R")
      message_file.puts  "#{file.chapman_code},#{coord},#{email},#{file.file_name},#{incorp_date}"
    end
  end
  message_file.puts  "Found #{partial_files} partial piece CSV files that are incorporated but Piece status is not set."
  p "Found #{partial_files} partial piece CSV files that are incorporated but Piece status is not set."
  p "Finished Partial Piece CSV files List - see log/partial_piece_csvfiles.log for output"
end
