desc "Set Freecen2Piece status and FreecenCSVFile completes_piece."

task set_piece_status_for_whole_piece_csvfiles:  :environment do

  puts "Set Piece Status: Started."

  start_time = Time.now
  csvfile_whole = 0
  csvfile_partial = 0
  csvfile_whole_incorporated = 0
  csvfile_records_updated = 0
  piece_records_updated = 0

  FreecenCsvFile.no_timeout.each do |csvfile|
    piece = Freecen2Piece.find_by(_id: csvfile.freecen2_piece_id)
    if csvfile.is_whole_piece(piece)
      csvfile_whole += 1
      csvfile_records_updated += 1 if csvfile.update_attributes(completes_piece: true)
      if piece.status.blank? && csvfile.incorporated
        csvfile_whole_incorporated  += 1 if csvfile.incorporated
        if piece.update_attributes(status: "Online", status_date: csvfile.incorporated_date)
          puts "County: #{csvfile.chapman_code} - Piece: #{piece.number} status updated to Online"
          piece_records_updated  += 1
        end
      end
    else
      csvfile_partial += 1
    end
  end


  puts "Set Piece Status: Found #{csvfile_whole} Whole Piece CSV files and #{csvfile_partial} Partial Piece CSV files"
  puts "Set Piece Status: Found #{csvfile_whole_incorporated} Incorporated Whole Piece CSV files with blank status"
  puts "Set Piece Status: #{csvfile_records_updated} csvfile records for whole pieces updated successfully"
  puts "Set Piece Status: #{piece_records_updated} piece records updated successfully"
  puts "Set Piece Status: Completed in #{Time.now - start_time} seconds."

end
