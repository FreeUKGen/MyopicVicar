namespace :freecen do
  desc 'converts vld to new freecen2 linkages'
  task :convert_vld_to_new_freecen2_linkage, %i[vld district piece place fix] => :environment do |_t, args|
    # this task moves a vld file and and all its linkages to a new district, piece and place
    # was used to move incorrectly linked vlds in SCS
    # Print the time before start the process
    start_time = Time.now
    fixit = args.fix.to_s == 'Y'
    vld = args.vld.to_s
    place = args.place.to_s
    district = args.district.to_s
    piece = args.piece.to_s
    vld_entry = Freecen1VldFile.find_by(_id: vld)

    new_place_entry = Freecen2Place.find_by(_id: place)

    old_piece_entry = FreecenPiece.find_by(_id: vld_entry.freecen_piece) if vld_entry.freecen_piece.present?

    old_place_entry = Place.find_by(_id: old_piece_entry.place_id) if old_piece_entry.place_id.present?

    old_freecen2_place_entry = Freecen2Place.find_by(_id: vld_entry.freecen2_place) if vld_entry.freecen2_place.present?

    old_freecen2_piece_entry = Freecen2Piece.find_by(_id: vld_entry.freecen2_piece) if vld_entry.freecen2_piece.present?

    new_freecen2_piece_entry = Freecen2Piece.find_by(_id: piece)

    file_for_warning_messages = "log/convert_scs_to_freecen2_#{new_place_entry.place_name}.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
    message_file = File.new(file_for_warning_messages, 'w')
    p "Starting conversion of #{vld_entry.file_name} in Scs to freecen2 from #{old_place_entry.place_name} in #{old_place_entry.chapman_code} to #{new_place_entry.place_name} in #{new_place_entry.chapman_code} at #{start_time} with fix  #{fixit}"
    message_file.puts "Starting conversion of #{vld_entry.file_name} in Scs to freecen2 from #{old_place_entry.place_name} in #{old_place_entry.chapman_code} to #{new_place_entry.place_name} in #{new_place_entry.chapman_code} at #{start_time} with fix  #{fixit}"
    p 'vld'
    p vld_entry.inspect
    p 'Old'
    p "Old piece #{old_piece_entry.inspect} old place #{old_place_entry.inspect}"
    message_file.puts "Old piece #{old_piece_entry.inspect} old place #{old_place_entry.inspect}"
    p "Old freecen2 piece #{old_freecen2_piece_entry.inspect} Old freecen2 place #{old_freecen2_place_entry.inspect}"
    message_file.puts "Old freecen2 piece #{old_freecen2_piece_entry.inspect} Old freecen2 place #{old_freecen2_place_entry.inspect}"
    p 'New'
    p "New freecen2 piece #{new_freecen2_piece_entry.inspect} New freecen2 place #{new_place_entry.inspect}"
    message_file.puts "New freecen2 piece #{new_freecen2_piece_entry.inspect} New freecen2 place #{new_place_entry.inspect}"

    new_freecen2_piece_entry.update_attributes(num_individuals: old_piece_entry.num_individuals, num_dwellings: old_piece_entry.num_dwellings, status: old_piece_entry.status, status_date: old_piece_entry.status_date) if fixit

    old_freecen2_piece_entry.update_attributes(freecen2_place_id: place, num_individuals: nil, num_dwellings: nil, status: nil, status_date: nil) if fixit

    new_place_entry.update_data_present(new_freecen2_piece_entry) if fixit

    vld_entry.update_attributes(freecen2_piece_id: piece, freecen2_place_id: place, freecen2_district_id: district) if fixit

    old_freecen2_place_entry.update_data_present_after_vld_delete(old_freecen2_piece_entry) if fixit

    p "Dwellings #{FreecenDwelling.where(freecen1_vld_file_id: vld).count}"
    message_file.puts "Dwellings #{FreecenDwelling.where(freecen1_vld_file_id: vld).count}"
    number_of_individuals = 0

    FreecenDwelling.where(freecen1_vld_file_id: vld).each do |dwelling|
      dwelling.update_attributes(freecen2_piece_id: piece, freecen2_place_id: place) if fixit
      number_of_individuals += FreecenIndividual.where(freecen_dwelling_id: dwelling._id).count
      FreecenIndividual.where(freecen_dwelling_id: dwelling._id).each do |individual|
        individual.update_attributes(freecen2_piece_id: piece, freecen2_place_id: place) if fixit
        record = SearchRecord.find_by(freecen_individual_id: individual._id)
        record.update_attributes(freecen2_place_id: place) if fixit
      end
    end
    p "Individuals #{number_of_individuals}"
    message_file.puts "Individuals #{number_of_individuals}"
    Freecen2PlaceCache.refresh(new_place_entry.chapman_code) if fixit
    Freecen2PlaceCache.refresh(old_freecen2_place_entry.chapman_code) if fixit
    running_time = Time.now - start_time
    message = 'Finished' if message.blank?
    message_file.puts "#{message} after #{running_time}"
    p "#{message} after #{running_time}"
  end
end
