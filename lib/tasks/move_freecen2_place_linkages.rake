namespace :freecen do
  desc 'Moves freecen2 place linkages from one place to another'

  task :move_freecen2_place_linkages, [:userid, :old, :new, :fix] => :environment do |_t, args|
    # based on freecen:convert_freecen2_place_id rake task
    # Print the time before start the process

    require 'user_mailer'

    def self.output_to_log(message_file, message_line)
      @report_email_log += "\n"
      @report_email_log += message_line
      message_file.puts message_line.to_s
      p message_line.to_s
    end

    # START

    start_time = Time.now
    old_place = args.old.to_s
    new_place = args.new.to_s
    fixit = args.fix.to_s == 'Y'
    mode = fixit ? 'UPDATE' : 'REVIEW only'
    userid = args.userid.present? ? args.userid.to_s : 'NA'
    file_for_warning_messages = "log/move_freecen2_place_#{userid}_#{start_time.strftime('%Y%m%d%H%M')}.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
    message_file = File.new(file_for_warning_messages, 'w')
    move_info = "Move of freecen2_place linkages from freecen2_place_id #{old_place} to #{new_place} in #{mode} mode."
    @report_email_log = ''
    message = ''
    old_place_record = Freecen2Place.find_by(_id: old_place)
    new_place_record = Freecen2Place.find_by(_id: new_place)
    if old_place_record.blank? || new_place_record.blank?
      message = "Either old #{old_place_record} or new #{new_place_record} is not found"
      fixit = false
    else
      move_info = "Move of freecen2_place linkages from  #{old_place_record.place_name} (#{old_place_record.chapman_code}) to #{new_place_record.place_name} (#{new_place_record.chapman_code}) in #{mode} mode"
      message_line = "Starting #{move_info} at #{start_time}"
      output_to_log(message_file, message_line)
      message_line = 'Before Linkages Move'
      output_to_log(message_file, message_line)
      message_line = "*** Old Place record *** = #{old_place_record.inspect}"
      output_to_log(message_file, message_line)
      message_line = "*** New Place record *** = #{new_place_record.inspect}"
      output_to_log(message_file, message_line)
      message_line = '** Census years **'
      output_to_log(message_file, message_line)
      message_line = "Old Place Census years = #{old_place_record.cen_data_years}"
      output_to_log(message_file, message_line)
      message_line = "New Place existing Census years = #{new_place_record.cen_data_years}"
      output_to_log(message_file, message_line)
      updated_new_cen_data_years = new_place_record.cen_data_years | old_place_record.cen_data_years
      updated_new_cen_data_years.sort!
      message_line = "Updated Census years for New Place will be = #{updated_new_cen_data_years}"
      output_to_log(message_file, message_line)
      message_line = '** Search Data present **'
      output_to_log(message_file, message_line)
      message_line = "Old Place Search Data present = #{old_place_record.data_present}"
      output_to_log(message_file, message_line)
      message_line = "New Place Search Data present = #{new_place_record.data_present}"
      output_to_log(message_file, message_line)
      updated_search_data_present = old_place_record.data_present || new_place_record.data_present ? true : false
      message_line = "Updated Search Data present for New Place will be = #{updated_search_data_present}"
      output_to_log(message_file, message_line)
      message_line = '** Districts **'
      output_to_log(message_file, message_line)
      old_freecen2_districts = Freecen2District.where(freecen2_place_id: old_place_record._id).count
      message_line = "Old Place Districts count = #{old_freecen2_districts}"
      output_to_log(message_file, message_line)
      if old_freecen2_districts.positive? && fixit
        districts_updated = Freecen2District.collection.update_many({ freecen2_place_id: old_place_record._id }, '$set' => { freecen2_place_id: new_place_record._id })
        message_line = districts_updated
        output_to_log(message_file, message_line)
      end
      message_line = '** Pieces **'
      output_to_log(message_file, message_line)
      old_freecen2_pieces = Freecen2Piece.where(freecen2_place_id: old_place_record._id).count
      message_line = "Old Place Pieces count = #{old_freecen2_districts}"
      output_to_log(message_file, message_line)
      if old_freecen2_pieces.positive? && fixit
        pieces_updated = Freecen2Piece.collection.update_many({ freecen2_place_id: old_place_record._id }, '$set' => { freecen2_place_id: new_place_record._id})
        message_line = pieces_updated
        output_to_log(message_file, message_line)
      end
      message_line = '** Civil Parishes **'
      output_to_log(message_file, message_line)
      old_freecen2_civil_parishes = Freecen2CivilParish.where(freecen2_place_id: old_place_record._id).count
      message_line = "Old Place Civil Parishes count = #{old_freecen2_civil_parishes}"
      output_to_log(message_file, message_line)
      if old_freecen2_civil_parishes.positive? && fixit
        parishes_updated = Freecen2CivilParish.collection.update_many({ freecen2_place_id: old_place_record._id }, '$set' => { freecen2_place_id: new_place_record._id})
        message_line = parishes_updated
        output_to_log(message_file, message_line)
      end
      message_line = '** Search Records **'
      output_to_log(message_file, message_line)
      old_search_records = SearchRecord.where(freecen2_place_id: old_place_record._id).count
      message_line = "Old Place Search Records count = #{old_search_records}"
      output_to_log(message_file, message_line)
      csv_records_present = old_search_records.positive? && SearchRecord.where(freecen2_place_id: old_place_record._id).first.freecen_csv_file_id.present? ? true : false
      message_line = "Old Place Search Records - CSV File(s) = #{csv_records_present}"
      output_to_log(message_file, message_line)
      vld_records_present = old_search_records.positive? && SearchRecord.where(freecen2_place_id: old_place_record._id).first.freecen1_vld_file_id.present? ? true : false
      message_line = "Old Place Search Records - VLD File(s) = #{vld_records_present}"
      output_to_log(message_file, message_line)
      message_line = '** Search Records Places Of Birth **'
      output_to_log(message_file, message_line)
      old_search_records_pobs = SearchRecord.where(birth_chapman_code: old_place_record.chapman_code, birth_place: old_place_record.place_name).count
      message_line = "Old Place name used in Search Records Place Of Birth count = #{old_search_records_pobs}"
      output_to_log(message_file, message_line)
      alternative_names = SortedSet.new
      alternative_names_list = '['
      if old_place_record.alternate_freecen2_place_names.present?
        old_place_record.alternate_freecen2_place_names.each do |alt_name|
          alt_name_used = SearchRecord.where(birth_chapman_code: old_place_record.chapman_code, birth_place: alt_name.alternate_name).count
          alternative_names << alt_name.alternate_name if alt_name_used.positive?
        end
        unless alternative_names.size.zero?
          alternative_names.each do |alt_pob|
            alternative_names_list += "#{alt_pob}, "
          end
          alternative_names_used_list = alternative_names_list[0..-3] + ']'
        end
        alt_names_info = alternative_names_list == '[' ? 'None' : alternative_names_used_list
        message_line = "Old Place Alternate Place Names used in Search Records Place of Birth = #{alt_names_info}"
        output_to_log(message_file, message_line)
      end

      # UPDATE Search recs for Place Id

      if old_search_records.positive? && fixit
        records_updated = SearchRecord.collection.update_many({ freecen2_place_id: old_place_record._id }, '$set' => { freecen2_place_id: new_place_record._id, location_names: [new_place_record.place_name] })
        message_line = "Search Records updated = #{records_updated.inspect}"
        output_to_log(message_file, message_line)
      end
      if old_search_records_pobs.positive? && fixit
        records_updated = SearchRecord.collection.update_many({ birth_county: old_place_record.chapman_code, birth_place: old_place_record.place_name }, '$set' => { birth_county: new_place_record.chapman_code, birth_place: new_place_record.place_name })
        message_line = "Search Records Places Of Birth updated = #{records_updated.inspect}"
        output_to_log(message_file, message_line)
      end
      if !alternative_names_list == '' && fixit
        message_line = "** Search Records Places Of Birth for old place used the following Alternate Place Names which should be added to the New Place if not already present: [#{alternative_names_list}] **"
        output_to_log(message_file, message_line)
      end
      if fixit
        new_place_record.update_attributes(cen_data_years: updated_new_cen_data_years, data_present: updated_search_data_present)
        old_place_record.update_attributes(disabled: 'true', data_present: false, cen_data_years: [])
        message_line = 'Freecen2_place Records after update'
        output_to_log(message_file, message_line)
        message_line = "*** Old Place record *** = #{old_place_record.inspect}"
        output_to_log(message_file, message_line)
        message_line = "*** New Place record *** = #{new_place_record.inspect}"
        output_to_log(message_file, message_line)
        Freecen2PlaceCache.refresh(new_place_record.chapman_code)
      end
    end

    running_time = Time.now - start_time
    message = "Finished - #{mode} mode run" if message.blank?
    message_line = "#{message} after #{running_time}s"
    output_to_log(message_file, message_line)
    unless userid == 'NA'
      user_rec = UseridDetail.userid(userid).first

      email_subject = "FreeCEN: #{move_info}"
      email_body = 'See attached Log file.'
      log_name = 'Move_freecen2_place.Log'
      email_to = user_rec.email_address

      p "Sending email to #{userid} - FreeCEN: #{move_info}"

      UserMailer.freecen_move_fc2_place_linkages_report(email_subject, email_body, @report_email_log, log_name, email_to).deliver_now
    end

    # end task
  end
end
