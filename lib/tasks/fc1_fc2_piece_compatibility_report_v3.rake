desc "fc1_fc2_piece_compatibility_report_v3: Check integrity of FC1 piece places when compared to FC2 places - NOTE: Does not check Ireland"
task fc1_fc2_piece_compatibility_report_v3:  :environment do

  report_file = "log/fc1_fc2_piece_compatibility_report_v3.csv"
  summary_file = "log/fc1_fc2_piece_compatibility_summary_v3.csv"
  FileUtils.mkdir_p(File.dirname(report_file) )  unless File.exists?(report_file)
  FileUtils.mkdir_p(File.dirname(summary_file) )  unless File.exists?(summary_file)
  detail_file = File.new(report_file, "w")
  summary_file = File.new(summary_file, "w")


  p "*** Started FC1 FC2 Piece Place Compatibility Report V3"
  total_fc1_piece_cnt = 0
  total_match_cnt = 0
  fc1_piece_cnt = 0
  place_match = false
  match_cnt = 0
  detail_file.puts  "FC1 Chapman Code,Year,FC1 Piece Number,Online,Review,Message,Review comments"
  summary_file.puts  "Country,FC1 Chapman Code,FC1 Piece Records Processed,FC1 Match Place Name,Percentage match"
  this_county = ''
  this_country = ''

  FreecenPiece.where(:chapman_code.exists => true).order_by(chapman_code: 1, year: 1, piece_number: 1).each do |fc1_piece|

    total_fc1_piece_cnt += 1
    if this_county == ''
      p "Processing - #{fc1_piece.chapman_code}"
      this_county = fc1_piece.chapman_code
      this_country = fc1_piece.place_country
    else
      if this_county != fc1_piece.chapman_code
        percentage_match = (match_cnt * 100 / fc1_piece_cnt).round(1).to_s
        summary_file.puts  "#{this_country},#{this_county},#{fc1_piece_cnt},#{match_cnt},#{percentage_match}"
        fc1_piece_cnt = 0
        match_cnt = 0
        p "Processing - #{fc1_piece.chapman_code}"
        this_county = fc1_piece.chapman_code
        this_country = fc1_piece.place_country
      end
    end
    fc1_piece_cnt += 1
    message = ''
    review_reqd = 'N'
    fc1_piece.status == 'Online' ? fc1_status = 'Y' : fc1_status = 'N'
    next if fc1_piece.freecen1_filename.blank?

    year, number = Freecen2Piece.extract_freecen2_piece_vld(fc1_piece.freecen1_filename)
    fc2_piece = Freecen2Piece.find_by(chapman_code: fc1_piece.chapman_code, year: year, number: number)


    if fc2_piece.blank?

      review_reqd = 'Y'
      message += ' FC2 Piece missing '
    else

      match_cnt += 1
      total_match_cnt += 1

    end

    detail_file.puts  "#{fc1_piece.chapman_code},#{year},#{number},#{fc1_status},#{review_reqd},#{message}"

  end
  percentage_match = (match_cnt * 100 / fc1_piece_cnt).round(1).to_s
  summary_file.puts  "#{this_country},#{this_county},#{fc1_piece_cnt},#{match_cnt},#{percentage_match}"
  percentage_match = (total_match_cnt * 100 / total_fc1_piece_cnt).round(1).to_s
  summary_file.puts  "ALL,ALL,#{total_fc1_piece_cnt},#{total_match_cnt},#{percentage_match}"
  p "*** Total FC1 Pieces processed = #{total_fc1_piece_cnt}"
  p "*** Finished FC1 FC2 Piece Place Compatibility Report V2 - see log/fc1_fc2_piece_compatibility_report_v2.csv (and fc1_fc2_piece_compatibility_summary_v2.csv) for output"
end
