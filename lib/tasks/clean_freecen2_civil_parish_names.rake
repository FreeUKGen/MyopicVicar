task :clean_freecen2_civil_parish_names, [:chapman_code, :limit, :fix] => [:environment] do |t, args|
  #
  # Obsolete task - AV 20/02/2023
  #
  # p "Started clean_freecen2 _civil_parish_names #{args.chapman_code}  #{args.limit} #{args.fix}"
  # clean_name(args.chapman_code, args.limit, args.fix)
  # p 'Finished'
end

def clean_name(chapman_code, limit, fix)
  time_start = Time.now.utc
  number = 0
  fixed = 0
  needing_fix = 0
  county = chapman_code.to_s.downcase == 'all' ? 'all' : chapman_code.to_s
  lim = limit.to_i
  fixit = fix.to_s.downcase == 'y' ? true : false
  p "#{time_start.strftime('%d/%m/%Y %H:%M:%S')} County=#{county} limit=#{lim} fixit=#{fixit}"

  file_for_warning_messages = 'log/clean_freecen2_civil_parish_names.txt'
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  message_file = File.new(file_for_warning_messages, 'w')

  fc2_cp_rec_count = county == 'all' ? Freecen2CivilParish.count : Freecen2CivilParish.where(chapman_code: county).count
  scope = county == 'all' ? 'All counties have' : "#{county} has"
  p "#{scope} #{fc2_cp_rec_count} records"

  fc2_cp_records = county == 'all' ? Freecen2CivilParish.pluck(:id, :chapman_code, :name, :freecen2_piece_id) : Freecen2CivilParish.where(chapman_code: county).pluck(:id, :chapman_code, :name, :freecen2_piece_id)

  p "fc2_records.length = #{fc2_cp_records.length}"

  fc2_cp_records.each do |civil_parish|

    number += 1
    break if number > lim

    cp_id = civil_parish[0]
    cp_county = civil_parish[1]
    cp_name = civil_parish[2]
    cp_fc2_piece_id = civil_parish[3]

    # 1. look for all occurances of &

    find1 = [] # 1. look for all occurances of &
    find2 = [] # 1. look for all occurances of ,
    find3 = [] # 1. look for all occurances of 2 spaces    place.strip.squeeze(' ')

    unless cp_name.blank?

      needs_fix = false

      find1 = (0...cp_name.length).find_all { |i| cp_name[i, 1] == '&' }

      if find1.length.positive?
        needs_fix = true
        fixed1 = cp_name.gsub('&', ' and ')
        message_text = "#{cp_id} #{cp_county} #{cp_name}: found #{find1.length} ampersand(s)"
        message_file.puts "#{message_text}"
      else
        fixed1 = cp_name
      end

      find2 = (0...fixed1.length).find_all { |i| fixed1[i, 1] == ',' }

      if find2.length.positive?
        needs_fix = true
        fixed2 = fixed1.gsub(',', ' ')
        message_text = "#{cp_id} #{cp_county} #{cp_name}: found #{find2.length} comma(s)"
        message_file.puts "#{message_text}"
      else
        fixed2 = fixed1
      end

      fixed3 = fixed2.strip.squeeze(' ')
      unless fixed3 == fixed2
        needs_fix = true
        message_text = "#{cp_id} #{cp_county} #{cp_name}: found multiple spaces"
        message_file.puts "#{message_text}"
      end
      needing_fix += 1 if needs_fix == true

      # Fix
      if fixit && needs_fix

        new_cp_name = fixed3
        new_cp_standard_name =  Freecen2Place.standard_place(new_cp_name)
        message_text = "#{cp_id} #{cp_county} #{cp_name}: fixed_name: #{new_cp_name}, fixed_standard_name: #{new_cp_standard_name}"
        message_file.puts "#{message_text}"

        unless cp_fc2_piece_id.blank?
          piece = Freecen2Piece.find_by(id: cp_fc2_piece_id)
          piece_cp_names = piece.civil_parish_names
          new_cp_names = piece.add_update_civil_parish_list
          if piece_cp_names != new_cp_names
            message_text = "#{cp_fc2_piece_id}: Piece: OLD civil_parish_names: #{piece_cp_names}"
            message_file.puts "#{message_text}"
            message_text = "#{cp_fc2_piece_id}: Piece: NEW civil_parish_names: #{new_cp_names}"
            message_file.puts "#{message_text}"
          end

        end
        fixed += 1
      end

    end
  end
  recs_processed = lim < fc2_cp_rec_count ? lim : fc2_cp_rec_count
  time_end = Time.now.utc
  run_time = time_end - time_start
  rec_processing_average_time = run_time / recs_processed
  p "Processed #{recs_processed} records"
  p "Needing fix #{needing_fix} records"
  p "Fixed #{fixed}"
  p "Average time to process a record #{rec_processing_average_time.round(2)} secs"
  p "Run time = #{run_time.round(2)} secs"
  p "#{time_end.strftime('%d/%m/%Y %H:%M:%S')} Finished"
end
