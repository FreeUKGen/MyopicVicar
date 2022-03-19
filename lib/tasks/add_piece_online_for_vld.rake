namespace :freecen do

  desc 'All pieces put to online'
  task :add_piece_online_for_vld, %i[lim fix] => :environment do |_t, args|
    # Print the time before start the process
    start_time = Time.now
    limit = args.lim.to_i

    fixit = args.fix.to_s == 'Y' ? true : false
    p "Starting vld checks at #{start_time} with limit #{limit} with fix  #{fixit}"

    # Call the RefreshUcfList library class file with passing the model name as parameter
    # FreecenPiece.no_timeout.each do |piece|
    #  piece.num_dwellings = piece.freecen_dwellings.count
    #  piece.save
    # end
    number = 0
    missing = 0
    processed = 0

    file_for_warning_messages = 'log/add_piece_online_for_vld.log'
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
    message_file = File.new(file_for_warning_messages, 'w')
    message_file.puts "Starting vld checks at #{start_time} with limit #{limit} with fix  #{fixit}"
    Freecen1VldFile.no_timeout.order_by(_id: -1).each do |file|
      number += 1
      message_file.puts number
      break if number == limit + 1

      p number if (number / 100) * 100 == number
      timestep1 = Time.now
      freecen1_piece = FreecenPiece.find_by(_id: file.freecen_piece_id)
      if freecen1_piece.blank?
        message_file.puts "#{file.file_name} has no freecen1 piece"
        message_file.puts file.inspect
        missing += 1
        next
      end
      piece2_number = Freecen2Piece.calculate_freecen2_piece_number(freecen1_piece)
      freecen2_piece = Freecen2Piece.find_by(number: piece2_number)
      if freecen2_piece.blank?
        missing += 1
        message_file.puts "#{piece2_number} for #{file.file_name} is missing"
      elsif !freecen2_piece.status == 'Online'
        message_file.puts "#{piece2_number} status for #{file.file_name} is missing and added"
        message_file.puts freecen2_piece.inspect
        freecen2_piece.update_attributes(status: 'Online', status_date: file._id.generation_time.to_datetime.in_time_zone('London')) if fixit
      end
      regexp = BSON::Regexp::Raw.new('^' + piece2_number + '\D')
      parts = Freecen2Piece.where(number: regexp).order_by(number: 1)
      message_file.puts 'After regex'
      message_file.puts Time.now - timestep1
      next if parts.count.zero?

      freecen2_place = parts[0].freecen2_place
      message_file.puts "Piece has no place #{parts[0].inspect}" if freecen2_place.blank?
      file_present = true if file.freecen2_place_id == freecen2_place._id
      date_present = true if freecen2_place.data_present == true
      cen_years_present = true if freecen2_place.cen_data_years.include?(parts[0].year)
      freecen2_place.freecen1_vld_files << [file] unless file_present
      freecen2_place.data_present = true unless date_present
      freecen2_place.cen_data_years << parts[0].year unless cen_years_present
      freecen2_place.save! if fixit && (!cen_years_present || !file_present || !date_present)
      message_file.puts 'Place Update'
      message_file.puts parts.count
      message_file.puts Time.now - timestep1
      parts.each do |part|
        processed += 1
        part.update_attributes(status: 'Online', status_date: file._id.generation_time.to_datetime.in_time_zone('London'), shared_vld_file: file.id) if fixit
        message_file.puts "Setting #{part.number} to online"
        message_file.puts part.inspect
        message_file.puts file.inspect
      end
      message_file.puts 'Piece parts update'
      message_file.puts Time.now - timestep1

    end
    Freecen2PlaceCache.refresh_all if fixit
    number -= 1 if number == limit + 1
    running_time = Time.now - start_time
    message_file.puts "Processed #{number} files #{processed} updates in time #{running_time} with #{missing} on-line files missing"
    p "Processed #{number} files #{processed} updates in time #{running_time} with #{missing} on-line files missing"
  end
end
