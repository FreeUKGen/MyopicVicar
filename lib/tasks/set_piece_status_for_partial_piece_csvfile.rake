desc "Set Freecen2Piece status and FreecenCSVFile completes_piece for a specific CSV File"

task :set_piece_status_for_partial_piece_csvfile, [:filename, :status]  => [:environment] do |t, args|

  puts "Set Piece Status for partial piece CSV file: Started."

  if args[:filename].blank? or args[:status].blank?
    puts "ERROR: File name (xxx.csv) and Status (Online or Part) must be provided as arguments"
  else
    if args[:status] != "Online" && args[:status] != "Part"
      puts "ERROR: Status invalid - must be Online or Part"
    else
      csvfile = FreecenCsvFile.find_by(file_name: args[:filename])
      if csvfile.blank?
        puts "ERROR: File #{args[:filename]} does not exist"
      else
        piece = Freecen2Piece.find_by(_id: csvfile.freecen2_piece_id)
        if csvfile.is_whole_piece(piece)
          puts "ERROR: File #{args[:filename]} is not partial piece file"
        else
          if csvfile.incorporated.blank?
            puts "ERROR: File #{args[:filename]} is not incorporated"
          else
            piece.update_attributes(status: args[:status], status_date: csvfile.incorporated_date)
            csvfile.update_attributes(completes_piece: true) if args[:status] == "Online"
            puts "Success: Piece status for File #{args[:filename]} updated to #{args[:status]}."
          end
        end
      end
    end
  end
  puts  "Set Piece Status for partial piece CSV file: Finished."
end
