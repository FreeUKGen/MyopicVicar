task :change_freecen2_place_for_freecen2_piece_with_search_records, %i[freecen2_piece_id freecen2_place_id update] => [:environment] do |_t, args|
  # A utility to move a single vld Freecen2_piece from one freecen2_place to new one; parameters are the piece id and the new place id

  file_for_messages = Rails.root.join('log/change_freecen2_place_for_freecen2_piece_with_search_records.log')
  message_file = File.new(file_for_messages, 'w')
  @freecen2_piece = Freecen2Piece.find_by(_id: args.freecen2_piece_id.to_s)
  @freecen2_place = Freecen2Place.find_by(_id: args.freecen2_place_id.to_s)
  search_record_creation = args.update.present? ? true : false
  crash unless @freecen2_piece.present? && @freecen2_place.present?
  existing_place = Freecen2Place.find_by(_id: @freecen2_piece.freecen2_place)

  p "Changing freecen2_piece #{@freecen2_piece.name} place from #{existing_place.place_name} to #{@freecen2_place.place_name} with search record update #{search_record_creation}"
  message_file.puts "Changing freecen2_piece #{@freecen2_piece.name} place from #{existing_place.place_name} to #{@freecen2_place.place_name} with search record update #{search_record_creation}"

  time_start = Time.now.getlocal
  file = Freecen1VldFile.find_by(freecen2_piece_id: @freecen2_piece.id)
  p 'File being relinked'
  p file
  if search_record_creation
    file.freecen_dwellings.no_timeout.each do |dwelling|
      @freecen2_place.freecen_dwellings << dwelling
      dwelling.freecen_individuals.no_timeout.each do |individual|
        @freecen2_place.search_records << individual.search_record
      end
    end
  end
  if search_record_creation
    @freecen2_place.freecen1_vld_files << file unless @freecen2_place.freecen1_vld_files.include?(file)
    @freecen2_piece.update_attributes(freecen2_place_id: @freecen2_place.id)
    @freecen2_place.save
    @freecen2_place.update_data_present(@freecen2_piece)
    existing_place.update_data_present_after_vld_delete(@freecen2_piece)
    file.save
    p 'refreshing place cache'
    Freecen2PlaceCache.refresh(@freecen2_piece.chapman_code)
  end
  file.reload
  p 'File after relinked'
  p file
  p 'Existing place '
  p existing_place
  p existing_place.freecen_dwellings.count
  p existing_place.search_records.count
  p 'New Place'
  p @freecen2_place
  p @freecen2_place.freecen_dwellings.count
  p @freecen2_place.search_records.count
  p @freecen2_piece
  seconds = Time.now.getlocal - time_start
  p "Finished in #{seconds} second; "
end
