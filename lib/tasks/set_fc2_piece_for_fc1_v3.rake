desc "Sst the fc2 piece in fc1_piece"
task set_fc2_piece_for_fc1_v3:  :environment do

  report_file = "log/set_fc1_fc2_piece_v3.csv"
  summary_file = "log/set_fc1_fc2_piece_summary_v3.csv"
  FileUtils.mkdir_p(File.dirname(report_file) )  unless File.exists?(report_file)
  FileUtils.mkdir_p(File.dirname(summary_file) )  unless File.exists?(summary_file)
  detail_file = File.new(report_file, "w")
  summary_file = File.new(summary_file, "w")


  p "*** Started FC1 FC2 Piece setting V3"
  total_fc1_piece_cnt = 0
  total_match_cnt = 0
  fc1_piece_cnt = 0
  place_match = false
  match_cnt = 0
  detail_file.puts  "FC1 Chapman Code,Year,FC1 Piece Number,fc1 Filename,fc1 id,Online,Fc2 number,fc2 id,Review,Message,Review comments"
  summary_file.puts  "Country,FC1 Chapman Code,FC1 Piece Records Processed,FC1 Match Place Name,Percentage match"
  this_county = ''
  this_country = ''
  codes = ChapmanCode.remove_codes(ChapmanCode::CODES)
  codes = codes["Scotland"].values

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
    fc1_piece.status == 'Online' ? fc1_status = 'Y' : fc1_status = 'N'
    piece2_number = Freecen2Piece.calculate_freecen2_piece_number(fc1_piece)

    fc2_piece = Freecen2Piece.find_by(year: fc1_piece.year, number: piece2_number)

    if fc2_piece.present?
      review_reqd = 'N'
      match_cnt += 1
      total_match_cnt += 1
    else
      piece_number_hold = piece2_number
      piece2_number += 'A'
      fc2_piece = Freecen2Piece.find_by( year: fc1_piece.year, number: piece2_number)
      if fc2_piece.present?
        review_reqd = 'N'
        match_cnt += 1
        total_match_cnt += 1
      else
        piece2_number = piece_number_hold + 'B'
        fc2_piece = Freecen2Piece.find_by( year: fc1_piece.year, number: piece2_number)
        if fc2_piece.present?
          review_reqd = 'N'
          match_cnt += 1
          total_match_cnt += 1
        else
          piece2_number = piece_number_hold + 'C'
          fc2_piece = Freecen2Piece.find_by(year: fc1_piece.year, number: piece2_number)
          if fc2_piece.present?
            review_reqd = 'N'
            match_cnt += 1
            total_match_cnt += 1
          else
            review_reqd = 'Y'
            message += ' FC2 Piece missing '
          end
        end
      end
    end
    fc2_piece_id = fc2_piece.present? ? fc2_piece._id : ''
    fc1_piece.update_attributes(freecen2_piece_id: fc2_piece._id) if fc2_piece.present?

    if fc2_piece.present?
      fc2_district = fc2_piece.freecen2_district
    else
      review_reqd = 'Y'
      message += ' FC2 District missing '
    end
    if fc2_district.present?
      fc2_place = fc2_district.freecen2_place
    else
      review_reqd = 'Y'
      message += ' FC2 District Place missing '
    end
    fc1_piece.update_attributes(freecen2_place_id: fc2_place._id) if fc2_place.present?
    detail_file.puts  "#{fc1_piece.chapman_code},#{fc1_piece.year},#{fc1_piece.piece_number},#{fc1_piece.freecen1_filename},#{fc1_piece._id} #{fc1_status},#{piece2_number},#{fc2_piece_id}, #{review_reqd},#{message}"
  end
  percentage_match = (match_cnt * 100 / fc1_piece_cnt).round(1).to_s
  summary_file.puts  "#{this_country},#{this_county},#{fc1_piece_cnt},#{match_cnt},#{percentage_match}"
  percentage_match = (total_match_cnt * 100 / total_fc1_piece_cnt).round(1).to_s
  summary_file.puts  "ALL,ALL,#{total_fc1_piece_cnt},#{total_match_cnt},#{percentage_match}"
  p "*** Total FC1 Pieces processed = #{total_fc1_piece_cnt}"
  p "*** Finished FC1 FC2 Piece setting V3 - see log/set_fc1_fc2_piece_v3.csv (and log/set_fc1_fc2_piece_summary_v3.csv) for output"
end
