class AddBirthPlaceToSearchRecordIndividual

  def self.process(limit, fix)
    #The purpose of this clean up utility is to eliminate search records that are unconnected with an entry. Or an entry without a batch
    Mongoid.load!("#{Rails.root}/config/mongoid.yml")

    file_for_warning_messages = "log/add_birth_place_to_search_record.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages) )
    message_file = File.new(file_for_warning_messages, "w")
    p "#{limit},  #{fix}"
    records = 0

    time_start = Time.now
    FreecenIndividual.no_timeout.each do |record|
      records = records + 1
      break if records == limit.to_i
      search_record = record.search_record
      next if search_record.birth_place.present?
      if records == (records / 10000) * 10000
        time_diff = Time.now - time_start
        average = time_diff * 1000 / records
        p "#{records},  #{average}"
        sleep(5)
        message_file.puts "#{records},  #{average}"
      end
      search_record.update_attributes(birth_place: record.birth_place)
    end
    time_diff = Time.now - time_start
    average_record = time_diff * 1000 / records
    p 'finished'
    p "#{records}, #{average_record}"
    message_file.puts "#{records}, #{average_record}"
  end
end
