class FreecenCsvFileUnincorporate
  def self.unincorporate(file, userid)
    freecen_file = FreecenCsvFile.find_by(_id: file)
    file_name = freecen_file.file_name
    chapman_code = freecen_file.chapman_code
    county = County.find_by(chapman_code: chapman_code)
    owner = freecen_file.userid
    fc2_piece_id = freecen_file.freecen2_piece_id
    message = "#{file_name} for #{owner} in #{chapman_code} "
    p "#{file_name} for #{owner} in #{chapman_code} "
    result, messagea = freecen_file.can_we_unincorporate?
    message += messagea
    success = false
    if result
      success, messagea = unincorporate_records(freecen_file)
      message += messagea
      puts "#{message}"
    end
    if success
      UserMailer.unincorporation_report(county.county_coordinator, message, file_name, owner).deliver_now
      # Log the unincorporation
      FreecenCsvFile.create_audit_record('Unincorp',freecen_file, userid, fc2_piece_id)
    else
      UserMailer.unincorporation_report_failure(county.county_coordinator, message, file_name, owner).deliver_now
    end
  end

  def self.unincorporate_records(freecen_file)
    begin
      SearchRecord.where(freecen_csv_file_id: freecen_file.id).destroy_all
      num = FreecenCsvEntry.collection.update_many({ freecen_csv_file_id: freecen_file.id }, '$set' => { search_record_id: nil })
      freecen_file.update_attributes(incorporated: false, incorporated_date: nil)
      piece = freecen_file.freecen2_piece
      freecen_file.update_attributes(completes_piece: false) unless freecen_file.is_whole_piece(piece)
      total_incorp_files = 0
      piece.freecen_csv_files.each do |file|
        if file.incorporated?
          total_incorp_files += 1
        end
      end
      if total_incorp_files == 0
        successa = piece.update_attributes(status: '', status_date: nil)
        messagea = '. Piece status cleared.' if successa
      else
        successa = piece.update_attributes(status: 'Part', status_date: DateTime.now.in_time_zone('London'))
        messagea = '. Piece status set to Part.' if successa
      end
      success = true if successa
      message = " Success - entries updated" if success
      message += messagea
      freecen_file.reload
      piece.reload
      success, messageb = piece.update_place
      piece.freecen2_civil_parishes.each do |civil_parish|
        success, messagec = civil_parish.update_place(freecen_file)
        message += messagec unless success
        break unless success
      end
      PlaceCache.refresh(freecen_file.chapman_code) if success
      Freecen2PlaceCache.refresh(freecen_file.chapman_code) if success
    rescue Exception => msg
      success = false
      message = "#{msg}, #{msg.backtrace.inspect}"
    end
    [success, message]
  end
end
