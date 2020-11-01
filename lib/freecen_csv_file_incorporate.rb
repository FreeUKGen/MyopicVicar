class FreecenCsvFileIncorporate
  def self.incorporate(file, owner)
    freecen_file = FreecenCsvFile.find_by(file_name: file.to_s, chapman_code: owner.to_s)
    county = County.chapman_code(owner.to_s).first
    message = "#{file} for #{owner} "
    success, messagea = incorporate_records(freecen_file)
    message += messagea
    if success
      UserMailer.incorporation_report(county.county_coordinator, message, file, owner).deliver_now
    else
      UserMailer.incorporation_report_failure(county.county_coordinator, message, file, owner).deliver_now
    end
  end

  def self.incorporate_records(freecen_file)
    enumeration_districts = {}
    place_ids = {}
    begin
      piece = freecen_file.freecen2_piece
      district = piece.freecen2_district
      chapman_code = freecen_file.chapman_code
      freecen_file_id = freecen_file.id
      freecen_file.freecen_csv_entries.all.no_timeout.each do |entry|
        parish = entry.civil_parish
        enumeration_districts[parish] = [] if enumeration_districts[parish].blank?
        enumeration_districts[parish] << entry.enumeration_district unless enumeration_districts[parish].include?(entry.enumeration_district)
        place_ids[parish] = entry.freecen2_civil_parish.freecen2_place unless place_ids.key?(parish)
        entry.translate_individual(piece, district, chapman_code, place_ids[parish], freecen_file_id)
      end
      message = 'success'
      successa = freecen_file.update_attributes(incorporated: true, enumeration_districts: enumeration_districts, incorporation_lock: true,
                                                incorporated_date: DateTime.now.in_time_zone('London'))
      # the translate individual adds the civil parishes
      # we need to add the piece place

      #place = piece.freecen2_place
      #place.cen_data_years << freecen_file.year unless place.cen_data_years.present? && place.cen_data_years.include?(freecen_file.year)
      #place.data_present = true
      #successb = place.save if successa
      PlaceCache.refresh(freecen_file.chapman_code) if successa #&& successb
      success = true if successa #&& successb
      message = 'File update and or place update failed' unless successa && successb
    rescue Exception => msg
      success = false
      message = "#{msg}, #{msg.backtrace.inspect}"
    end
    [success, message]
  end
end
