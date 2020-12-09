class DeleteFreecen2PlaceFromCsvFile
  def self.slurp_the_csv_file(filename)
    begin
      #we slurp in the full csv file
      array_of_data_lines = CSV.read(filename)
      success = true
    rescue Exception => msg
      success = false
      message = "#{msg}, #{msg.backtrace.inspect}"
      p message
      success = false
    end
    [success, array_of_data_lines]
  end

  def self.process(file, limit)
    limit = limit.to_i
    file = file.to_s
    base = Rails.root.join('tmp', file)
    file_for_warning_messages = Rails.root.join('log', 'delete_place_messages.log')
    message_file = File.new(file_for_warning_messages, 'w')
    success, array = slurp_the_csv_file(base)
    p 'csv slurp failed' unless success
    message_file.puts "csv slurp failed" unless success
    crash unless success

    @number_of_line = 0
    @number_deleted = 0
    @number_skipped = 0
    length = array.length
    p "Started a freecen2 place delete with limit of #{limit} with a file at #{base} with #{length} entries"

    array.each do |line|
      break if @number_of_line > limit
      p line

      @number_of_line += 1
      next if line[0].present? && line[0].strip == 'Chapman Code'
      next if line[0].blank?

      chapman_code = line[2]
      place_name = line[3].strip if line[3].present?
      standard_place_name = Freecen2Place.standard_place(place_name)
      p place_name
      place = Freecen2Place.find_by(chapman_code: chapman_code, place_name: place_name)
      p place
      if place.present?
        @number_deleted += 1
        p "Place #{place_name} found in #{chapman_code}"
        message_file.puts "Place #{place_name} found exists in #{chapman_code}"
        place.delete

      else
        @number_skipped += 1
        p "Place #{place_name} not found in #{chapman_code}"
        message_file.puts "Place #{place_name} not found exists in #{chapman_code}"
      end
    end
    p "#{@number_of_line} records processed with #{@number_deleted} deleted and #{@number_skipped} skipped"
  end
end
