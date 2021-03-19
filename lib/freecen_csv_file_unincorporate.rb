class FreecenCsvFileUnincorporate
  def self.unincorporate(file)
    freecen_file = FreecenCsvFile.find_by(_id: file)
    file_name = freecen_file.file_name
    chapman_code = freecen_file.chapman_code
    county = County.find_by(chapman_code: chapman_code)
    owner = freecen_file.userid
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
    else
      UserMailer.unincorporation_report_failure(county.county_coordinator, message, file_name, owner).deliver_now
    end
  end

  def self.unincorporate_records(freecen_file)
    begin
      SearchRecord.where(freecen_csv_file_id: freecen_file.id).delete_all
      num = FreecenCsvEntry.collection.update_many({ freecen_csv_file_id: freecen_file.id }, '$set' => { search_record_id: nil })
      freecen_file.update_attributes(incorporated: false, incorporated_date: nil)
      success = true
      message = "Success #{num} entries updated"
      piece = freecen_file.freecen2_piece
      freecen_file.reload
      piece.reload
      success, message = piece.update_place
      piece.freecen2_civil_parishes.each do |civil_parish|
        success, messagea = civil_parish.update_place(freecen_file)
        message += messagea unless success
        break unless success
      end
      PlaceCache.refresh(freecen_file.chapman_code) if success
    rescue Exception => msg
      success = false
      message = "#{msg}, #{msg.backtrace.inspect}"
    end
    [success, message]
  end
end
