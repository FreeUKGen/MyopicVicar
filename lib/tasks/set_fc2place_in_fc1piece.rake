desc "set_fc2place_in_fc1piece: Populate freecen2_place_id for all Online freecen_piece documents NOTE: Does not handle Ireland"
task set_fc2place_in_fc1piece:  :environment do

  log_file = "log/set_fc2place_in_fc1piece.csv"
  FileUtils.mkdir_p(File.dirname(log_file) )  unless File.exists?(log_file)
  log_file = File.new(log_file, "w")

  p "*** Started Population of freecen2_place_id in freecen_piece documents"
  log_file.puts  "Country,FC1 Chapman Code,Year,FC1 Piece Number,Online,FC1 Place Name,FC Place name, Review, Message,Review comments"
  total_fc1_piece_cnt = 0
  place_match = false
  total_match_cnt = 0
  this_county = ''

  FreecenPiece.where(:chapman_code.exists => true ).order_by(chapman_code: 1, year: 1, piece_number: 1).each do |fc1_piece|
    review_reqd = 'N'
    if fc1_piece.status == 'Online'
      message = ''
      total_fc1_piece_cnt += 1
      if this_county == '' || this_county != fc1_piece.chapman_code
        p "Processing - #{fc1_piece.chapman_code}"
        this_county = fc1_piece.chapman_code
      end
      fc1_place = Place.find_by(id: fc1_piece.place_id)
      if fc1_place.blank?
        fc1_place_name = ''
        review_reqd = 'Y'
        message += ' FC1 Place missing +'
      else
        fc1_place_name = fc1_place.place_name
        place_match, fc2_place_id = Freecen2Place.valid_place(this_county, fc1_place_name)
        unless place_match
          # try to match after removing numbers in FC1 place name
          fc1_replaced_1 = fc1_place_name.gsub(/\s\d\D\d/,"")      # e.g. 1C1
          fc1_replaced_2 = fc1_replaced_1.gsub(/\s\d\D/,"")      # e.g. 1A
          fc1_try_match = fc1_replaced_2.gsub(/\d\s/,"")         # e.g. 1
          place_match, fc2_place_id = Freecen2Place.valid_place(this_county, fc1_try_match)
        end
        if place_match
          total_match_cnt += 1
          fc2_place = Freecen2Place.find_by(id: fc2_place_id)
          fc2_place_name = fc2_place.place_name
          message += " Place name match (#{fc2_place_name} [#{fc2_place_id}]) +"
          fc1_piece.update_attributes(freecen2_place_id: fc2_place_id)
          if fc2_place.data_present == false
            fc2_place.data_present = true
            fc2_place_save_needed = true
          end
          if !fc2_place.cen_data_years.include?(fc1_piece.year)
            fc2_place.cen_data_years << fc1_piece.year
            fc2_place_save_needed = true
          end
          fc2_place.save! if fc2_place_save_needed
        else
          review_reqd = 'Y'
          message += ' Unable to match place name +'
        end
      end
      unless message == ''
        place_name = '"' + fc1_place_name + '"'   # some place names have a comma in them!
        out_message = '"' +  message[1..-2] + '"'
        log_file.puts   "#{fc1_piece.place_country},#{fc1_piece.chapman_code},#{fc1_piece.year},#{fc1_piece.piece_number},#{fc1_piece.status},#{place_name},#{fc2_place_name},#{review_reqd},#{out_message}"
      end
    end
  end
  p "*** Total FC1 Pieces processed = #{total_fc1_piece_cnt}"
  p "*** Total FC2_place_ids set = #{total_match_cnt}"
  p "*** Population of freecen2_place_id in freecen_piece documents - see log/set_fc2place_in_fc1piece.csv for list of documents where freecen2_place_id not set"
end
