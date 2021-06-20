class FreecenCsvFileIncorporate
  def self.incorporate(file)
    freecen_file = FreecenCsvFile.find_by(_id: file)
    file_name = freecen_file.file_name
    chapman_code = freecen_file.chapman_code
    county = County.find_by(chapman_code: chapman_code)
    owner = freecen_file.userid
    message = "#{file_name} for #{owner} in #{chapman_code} "
    p "#{file_name} for #{owner} in #{chapman_code} "
    result, messagea = freecen_file.can_we_incorporate?
    message += messagea
    if result
      success, messagea = incorporate_records(freecen_file)
      message += messagea
    end
    if success
      UserMailer.incorporation_report(county.county_coordinator, message, file_name, owner).deliver_now
    else
      UserMailer.incorporation_report_failure(county.county_coordinator, message, file_name, owner).deliver_now
    end
  end


  def self.incorporate_records(freecen_file)
    enumeration_districts = {}
    place_ids = {}
    start = Time.now.to_i
    begin
      piece = freecen_file.freecen2_piece
      district = piece.freecen2_district
      chapman_code = freecen_file.chapman_code
      @freecen_file_id = freecen_file.id
      number = 0
      freecen_file.freecen_csv_entries.no_timeout.each do |entry|
        number += 1
        parish = entry.civil_parish
        enumeration_districts[parish] = [] if enumeration_districts[parish].blank?
        enumeration_districts[parish] << entry.enumeration_district unless enumeration_districts[parish].include?(entry.enumeration_district)
        place_ids[parish] = entry.freecen2_civil_parish.freecen2_place unless place_ids.key?(parish)
        entry.translate_individual(piece, district, chapman_code, place_ids[parish], @freecen_file_id)
      end

      time_end = Time.now.to_i
      actual = time_end - start
      per = actual / number
      puts "Success; #{number} records in #{actual} seconds or #{per} seconds a record"
      message = "success; #{number} records in #{actual} or #{per} seconds a record"
      successa = freecen_file.update_attributes(incorporated: true, enumeration_districts: enumeration_districts, incorporation_lock: true,
                                                incorporated_date: DateTime.now.in_time_zone('London'))
      # the translate individual adds the civil parishes

      successb = true
      if successa  && freecen_file.completes_piece?
        successb = piece.update_attributes(status: 'Online', status_date: DateTime.now.in_time_zone('London'))
        message += '. Piece status set to Online' if successb
      else
        successb = piece.update_attributes(status: 'Part', status_date: DateTime.now.in_time_zone('London'))
        message += '. Piece status set to Part' if successb
      end

      PlaceCache.refresh(freecen_file.chapman_code) if successa && successb
      message += '. Place cache rewritten.'
      success = true if successa && successb
      message = 'File update and or place update failed' unless successa && successb
    rescue Exception => msg
      puts msg
      puts msg.backtrace.inspect
      SearchRecord.where(freecen_csv_file_id: @freecen_file_id).delete_all
      FreecenCsvEntry.collection.update_many({ freecen_csv_file_id: @freecen_file_id }, '$set' => { search_record_id: nil })
      success = false
      message = "#{msg}, #{msg.backtrace.inspect}"
    end
    [success, message]
  end
end
