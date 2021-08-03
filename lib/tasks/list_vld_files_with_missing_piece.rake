desc "List VLD files with missing Piece"
task :list_vld_files_with_missing_piece => :environment do

  file_for_warning_messages = "log/list_vld_files_with_missing_piece.log"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )  unless File.exists?(file_for_warning_messages)
  message_file = File.new(file_for_warning_messages, "w")
  p "Started VLD Files with Missing Piece List"
  message_file.puts  "VLD Files with Missing Piece List"
  vld_files_cnt = 0
  vld_piece_missing_cnt = 0
  message_file.puts  "Chapman Code,County Coordinator,Email,VLD File Name,Year,Piece Number"
  Freecen1VldFile.all.order_by(dir_name: 1, file_name: 1).each do |file|
    vld_files_cnt += 1
    piece = FreecenPiece.where(chapman_code: file.dir_name, piece_number: file.piece, year: file.full_year, status: 'Online').first
    if piece.blank?
      vld_piece_missing_cnt += 1
      cnty = County.where(:chapman_code => file.dir_name)
      coord = cnty.coordinator_name(file.dir_name)
      email = cnty.coordinator_email_address(file.dir_name)
      message_file.puts  "#{file.dir_name},#{coord},#{email},#{file.file_name},#{file.full_year},#{file.piece}"
    end
  end
  message_file.puts  "Found #{vld_piece_missing_cnt} VLD files with missing Piece"
  p "Processed #{vld_files_cnt} VLD files"
  p "Found #{vld_piece_missing_cnt} VLD files with missing Piece"
  p "Finished VLD files with missing Piece List - see log/list_vld_files_with_missing_piece.log for output"
end
