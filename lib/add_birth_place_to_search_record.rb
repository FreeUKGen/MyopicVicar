class AddBirthPlaceToSearchRecord

  def self.process(limit, fix)
    #The purpose of this clean up utility is to eliminate search records that are unconnected with an entry. Or an entry without a batch
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")

    file_for_warning_messages = "log/add_birth_place_to_search_record.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    message_file = File.new(file_for_warning_messages, "w")
    p "#{limit},  #{fix}"
    records = 0

    time_start = Time.now
    SearchRecord.no_timeout.each do |record|


      next unless record.freecen_csv_entry_id.present?
      entry_id = record.freecen_csv_entry_id
      entry = FreecenCsvEntry.id(entry_id).first unless entry_id.nil?
      next unless entry.present?

      records = records + 1
      break if records == limit.to_i
      if records == (records / 10000) * 10000
        p records
        time_diff = Time.now - time_start
        average = time_diff * 1000 / records
        p average
        message_file.puts "#{records},  #{average}"
      end

      if entry.birth_place.present?
        birth_place = entry.birth_place
      elsif entry.verbatim_birth_place.present?
        birth_place = entry.verbatim_birth_county
      end
      record.update_attributes(birth_place: birth_place) if birth_place.present?


    end
    p records

    time_diff = Time.now - time_start
    average_record = time_diff * 1000 / records

    p average_record

    message_file.puts "#{records}, #{average_record}"
  end
end
