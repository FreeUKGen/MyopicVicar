namespace :freecen do

  desc "Polulate Freecen2_piece_admin_county for issue 1544"
  task populate_freecen2_piece_admin_county:  :environment do

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

    def self.output_to_log(log_file, message)
      log_file.puts message.to_s
      p message
    end

    #
    # START
    #

    recs_updated = 0
    total_recs = Freecen2Piece.all.count
    log_file_name = 'log/Populate_freecen2_piece_admin_county.log'
    FileUtils.mkdir_p(File.dirname(log_file_name)) unless File.exist?(log_file_name)
    log_file = File.new(log_file_name, 'w')

    message = '*** Started population of Freecen2_piece admin_county'
    output_to_log(log_file, message)

    Freecen2Piece.no_timeout.each do |piece|
      piece.set(admin_county: piece.chapman_code)
      recs_updated += 1
      if (recs_updated % 500).zero?
        message = "1. #{recs_updated} records updated from #{total_recs} in Freecen2Piece collection"
        output_to_log(log_file, message)
      end
    end
    message = "1. #{recs_updated} records updated from #{total_recs} in Freecen2Piece collection"
    output_to_log(log_file, message)

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
        piece_rec_cnt = Freecen2Piece.where(chapman_code: chapman_code, number: piece_number).count
        if piece_rec_cnt == 1
          piece_rec = Freecen2Piece.find_by(chapman_code: chapman_code, number: piece_number)
          piece_rec.set(admin_county: admin_county)
          recs_updated += 1
          if (recs_updated % 100).zero?
            message = "2. #{recs_updated} records updated from CSV file data"
            output_to_log(log_file, message)
          end
        else
          if piece_rec_cnt.zero?
            message = "Piece not found - #{chapman_code},#{piece_number},#{admin_county}"
          else
            message = "Piece duplicates found - #{chapman_code},#{piece_number},#{admin_county}"
          end
          output_to_log(log_file, message)
        end
      end
    else
      message = "**** ERROR - #{csv_filename} does not exist in Rails root tmp folder"
      output_to_log(log_file, message)
    end
    message = "2. #{recs_updated} records updated from #{recs_read} CSV file data records"
    output_to_log(log_file, message)
    message = '*** Finished population of Freecen2_piece admin_county'
    output_to_log(log_file, message)

  end
end
