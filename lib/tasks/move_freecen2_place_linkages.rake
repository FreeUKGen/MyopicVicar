namespace :freecen do
  desc 'moves freecen2 place linkages from one place to another'
  task :move_freecen2_place_linkages, %i[old new fix] => :environment do |_t, args|
    # based on freecen:convert_freecen2_place_id rake task
    # Print the time before start the process
    start_time = Time.now
    old_place = args.old.to_s
    new_place = args.new.to_s
    fixit = args.fix.to_s == 'Y'
    old_place_entry = Freecen2Place.find_by(_id: old_place)
    new_place_entry = Freecen2Place.find_by(_id: new_place)
    file_for_warning_messages = "log/move_freecen2_place_#{old_place_entry.chapman_code}_#{old_place_entry.place_name}.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
    message_file = File.new(file_for_warning_messages, 'w')
    message_line = "Starting Move of freecen2_place linkages from  #{old_place} (#{old_place_entry.chapman_code}) to #{new_place} (#{new_place_entry.chapman_code}) at #{start_time} with fix #{fixit}"
    # take out all p commands !!!!!!!!!!!!!!!!!!!
    p message_line
    message_file.puts message_line
    message_line = 'Before Linkages Move'
    message_file.puts message_line
    p message_line
    message_line = "Old Place record #{old_place_entry.inspect}"
    message_file.puts message_line
    p message_line
    message_line = "New Place record #{new_place_entry.inspect}"
    message_file.puts message_line
    p message_line
    if old_place_entry.blank? || new_place_entry.blank?
      message = "Either old #{old_place_entry} or new #{new_place_entry} is not found"
      fixit = false
    else
      message_line = '** Census years **'
      message_file.puts message_line
      p message_line
      message_file.puts "Old Place Census years #{old_place_entry.cen_data_years}"
      message_file.puts message_line
      p message_line
      message_file.puts "New Place existing Census years #{new_place_entry.cen_data_years}"
      message_file.puts message_line
      p message_line
      updated_new_cen_data_years = new_place_entry.cen_data_years | old_place_entry.cen_data_years
      updated_new_cen_data_years.sort!
      p updated_new_cen_data_years
      message_line = "Updated Census years for New Place will be #{updated_new_cen_data_years}"
      message_file.puts message_line
      p message_line
      message_line = '** Search Data present **'
      message_file.puts message_line
      p message_line
      message_line = "Old Place Search Data present #{old_place_entry.data_present}"
      message_file.puts message_line
      p message_line
      message_line = "New Place Search Data present #{new_place_entry.data_present}"
      message_file.puts message_line
      p message_line
      updated_search_data_present = old_place_entry.data_present || new_place_entry.data_present ? true : false
      p message_line = "Updated Search Data present for New Place will be #{updated_search_data_present}"
      message_file.puts message_line
      p message_line
      message_line = '** Districts **'
      message_file.puts message_line
      p message_line
      old_freecen2_districts = Freecen2District.where(freecen2_place_id: old_place_entry._id).count
      message_line = "Old Place Districts count = #{old_freecen2_districts}"
      message_file.puts message_line
      p message_line
      if !old_freecen2_districts.zero? && fixit
        districts_updated = Freecen2District.collection.update_many({ freecen2_place_id: old_place_entry._id }, '$set' => { freecen2_place_id: new_place_entry._id })
        message_line = districts_updated
        message_file.puts message_line
        p message_line
      end
      message_line = '** Pieces **'
      message_file.puts message_line
      p message_line
      old_freecen2_pieces = Freecen2Piece.where(freecen2_place_id: old_place_entry._id).count
      message_line = "Old Place Pieces count = #{old_freecen2_districts}"
      message_file.puts message_line
      p message_line
      if !old_freecen2_pieces.zero? && fixit
        pieces_updated = Freecen2Piece.collection.update_many({ freecen2_place_id: old_place_entry._id }, '$set' => { freecen2_place_id: new_place_entry._id})
        message_line = pieces_updated
        message_file.puts message_line
        p message_line
      end
      message_line = '** Civil Parishes **'
      message_file.puts message_line
      p message_line
      old_freecen2_civil_parishes = Freecen2CivilParish.where(freecen2_place_id: old_place_entry._id).count
      message_line = "Old Place Civil Parishes count = #{old_freecen2_civil_parishes}"
      message_file.puts message_line
      p message_line
      if !old_freecen2_civil_parishes.zero? && fixit
        parishes_updated = Freecen2CivilParish.collection.update_many({ freecen2_place_id: old_place_entry._id }, '$set' => { freecen2_place_id: new_place_entry._id})
        message_line = parishes_updated
        message_file.puts message_line
        p message_line
      end
      message_line = '** Search Records **'
      message_file.puts message_line
      p message_line
      old_search_records = SearchRecord.where(freecen2_place_id: old_place_entry._id).count
      message_line = "Old Place Search Records count = #{old_search_records}"
      message_file.puts message_line
      p message_line
      csv_records_present = true if !search_records.zero? && SearchRecord.where(freecen2_place_id: old_place_entry._id).first.freecen_csv_file_id.present?
      message_line = "Old Place Search Records - CSV File(s) = #{csv_records_present}"
      message_file.puts message_line
      p message_line
      vld_records_present = true if !search_records.zero? && SearchRecord.where(freecen2_place_id: old_place_entry._id).first.freecen1_vld_file_id.present?
      message_line = "Old Place Search Records - VLD File(s) = #{vld_records_present}"
      message_file.puts message_line
      p message_line
      message_line = '** Search Records POBs **'
      old_search_records_pobs = SearchRecord.where(birth_county: old_place_entry.chapman_code, birth_place: old_place_entry.place_name).count
      message_line = "Old Place Search Records POBs count = #{old_search_records_pobs}"
      message_file.puts message_line
      p message_line

      # UPDATE Search recs for Place Id

      if !old_search_records.zero? && fixit
        records_updated = SearchRecord.collection.update_many({ freecen2_place_id: old_place_entry._id }, '$set' => { freecen2_place_id: new_place_entry._id, location_names: [new_place_entry.place_name] })
        message_line = "Search Records updated = #{records_updated.inspect}"
        message_file.puts message_line
        p message_line
      end

      # UPDATE POBs for CSV recs

      if csv_records_present && fixit
        csv_pob_recs = SearchRecord.where(birth_county: old_place_entry.chapman_code, birth_place: old_place_entry.place_name).freecen_csv_file_id.present?
        csv_pob_recs.each do |csv_search_record|
          recs_to_update = FreecenCsvEntry.where(birth_county: old_place_entry.chapman_code, birth_place: old_place_entry.place_name, freecen_csv_file_id: csv_search_record.freecen_csv_file_id).count
          unless recs_to_update.zero?
            csv_entry_recs_updated = FreecenCsvEntry.collection.update_many({freecen_csv_file_id: csv_search_record.freecen_csv_file_id, birth_county: old_place_entry.chapman_code, birth_place: old_place_entry.place_name }, '$set' => { birth_county: new_place_entry.chapman_code, birth_place: new_place_entry.place_name })
            message_line = "Search Records CSV Entry POBs updated = #{csv_entry_recs_updated.inspect}"
            message_file.puts message_line
            p message_line
          end
        end
        csv_pob_records_updated = SearchRecord.collection.update_many({birth_county: old_place_entry.chapman_code, birth_place: old_place_entry.place_name, freecen_csv_file_id: { '$ne' => nil } }, '$set' => { birth_county: new_place_entry.chapman_code, birth_place: new_place_entry.place_name })
        message_line = "Search Records CSV POBs updated = #{csv_pob_records_updated.inspect}"
        message_file.puts message_line
        p message_line
      end
    end

    # UPDATE POBs for VLD recs

    if vld_records_present && fixit
      vld_search_pob_recs = SearchRecord.where(birth_county: old_place_entry.chapman_code, birth_place: old_place_entry.place_name).freecen1_vld_file_id.present?
      vld_search_pob_recs.each do |vld_search_record|
        recs_to_update = Freecen1VldEntry.where(birth_county: old_place_entry.chapman_code, birth_place: old_place_entry.place_name, freecen1_vld_file_id: vld_search_record.freecen1_vld_file_id).count
        unless recs_to_update.zero?
          vld_entry_recs_updated = Freecen1VldEntry.collection.update_many({freecen1_vld_file_id: vld_search_record.freecen1_vld_file_id, birth_county: old_place_entry.chapman_code, birth_place: old_place_entry.place_name }, '$set' => { birth_county: new_place_entry.chapman_code, birth_place: new_place_entry.place_name })
          message_line = "Search Records VLD Entry POBs updated = #{vld_entry_recs_updated.inspect}"
          message_file.puts message_line
          p message_line
        end
        recs_to_update = FreecenIndividual.where(birth_county: old_place_entry.chapman_code, birth_place: old_place_entry.place_name, freecen1_vld_file_id: vld_search_record.freecen_individual_id).count
        unless recs_to_update.zero?
          vld_individ_recs_updated = FreecenIndividual.collection.update_many({_id: vld_search_record.freecen_individual_id, birth_county: old_place_entry.chapman_code, birth_place: old_place_entry.place_name }, '$set' => { birth_county: new_place_entry.chapman_code, birth_place: new_place_entry.place_name })
          message_line = "Search Records VLD Individual POBs updated = #{vld_individ_recs_updated.inspect}"
          message_file.puts message_line
          p message_line
        end
      end
      vld_pob_records_updated = SearchRecord.collection.update_many({birth_county: old_place_entry.chapman_code, birth_place: old_place_entry.place_name, freecen1_vld_file_id: { '$ne': nil } }, '$set' => { birth_county: new_place_entry.chapman_code, birth_place: new_place_entry.place_name })
      message_line = "Search Records VLD POBs updated = #{vld_pob_records_updated.inspect}"
      message_file.puts message_line
      p message_line
    end

    new_place_entry.update_attributes(cen_data_years: updated_new_cen_data_years, data_present: updated_cen_data_present) if fixit
    old_place_entry.update_attributes(data_present: false, cen_data_years: []) if fixit
    message_line = 'Updated places'
    message_file.puts message_line
    p message_line
    message_line = "#{old_place_entry.inspect}"
    message_file.puts message_line
    p message_line
    message_line = "#{new_place_entry.inspect}"
    message_file.puts message_line
    p message_line
  end
  Freecen2PlaceCache.refresh(new_place_entry.chapman_code) if fixit
  running_time = Time.now - start_time
  message = 'Finished' if message.blank?
  message_line = "#{message} after #{running_time}"
  message_file.puts message_line
  p message_line
end
end
