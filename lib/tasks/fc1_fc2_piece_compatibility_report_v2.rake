desc "fc1_fc2_piece_compatibility_report_v2: Check integrity of FC1 piece places when compared to FC2 places - NOTE: Does not check Ireland"
task fc1_fc2_piece_compatibility_report_v2:  :environment do

  report_file = "log/fc1_fc2_piece_compatibility_report_v2.csv"
  summary_file = "log/fc1_fc2_piece_compatibility_summary_v2.csv"
  FileUtils.mkdir_p(File.dirname(report_file) )  unless File.exists?(report_file)
  FileUtils.mkdir_p(File.dirname(summary_file) )  unless File.exists?(summary_file)
  detail_file = File.new(report_file, "w")
  summary_file = File.new(summary_file, "w")


  p "*** Started FC1 FC2 Piece Place Compatibility Report V2"
  total_fc1_piece_cnt = 0
  total_match_cnt = 0
  fc1_piece_cnt = 0
  place_match = false
  match_cnt = 0
  detail_file.puts  "Country,FC1 Chapman Code,Year,FC1 Piece Number,Online,FC1 Place Name,Message,Review comments"
  summary_file.puts  "Country,FC1 Chapman Code,FC1 Piece Records Processed,FC1 Match Place Name,Percentage match"
  this_county = ''
  this_country = ''

  FreecenPiece.where(:chapman_code.exists => true ).order_by(chapman_code: 1, year: 1, piece_number: 1).each do |fc1_piece|
    if fc1_piece.status == 'Online'
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
      fc1_place = Place.find_by(id: fc1_piece.place_id)
      if fc1_place.blank?
        fc1_place_name = ''
        review_reqd = 'Y'
        message += ' FC1 Place missing +'
      else
        fc1_place_name = fc1_place.place_name
        place_match, fc2_place_id = Freecen2Place.valid_place(this_county,fc1_place_name)
        unless place_match
          # try to match after removing numbers in FC1 place name
          fc1_replaced_1 = fc1_place_name.gsub(/\s\d\D\d/,"")      # e.g. 1C1
          fc1_replaced_2 = fc1_replaced_1.gsub(/\s\d\D/,"")      # e.g. 1A
          fc1_try_match = fc1_replaced_2.gsub(/\d\s/,"")         # e.g. 1
          place_match, fc2_place_id = Freecen2Place.valid_place(this_county,fc1_try_match)
        end
        if place_match
          match_cnt += 1
          total_match_cnt += 1
          fc2_place = Freecen2Place.find_by(id: fc2_place_id)
          fc2_place_name = fc2_place.place_name
          message += " Place name match (#{fc2_place_name} [#{fc2_place_id}]) +"
        else
          review_reqd = 'Y'
          message += ' Unable to match place name +'
        end
      end
      place_name = '"' + fc1_place_name + '"'   # some place names have a comma in them!
      out_message = '"' +  message[1..-2] + '"'
      detail_file.puts  "#{fc1_piece.place_country},#{fc1_piece.chapman_code},#{fc1_piece.year},#{fc1_piece.piece_number},#{fc1_status},#{place_name},#{out_message}" unless review_reqd == 'N'
    end
  end
  percentage_match = (match_cnt * 100 / fc1_piece_cnt).round(1).to_s
  summary_file.puts  "#{this_country},#{this_county},#{fc1_piece_cnt},#{match_cnt},#{percentage_match}"
  percentage_match = (total_match_cnt * 100 / total_fc1_piece_cnt).round(1).to_s
  summary_file.puts  "ALL,ALL,#{total_fc1_piece_cnt},#{total_match_cnt},#{percentage_match}"
  p "*** Total FC1 Pieces processed = #{total_fc1_piece_cnt}"
  p "*** Finished FC1 FC2 Piece Place Compatibility Report V2 - see log/fc1_fc2_piece_compatibility_report_v2.csv (and fc1_fc2_piece_compatibility_summary_v2.csv) for output"
end
