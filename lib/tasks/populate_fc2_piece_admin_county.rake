namespace :freecen do

  desc "Polulate Freecen2_piece_admin_county for issue 1544"
  task populate_freecen2_piece_admin_county:  :environment do
    p '*** Started population of Freecen2_piece admin_county'

    def self.read_in_admin_county_csv_file(csv_filename)
      begin
        array_of_data_lines = CSV.read(csv_filename)
        success = true
      rescue Exception => msg
        success = false
        message = "#{msg}, #{msg.backtrace.inspect}"
        p message
        success = false
      end
      [success, array_of_data_lines]
    end

    #
    # START
    #

    Freecen2Piece.no_timeout.each do |piece|
      piece.update_attributes(admin_county: piece.chapman_code)
    end

    csv_filename = Rails.root.join('tmp', 'FC2_PIECE_ADMIN_COUNTY.CSV')
    recs_read = 0
    recs_updated = 0
    if File.file?(csv_filename)
      _success, county_def_array = read_in_admin_county_csv_file(csv_filename)
      county_def_array.each do |rec|
        recs_read += 1
        next if recs_read == 1 # ignore header row

        chapman_code = rec[0].to_s
        piece_number = rec[1].to_s
        admin_county = rec[2].to_s
        piece_rec_cnt = FreeCen2Piece.where(chapman_code: chapman_code, number: piece_number).count
        if piece_rec_cnt == 1
          piece_rec = FreeCen2Piece.find_by(chapman_code: chapman_code, number: piece_number)
          piece_rec.update_attributes(admin_county: chapman_code)
          recs_updated += 1
        else
          p "Piece not found - #{chapman_code},#{piece_number},#{admin_county}" if piece_rec_cnt.zero?
          p "Piece duplicates found - #{chapman_code},#{piece_number},#{admin_county}" if piece_rec_cnt > 1
        end
      end
    else
      p "**** ERROR - #{csv_filename} does not exist in Rails root tmp folder"
    end

    p "Found #{recs_read - 1} data records in FC2_PIECE_ADMIN_COUNTY.CSV input file"
    p "Upadated #{recs_updated} from input file"
    p '*** Finished population of Freecen2_piece admin_county'
  end
end
