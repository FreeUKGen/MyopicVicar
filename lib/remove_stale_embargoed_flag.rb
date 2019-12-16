class RemoveStaleEmbargoedFlag
  def self.process(limit)
    this_year = DateTime.now.year.to_i
    file_for_warning_messages = Rails.root.join('log', "remove_stale_embargoed_flag_ #{this_year}.log")
    message_file = File.new(file_for_warning_messages, 'w')
    message_file.puts "Removing flags for #{this_year} year and earlier on #{Rails.application.config.website}"
    number = 0
    unembargoed = 0
    entries = Freereg1CsvEntry.where(:embargo_records.exists => true).hint("entry_id_embargo_id").all
    message_file.puts entries.length
    entries.no_timeout.each do |entry|
      number = number + 1
      break if number > limit.to_i && limit.to_i > 0
      if entry.embargo_records.last.embargoed == true && (entry.embargo_records.last.release_year.to_i <= this_year.to_i)
        unembargoed = unembargoed + 1
        record = entry.search_record
        record.update_attributes(embargoed: false, release_year: this_year)
      end
    end
    message_file.puts " #{number} processed and #{unembargoed} were unembargoed"
    message_file.close
  end
end
