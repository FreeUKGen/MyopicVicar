class FreecenCsvFileUnincorporate

  def self.unincorporate(file, owner)
    freecen_file = FreecenCsvFile.find_by(file_name: file.to_s, chapman_code: owner.to_s)
    county = County.chapman_code(owner.to_s).first
    message = "#{file} for #{owner} "
    message += unincorporate_records(freecen_file)
    UserMailer.unincorporation_report(county.county_coordinator, message, file, owner).deliver_now
  end

  def self.unincorporate_records(freecen_file)
    SearchRecord.collection.delete_many(freecen_csv_file_id: freecen_file.id)
    freecen_file.update_attributes(incorporated: false, incorporated_date: nil)
    message = 'Records removed'
    message
  end
end
