class FreecenCsvFileUnincorporate

  def self.unincorporate(file, owner)
    freecen_file = FreecenCsvFile.find_by(file_name: file.to_s, chapman_code: owner.to_s)
    county = County.chapman_code(owner.to_s).first
    message = "#{file} for #{owner} "
    success, messagea = unincorporate_records(freecen_file)
    message += messagea
    if success
      UserMailer.unincorporation_report(county.county_coordinator, message, file, owner).deliver_now
    else
      UserMailer.unincorporation_report_failure(county.county_coordinator, message, file, owner).deliver_now
    end
  end

  def self.unincorporate_records(freecen_file)
    begin
      freecen_file.freecen_csv_entries.each do |entry|
        entry.update_attributes(search_record_id: nil)
      end
      SearchRecord.collection.delete_many(freecen_csv_file_id: freecen_file.id)
      freecen_file.update_attributes(incorporated: false, incorporated_date: nil)
      success = true
      message = 'success'
      piece = freecen_file.freecen2_piece
      freecen_file.reload
      piece.reload
      action = piece.do_we_update_place?
      p action
      if action
        place = piece.freecen2_place
        p place.cen_data_years
        place.cen_data_years.delete_if { |year| year == piece.year }
        place.data_present = false
        success = place.save
        PlaceCache.refresh(freecen_file.chapman_code) if success
        message = 'Failed to update place' unless success
      end
    rescue Exception => msg
      success = false
      message = "#{msg}, #{msg.backtrace.inspect}"
    end
    [success, message]
  end
end
