desc "Update piece online times from FC1 mysql output"
task :update_pieces_fc1_online_times, [:csv_file] => :environment do |t, args|
  #to create the csv file, open a mysql session for FC1 and do the following:
  #SELECT * FROM Pieces INTO OUTFILE '/tmp/freecen_pieces.csv' FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';
  if args[:csv_file].empty?
    puts "ERROR! no input.csv file specified."
    puts "usage rake update_pieces_fc1_online_times[input.csv]"
    puts "(See comments in freecen_pieces.rake for how to create the csv)"
  else
    require "csv"
    # use iso-8859-1 because the FreeCen1 mysql database is Latin1, not UTF-8
    raw_file = File.read(args[:csv_file], :encoding => 'iso-8859-1')
    raw_file=raw_file.encode('utf-8', :undef => :replace)
    csv_rows = CSV.parse(raw_file) unless raw_file.nil?
    if csv_rows.nil? || csv_rows.length < 1
      puts "ERROR! no csv rows parsed by freecen_pieces.rake - see comments for usage"
    else
      puts "read #{csv_rows.length} rows from the csv file."
      csv_rows.each_with_index do |row, idx|
        #[0]country [1]yearnum [2]piecenum [3]suffix [4]sctpar [5]county
        #[6]districtname [7]subplaces [8]status [9]notes [10]onlineTime
        if row[0]!='ENW' && row[0]!='SCT'
          puts "WARNING: unrecognized series in row #{idx} col 0. Row ignored."
          next
        end
        #assign variables from csv columns
        series = row[0]
        yy = (row[1].to_i * 10 + 1831) #convert year num (1-9) to 1841..1891
        piecenum = row[2]
        sfx = row[3]
        sfx.strip! unless sfx.nil?
        sfx = nil if sfx.blank?
        sctpar = row[4]
        sctpar = nil if sctpar.blank? || 0==sctpar || '0'==sctpar
        cty = row[5]
        dist = row[6]
        pstatus = row[8]
        notes= row[9]
        olt = row[10].to_i
        #find the freecen_piece associated with this row of the csv
        piece = FreecenPiece.where(piece_number:piecenum, chapman_code:cty, year:yy, suffix:sfx, parish_number:sctpar)
        if piece.count > 1
          puts "*** ERROR: #{piece.count} pieces match criteria for line #{idx} (not updating them)"
          
          piece.each do |pp|
            puts "  _id:#{pp[:_id]} yy:#{pp[:year]} cty:#{pp[:chapman_code]} piece:#{pp[:piece_number]} sfx:#{pp[:suffix]} sctpar:#{pp[:parish_number]} dist:#{pp[:district_name]}}}"
          end
          next
        end
        piece = piece.first
        if piece.nil?
          puts "*** ERROR: piece not found for line #{idx+1}. (yy=#{yy} cty=#{cty} piece=#{piecenum} sfx=#{sfx} sctpar=#{sctpar} dist=#{dist}"
          next
        end
        #update the online time of the freecen_piece
        if piece[:online_time] != olt
          piece[:online_time] = olt
          piece.save!
        end

      end

    end
  end
end
