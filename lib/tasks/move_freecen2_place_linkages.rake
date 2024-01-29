namespace :freecen do
  desc 'Moves freecen2 place linkages from one place to another'

  task :move_freecen2_place_linkages, [:userid, :old, :new, :fix] => :environment do |_t, args|
    # based on freecen:convert_freecen2_place_id rake task
    # Print the time before start the process
    start_time = Time.now
    old_place = args.old.to_s
    new_place = args.new.to_s
    fixit = args.fix.to_s == 'Y'
    userid = args.userid.present? ? args.userid.to_s : 'n/a'
    old_place_record = Freecen2Place.find_by(_id: old_place)
    new_place_record = Freecen2Place.find_by(_id: new_place)
    file_for_warning_messages = "log/move_freecen2_place_#{old_place_record.chapman_code}_#{old_place_record.place_name}.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
    message_file = File.new(file_for_warning_messages, 'w')
    move_info = "Move of freecen2_place linkages from  #{old_place_record.place_name} (#{old_place_record.chapman_code}) to #{new_place_record.place_name} (#{new_place_record.chapman_code}"
    report_email_log = ''
    message_line = "Starting #{move_info} at #{start_time} with fix #{fixit}"
    output_to_log(message_file, report_log, message_line)
    message_line = 'Before Linkages Move'
    output_to_log(message_file, report_log, message_line)
    message_line = "Old Place record #{old_place_record.inspect}"
    output_to_log(message_file, report_log, message_line)
    message_line = "New Place record #{new_place_record.inspect}"
    output_to_log(message_file, report_log, message_line)

    if old_place_record.blank? || new_place_record.blank?
      message = "Either old #{old_place_record} or new #{new_place_record} is not found"
      fixit = false
    else
      message_line = '** Census years **'
      output_to_log(message_file, report_log, message_line)
      message_file.puts "Old Place Census years #{old_place_record.cen_data_years}"
      output_to_log(message_file, report_log, message_line)
      message_file.puts "New Place existing Census years #{new_place_record.cen_data_years}"
      output_to_log(message_file, report_log, message_line)
      updated_new_cen_data_years = new_place_record.cen_data_years | old_place_record.cen_data_years
      updated_new_cen_data_years.sort!
      message_line = "Updated Census years for New Place will be #{updated_new_cen_data_years}"
      output_to_log(message_file, report_log, message_line)
      message_line = '** Search Data present **'
      output_to_log(message_file, report_log, message_line)
      message_line = "Old Place Search Data present #{old_place_record.data_present}"
      output_to_log(message_file, report_log, message_line)
      message_line = "New Place Search Data present #{new_place_record.data_present}"
      output_to_log(message_file, report_log, message_line)
      updated_search_data_present = old_place_record.data_present || new_place_record.data_present ? true : false
      message_line = "Updated Search Data present for New Place will be #{updated_search_data_present}"
      output_to_log(message_file, report_log, message_line)
      message_line = '** Districts **'
      output_to_log(message_file, report_log, message_line)
      old_freecen2_districts = Freecen2District.where(freecen2_place_id: old_place_record._id).count
      message_line = "Old Place Districts count = #{old_freecen2_districts}"
      output_to_log(message_file, report_log, message_line)
      if old_freecen2_districts.positive? && fixit
        districts_updated = Freecen2District.collection.update_many({ freecen2_place_id: old_place_record._id }, '$set' => { freecen2_place_id: new_place_record._id })
        message_line = districts_updated
        output_to_log(message_file, report_log, message_line)
      end
      message_line = '** Pieces **'
      output_to_log(message_file, report_log, message_line)
      old_freecen2_pieces = Freecen2Piece.where(freecen2_place_id: old_place_record._id).count
      message_line = "Old Place Pieces count = #{old_freecen2_districts}"
      output_to_log(message_file, report_log, message_line)
      if old_freecen2_pieces.positive? && fixit
        pieces_updated = Freecen2Piece.collection.update_many({ freecen2_place_id: old_place_record._id }, '$set' => { freecen2_place_id: new_place_record._id})
        message_line = pieces_updated
        output_to_log(message_file, report_log, message_line)
      end
      message_line = '** Civil Parishes **'
      output_to_log(message_file, report_log, message_line)
      old_freecen2_civil_parishes = Freecen2CivilParish.where(freecen2_place_id: old_place_record._id).count
      message_line = "Old Place Civil Parishes count = #{old_freecen2_civil_parishes}"
      output_to_log(message_file, report_log, message_line)
      if old_freecen2_civil_parishes.positive? && fixit
        parishes_updated = Freecen2CivilParish.collection.update_many({ freecen2_place_id: old_place_record._id }, '$set' => { freecen2_place_id: new_place_record._id})
        message_line = parishes_updated
        output_to_log(message_file, report_log, message_line)
      end
      message_line = '** Search Records **'
      output_to_log(message_file, report_log, message_line)
      old_search_records = SearchRecord.where(freecen2_place_id: old_place_record._id).count
      message_line = "Old Place Search Records count = #{old_search_records}"
      output_to_log(message_file, report_log, message_line)
      csv_records_present = true if search_records.positive? && SearchRecord.where(freecen2_place_id: old_place_record._id).first.freecen_csv_file_id.present?
      message_line = "Old Place Search Records - CSV File(s) = #{csv_records_present}"
      output_to_log(message_file, report_log, message_line)
      vld_records_present = true if search_records.positive? && SearchRecord.where(freecen2_place_id: old_place_record._id).first.freecen1_vld_file_id.present?
      message_line = "Old Place Search Records - VLD File(s) = #{vld_records_present}"
      output_to_log(message_file, report_log, message_line)
      message_line = '** Search Records POBs **'
      old_search_records_pobs = SearchRecord.where(birth_county: old_place_record.chapman_code, birth_place: old_place_record.place_name).count
      message_line = "Old Place Search Records POBs count = #{old_search_records_pobs}"
      output_to_log(message_file, report_log, message_line)
      message_line = '** Dwellings **'
      output_to_log(message_file, report_log, message_line)
      old_dwellings = Dwelling.where(freecen2_place_id: old_place_record._id).count
      message_line = "Old Dwelling Records count = #{old_dwellings}"
      output_to_log(message_file, report_log, message_line)

      # UPDATE Search recs for Place Id

      if old_search_records.positive? && fixit
        records_updated = SearchRecord.collection.update_many({ freecen2_place_id: old_place_record._id }, '$set' => { freecen2_place_id: new_place_record._id, location_names: [new_place_record.place_name] })
        message_line = "Search Records updated = #{records_updated.inspect}"
        output_to_log(message_file, report_log, message_line)
      end

      # UPDATE Dwellings recs Place Id

      if old_dwellings.positive? && fixit
        records_updated = Dwelling.collection.update_many({ freecen2_place_id: old_place_record._id }, '$set' => { freecen2_place_id: new_place_record._id})
        message_line = "Dwellings updated = #{records_updated.inspect}"
        output_to_log(message_file, report_log, message_line)
      end

      # UPDATE POBs for CSV recs

      if csv_records_present && fixit
        csv_pob_recs = SearchRecord.where(birth_county: old_place_record.chapman_code, birth_place: old_place_record.place_name).freecen_csv_file_id.present?
        csv_pob_recs.each do |csv_search_record|
          recs_to_update = FreecenCsvEntry.where(birth_county: old_place_record.chapman_code, birth_place: old_place_record.place_name, freecen_csv_file_id: csv_search_record.freecen_csv_file_id).count
          if recs_to_update.positive?
            csv_entry_recs_updated = FreecenCsvEntry.collection.update_many({freecen_csv_file_id: csv_search_record.freecen_csv_file_id, birth_county: old_place_record.chapman_code, birth_place: old_place_record.place_name }, '$set' => { birth_county: new_place_record.chapman_code, birth_place: new_place_record.place_name })
            message_line = "Search Records CSV Entry POBs updated = #{csv_entry_recs_updated.inspect}"
            output_to_log(message_file, report_log, message_line)
          end
          recs_to_update = FreecenIndividual.where(birth_county: old_place_record.chapman_code, birth_place: old_place_record.place_name, freecen_csv_file_id: csv_search_record.freecen_individual_id).count
          next if recs_to_update.zero?

          csv_individ_recs_updated = FreecenIndividual.collection.update_many({_id: csv_search_record.freecen_individual_id, birth_county: old_place_record.chapman_code, birth_place: old_place_record.place_name }, '$set' => { birth_county: new_place_record.chapman_code, birth_place: new_place_record.place_name })
          message_line = "Search Records CSV Individual POBs updated = #{csv_individ_recs_updated.inspect}"
          output_to_log(message_file, report_log, message_line)
        end
        csv_pob_records_updated = SearchRecord.collection.update_many({birth_county: old_place_record.chapman_code, birth_place: old_place_record.place_name, freecen_csv_file_id: { '$ne' => nil } }, '$set' => { birth_county: new_place_record.chapman_code, birth_place: new_place_record.place_name })
        message_line = "Search Records CSV POBs updated = #{csv_pob_records_updated.inspect}"
        output_to_log(message_file, report_log, message_line)
      end

      # UPDATE POBs for VLD recs

      if vld_records_present && fixit
        vld_search_pob_recs = SearchRecord.where(birth_county: old_place_record.chapman_code, birth_place: old_place_record.place_name).freecen1_vld_file_id.present?
        vld_search_pob_recs.each do |vld_search_record|
          recs_to_update = Freecen1VldEntry.where(birth_county: old_place_record.chapman_code, birth_place: old_place_record.place_name, freecen1_vld_file_id: vld_search_record.freecen1_vld_file_id).count
          if recs_to_update.positive?
            vld_entry_recs_updated = Freecen1VldEntry.collection.update_many({freecen1_vld_file_id: vld_search_record.freecen1_vld_file_id, birth_county: old_place_record.chapman_code, birth_place: old_place_record.place_name }, '$set' => { birth_county: new_place_record.chapman_code, birth_place: new_place_record.place_name })
            message_line = "Search Records VLD Entry POBs updated = #{vld_entry_recs_updated.inspect}"
            output_to_log(message_file, report_log, message_line)
          end
          recs_to_update = FreecenIndividual.where(birth_county: old_place_record.chapman_code, birth_place: old_place_record.place_name, freecen1_vld_file_id: vld_search_record.freecen_individual_id).count
          next if recs_to_update.zero?

          vld_individ_recs_updated = FreecenIndividual.collection.update_many({_id: vld_search_record.freecen_individual_id, birth_county: old_place_record.chapman_code, birth_place: old_place_record.place_name }, '$set' => { birth_county: new_place_record.chapman_code, birth_place: new_place_record.place_name })
          message_line = "Search Records VLD Individual POBs updated = #{vld_individ_recs_updated.inspect}"
          output_to_log(message_file, report_log, message_line)
        end
        vld_pob_records_updated = SearchRecord.collection.update_many({birth_county: old_place_record.chapman_code, birth_place: old_place_record.place_name, freecen1_vld_file_id: { '$ne': nil } }, '$set' => { birth_county: new_place_record.chapman_code, birth_place: new_place_record.place_name })
        message_line = "Search Records VLD POBs updated = #{vld_pob_records_updated.inspect}"
        output_to_log(message_file, report_log, message_line)
      end

      new_place_record.update_attributes(cen_data_years: updated_new_cen_data_years, data_present: updated_cen_data_present) if fixit
      old_place_record.update_attributes(data_present: false, cen_data_years: []) if fixit
      message_line = 'Updated places'
      output_to_log(message_file, report_log, message_line)
      message_line = "#{old_place_record.inspect}"
      output_to_log(message_file, report_log, message_line)
      message_line = "#{new_place_record.inspect}"
      output_to_log(message_file, report_log, message_line)
      Freecen2PlaceCache.refresh(new_place_record.chapman_code) if fixit
    end
    running_time = Time.now - start_time
    message = 'Finished' if message.blank?
    message_line = "#{message} after #{running_time}"
    output_to_log(message_file, report_log, message_line)
    unless userid == 'n/a'
      require 'user_mailer'
      user_rec = UseridDetail.userid(userid).first

      email_subject = "FreeCEN: #{move_info}"
      email_body = 'See attached Log file.'
      log_name = "Move_freecen2_place_#{old_place_record.chapman_code}_#{old_place_record.place_name}.log"
      email_to = user_rec.email_address

      p "Sending email to #{userid} - FreeCEN: #{move_info}"

      UserMailer.freecen_move_fc2_place_linkages_report(email_subject, email_body, report_email_log, log_name, email_to).deliver_now
    end

    # end task
  end

  def self.output_to_log(message_file, report_log, message_line)
    output_to_log(message_file, report_log, message_line).to_s
    report_log += "\n"
    report_log += message_line
    .to_s
  end
end
