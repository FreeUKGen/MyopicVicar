class UpdateFreecen2PlaceFromCsvFile
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
    file_for_warning_messages = Rails.root.join('log', 'country_messages.log')
    message_file = File.new(file_for_warning_messages, 'w')
    success, array = slurp_the_csv_file(base)
    p 'csv slurp failed' unless success
    message_file.puts "csv slurp failed" unless success
    crash unless success

    @number_of_line = 0
    @number_added = 0
    @number_skipped = 0
    length = array.length
    p "Started a freecen2 place update with limit of #{limit} with a file at #{base} with #{length} entries"

    array.each do |line|
      break if @number_of_line > limit

      @number_of_line += 1
      next if line[0].present? && line[0].strip == 'Chapman Code'
      next if line[0].blank?

      chapman_code = line[0]
      place_name = line[1].strip if line[1].present?
      grid_reference = line[2].strip if line[2].present?
      latitude = line[3].strip if line[3].present?
      longitude = line[4].strip if line[4].present?
      source = line[5].strip if line[5].present?
      genuki_url  = line[6].strip if line[6].present?
      place_notes = line[7].strip if line[7].present?
      alternates = []
      index = 8
      while index <= line.length
        alternates << line[index].strip if line[index].present?
        index += 1
      end
      if grid_reference.present? && grid_reference.is_gridref?
        location = grid_reference.to_latlng.to_a
        latitude = location[0]
        longitude = location[1]
      end
      standard_place_name = Freecen2Place.standard_place(place_name)
      place = Freecen2Place.find_by(standard_place_name: standard_place_name)
      if place.present?
        p "Place #{place_name} already exists in #{chapman_code}"
        message_file.puts "Place #{place_name} already exists in #{chapman_code}"
        @number_skipped += 1
      else
        place = Freecen2Place.new(chapman_code: chapman_code, place_name: place_name, standard_place_name: standard_place_name, grid_reference: grid_reference, latitude: latitude,
                                  longitude: longitude, source: source, genuki_url: genuki_url, place_notes: place_notes)
        result = place.save
        if result
          @number_added += 1
          place.reload
          alternates.each do |alternate|
            standard_place_name = Freecen2Place.standard_place(alternate)
            place.alternate_freecen2_place_names << AlternateFreecen2PlaceName.new(alternate_name: alternate, standard_place_name: standard_place_name)
            place.save
          end
          p "#{place_name} created"
          message_file.puts "#{chapman_code}, #{place_name}, created"
        else
          p "#{place_name} creation failed"
          p line
        end
      end
    end
    p "#{@number_of_line} records processed with #{@number_added} added and #{@number_skipped}"
  end
end
