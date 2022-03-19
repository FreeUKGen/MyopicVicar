namespace :freecen do
  desc 'converts freecen2 place linkages'
  task :convert_freecen2_place_id, %i[old new fix] => :environment do |_t, args|
    # Print the time before start the process
    start_time = Time.now
    old_place = args.old.to_s
    new_place = args.new.to_s
    fixit = args.fix.to_s == 'Y'
    old_place_entry = Freecen2Place.find_by(_id: old_place)
    new_place_entry = Freecen2Place.find_by(_id: new_place)
    file_for_warning_messages = "log/convert_freecen2_place_#{new_place_entry.place_name}.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
    message_file = File.new(file_for_warning_messages, 'w')
    p "Starting conversion of freecen2_place linkage from #{old_place} to #{new_place} at #{start_time} with fix  #{fixit}"
    message_file.puts "Starting conversion of freecen2_place linkage from #{old_place} to #{new_place} at #{start_time} with fix  #{fixit}"
    message_file.puts 'old'
    p 'old'
    message_file.puts "#{old_place_entry.inspect}"
    p old_place_entry
    message_file.puts 'new'
    p 'new'
    message_file.puts "#{new_place_entry.inspect}"
    p new_place_entry
    if old_place_entry.blank? || new_place_entry.blank?
      message = "Either old #{old_place_entry} or new #{new_place_entry} is not found"
      fixit = false
    else
      p 'Census years'
      message_file.puts 'Census years'
      old_cen_data_years = old_place_entry.cen_data_years
      p old_cen_data_years
      message_file.puts "#{old_cen_data_years}"
      new_cen_data_years = new_place_entry.cen_data_years
      p new_cen_data_years
      message_file.puts "#{new_cen_data_years}"
      updated_new_cen_data_years = new_cen_data_years | old_cen_data_years
      updated_new_cen_data_years.sort!
      p updated_new_cen_data_years
      message_file.puts "#{updated_new_cen_data_years}"
      p 'Data present'
      message_file.puts 'Data present'
      old_cen_data_present = old_place_entry.data_present
      p old_cen_data_present
      message_file.puts "#{old_cen_data_present}"
      new_cen_data_present = new_place_entry.data_present
      p new_cen_data_present
      message_file.puts "#{new_cen_data_present}"
      updated_cen_data_present = updated_new_cen_data_years.present? ? true : false
      p updated_cen_data_present
      message_file.puts "#{updated_cen_data_present}"
      p 'Districts'
      message_file.puts 'Districts'
      freecen2_districts = Freecen2District.where(freecen2_place_id: old_place_entry._id).count
      p freecen2_districts
      message_file.puts "#{freecen2_districts}"
      if !freecen2_districts.zero? && fixit
        districts_updated = Freecen2District.collection.update_many({ freecen2_place_id: old_place_entry._id }, '$set' => { freecen2_place_id: new_place_entry._id })
      end
      p districts_updated
      message_file.puts "#{districts_updated}"
      p 'Pieces'
      message_file.puts 'Pieces'
      freecen2_pieces = Freecen2Piece.where(freecen2_place_id: old_place_entry._id).count
      p freecen2_pieces
      message_file.puts "#{freecen2_pieces}"
      if !freecen2_pieces.zero? && fixit
        pieces_updated = Freecen2Piece.collection.update_many({ freecen2_place_id: old_place_entry._id }, '$set' => { freecen2_place_id: new_place_entry._id})
      end
      p pieces_updated
      message_file.puts "#{pieces_updated}"
      p 'Parishes'
      message_file.puts 'Parishes'
      freecen2_civil_parishes = Freecen2CivilParish.where(freecen2_place_id: old_place_entry._id).count
      p freecen2_civil_parishes
      message_file.puts "#{freecen2_civil_parishes}"
      if !freecen2_civil_parishes.zero? && fixit
        parishes_updated = Freecen2CivilParish.collection.update_many({ freecen2_place_id: old_place_entry._id }, '$set' => { freecen2_place_id: new_place_entry._id})
      end
      p parishes_updated
      message_file.puts "#{parishes_updated}"
      p 'Records'
      message_file.puts 'Records'
      search_records = SearchRecord.where(freecen2_place_id: old_place_entry._id).count
      csv_record = true if !search_records.zero? && SearchRecord.where(freecen2_place_id: old_place_entry._id).first.freecen_individual.blank?
      p search_records
      message_file.puts "#{search_records}"
      p 'csv'
      message_file.puts 'csv'
      p csv_record
      message_file.puts "#{csv_record.inspect}"
      if !search_records.zero? && fixit
        records_updated = SearchRecord.collection.update_many({ freecen2_place_id: old_place_entry._id }, '$set' => { freecen2_place_id: new_place_entry._id, location_names: [new_place_entry.place_name] })
      end
      p records_updated
      message_file.puts "#{records_updated.inspect}"
      new_place_entry.update_attributes(cen_data_years: updated_new_cen_data_years, data_present: updated_cen_data_present) if fixit
      old_place_entry.update_attributes(disabled: 'true', data_present: false, cen_data_years: []) if fixit
      message_file.puts 'Updated places'
      message_file.puts "#{old_place_entry.inspect}"
      message_file.puts "#{new_place_entry.inspect}"
    end
    Freecen2PlaceCache.refresh(new_place_entry.chapman_code) if fixit
    running_time = Time.now - start_time
    message = 'Finished' if message.blank?
    message_file.puts "#{message} after #{running_time}"
    p "#{message} after #{running_time}"
  end
end
