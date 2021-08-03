desc "fc1_fc2_piece_compatibility_report: Check integrity of FC1 piece places when compared to FC2 pieces places - NOTE: Does not check Scotland or Ireland"
task fc1_fc2_piece_compatibility_report:  :environment do

  report_file = "log/fc1_fc2_piece_compatibility_report.csv"
  summary_file = "log/fc1_fc2_piece_compatibility_summary.csv"
  FileUtils.mkdir_p(File.dirname(report_file) )  unless File.exists?(report_file)
  FileUtils.mkdir_p(File.dirname(summary_file) )  unless File.exists?(summary_file)
  detail_file = File.new(report_file, "w")
  summary_file = File.new(summary_file, "w")

  fc1_replacements = {
    "-" => " ",
    "St George Hanover Sq" => "St George Hanover Square",
    "St George Hanover S" => "St George Hanover Square",
    "Taunton St Mary Mag" => "Taunton St Mary Magdalene",
    "TauntonStMaryMag" => "Taunton St Mary Magdalene",
    "Taunton St MARY" => "Taunton St Mary Magdalene",
    "Taunton StJames" => "Taunton St James",
    "Combe StNicholas" => "Combe St Nicholas",
    "St James Bermondsey" => "Bermondsey St James",
    "Llanfihangel y Tr." => "Llanfihangel Y Traethau",
    "Gilligham" => "Gillingham",
    "Llanddausant" => "Llanddausaint",
    "Congleon" => "Congleton"
  }
  fc1_keys = Regexp.union(fc1_replacements.keys)

  fc2_replacements = {
    "the " => " ",
    "'s" => "s",
    "Whitchurch Canon" => "Whitchurch Can",
    "Whitchurch Canonicorum" => "Whitchurch Canonicor",
    "Sherborne" => "Sherbourne",
    "On The" => "On"
  }
  fc2_keys = Regexp.union(fc2_replacements.keys)

  p "*** Started FC1 FC2 Piece Compatibility Report"
  total_fc1_pieces = 0
  total_fully_compatible = 0
  total_district_place_compatible = 0
  total_probably_ok = 0
  total_fc2_missing = 0
  fc1_piece_cnt = 0
  fc2_missing_cnt = 0
  fully_compatible = 0
  district_place_compatible = 0
  probably_ok = 0
  detail_file.puts  "Country,FC1 Chapman Code,Year,FC1 Piece Number,Online,FC1 Place Name,FC2 Chapman Code,FC2 Piece Number,FC2 Place Name,FC2 District Place Name,Message,Review Required,Review comments"
  summary_file.puts  "Country,FC1 Chapman Code,FC1 Piece Records Processed,FC1 Full Match Place Name,FC1 Full Match District Place Name,FC1 Probable Match Place Name,Percentage match,FC2 Piece Records Missing,Needs Review"
  this_county = ''
  this_country = ''

  FreecenPiece.where(place_country:  "England").or(FreecenPiece.where(place_country:  "Wales")).order_by(chapman_code:1, year: 1, piece_number: 1).each do |fc1_piece|
    if fc1_piece.status == 'Online'
      total_fc1_pieces += 1
      if this_county == ''
        p "Processing - #{fc1_piece.chapman_code}"
        this_county = fc1_piece.chapman_code
        this_country = fc1_piece.place_country
      else
        if this_county != fc1_piece.chapman_code
          percentage_match = ((fully_compatible + probably_ok + district_place_compatible) * 100 / fc1_piece_cnt).round(1).to_s
          needs_review_cnt = fc1_piece_cnt - (fully_compatible + district_place_compatible)
          summary_file.puts  "#{this_country},#{this_county},#{fc1_piece_cnt},#{fully_compatible},#{district_place_compatible},#{probably_ok},#{percentage_match},#{fc2_missing_cnt},#{needs_review_cnt}"
          fc1_piece_cnt = 0
          fc2_missing_cnt = 0
          fully_compatible = 0
          district_place_compatible = 0
          probably_ok = 0
          p "Processing - #{fc1_piece.chapman_code}"
          this_county = fc1_piece.chapman_code
          this_country = fc1_piece.place_country
        end
      end
      fc1_piece_cnt += 1
      message = ''
      review_reqd = 'Y'
      prefix = ''
      fc1_piece.status == 'Online' ? fc1_status = 'Y' : fc1_status = 'N'
      fc1_place = Place.find_by(id: fc1_piece.place_id)
      if fc1_place.blank?
        fc1_place_name = ''
        message += 'FC1 Place missing+'
      else
        fc1_place_name = fc1_place.place_name
        message += "FC1 District (#{fc1_piece.district_name})- FC1 Place Name mismatch+" unless fc1_place_name == fc1_piece.district_name
        case fc1_piece.year
        when '1841'
          prefix ='HO107_'
        when '1851'
          prefix ='HO107_'
        when '1861'
          prefix = 'RG9_'
        when '1871'
          prefix = 'RG10_'
        when '1881'
          prefix = 'RG11_'
        when '1891'
          prefix = 'RG12_'
        when '1901'
          prefix = 'RG13_'
        when '1911'
          prefix = 'RG14_'
        when '1921'
          prefix = 'RG15_'
        end
        fc2_piece = Freecen2Piece.find_by(year: fc1_piece.year, number: prefix + fc1_piece.piece_number.to_s)
        if fc2_piece.blank?
          fc2_p_no = ''
          fc2_chap = ''
          message += 'FC2 Piece record missing+'
          fc2_missing_cnt += 1
          total_fc2_missing += 1
        else
          fc2_p_no = fc2_piece.number
          fc2_chap = fc2_piece.chapman_code
          fc2_place = Freecen2Place.find_by(id: fc2_piece.freecen2_place_id)
          fc2_district = Freecen2District.find_by(id: fc2_piece.freecen2_district_id)
          fc2_district_place = Freecen2Place.find_by(id: fc2_district.freecen2_place_id)

          if fc2_district_place.present?
            fc2_district_place_name = fc2_district_place.place_name
          else
            fc2_district_place_name = ""
          end

          if fc2_place.present?
            fc2_place_name = fc2_place.place_name
            if fc1_place_name.downcase == fc2_place_name.downcase
              message += 'Full Place name match+'
              review_reqd = 'N'
              fully_compatible += 1
              total_fully_compatible += 1
            else

              fc1_replaced = fc1_place_name.gsub(fc1_keys, fc1_replacements)

              fc1_replaced_1 = fc1_replaced.gsub(/\s\d\D\d/,"")      # e.g. 1C1
              fc1_replaced_2 = fc1_replaced_1.gsub(/\s\d\D/,"")      # e.g. 1A
              fc1_try_match = fc1_replaced_2.gsub(/\d\s/,"")         # e.g. 1

              fc2_try_match = fc2_place_name.gsub(fc2_keys, fc2_replacements)

              if fc1_try_match.downcase == fc2_try_match.downcase
                message += 'Place name match probably ok+'
                probably_ok  += 1
                total_probably_ok += 1
              else
                fc2_place_no_prefix = fc2_place_name.downcase.delete_prefix("st ").delete_prefix("north ").delete_prefix("south ").delete_prefix("east ").delete_prefix("west ")
                if fc1_place_name.downcase.include? fc2_place_no_prefix.split[0]    # fc1 place includes first word in fc2 place (with prefix removed)
                  message += 'Place name match probably ok+'
                  probably_ok  += 1
                  total_probably_ok += 1
                else
                  if fc1_place_name.downcase == fc2_district_place_name.downcase
                    message += "Place name matches FC2 District Place name+"
                    review_reqd = 'N'
                    district_place_compatible  += 1
                    total_district_place_compatible += 1
                  else
                    message += "Place name mismatch - (NOTE: FC2 District = #{fc2_district.name} - FC2 District Place = #{fc2_district_place.place_name})+"
                  end
                end
              end
            end
          else
            fc2_place_name = ''
            message += 'FC2 Place record missing+'
          end
        end
      end
      detail_file.puts  "#{fc1_piece.place_country},#{fc1_piece.chapman_code},#{fc1_piece.year},#{fc1_piece.piece_number},#{fc1_status},#{fc1_place_name},#{fc2_chap},#{fc2_p_no},#{fc2_place_name},#{fc2_district_place_name},#{message[0..-2]},#{review_reqd}"
      # unless review_reqd == 'N'
    end
  end
  percentage_match = ((fully_compatible + probably_ok + district_place_compatible) * 100 / fc1_piece_cnt).round(1).to_s
  needs_review_cnt = fc1_piece_cnt - (fully_compatible + district_place_compatible)
  summary_file.puts  "#{this_country},#{this_county},#{fc1_piece_cnt},#{fully_compatible},#{district_place_compatible},#{probably_ok},#{percentage_match},#{fc2_missing_cnt},#{needs_review_cnt}"
  percentage_match = ((total_fully_compatible + total_district_place_compatible + total_probably_ok) * 100 / total_fc1_pieces).round(1).to_s
  needs_review_cnt = total_fc1_pieces- (total_fully_compatible + total_district_place_compatible)
  summary_file.puts  "ALL,ALL,#{total_fc1_pieces},#{total_fully_compatible},#{total_district_place_compatible},#{total_probably_ok},#{percentage_match},#{total_fc2_missing},#{needs_review_cnt}"
  p "*** Total FC1 Pieces processed = #{total_fc1_pieces}"
  p "*** Finished FC1 FC2 Piece Compatibility Report- see log/fc1_fc2_piece_compatibility_report.csv (and fc1_fc2_piece_compatibility_summary.csv) for output"
end
