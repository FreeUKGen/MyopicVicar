class UploadPlaceDumpFromCsvFileToFreecen2PlaceCollection
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
    params = {}
    p "Started a freecen2 place update with limit of #{limit} with a file at #{base} with #{length} entries"

    array.each do |line|
      break if @number_of_line > limit
      p line
      @number_of_line += 1
      next if line[0].present? && line[0].strip == 'Chapman Code'
      next if line[0].blank?


      param[:country] = line[0]
      param[:county] = line[1] #{place.county}"
      param[:chapman_code] = line[2] #{place.chapman_code}"
      param[:place_name] = line[3]
      param[:last_amended] = line[4]
      param[:location] = line[5]
      param[:grid_reference] = line[6] #{place.grid_reference}"
      param[:latitude] = line[7] #{place.latitude}"
      param[:longitude] = line[8] #{place.longitude}"
      param[:source] = line[9]
      param[:genuki_url] = line[10]
      param[:place_notes] = line[11]
      param[:original_country] = line[12] #{place.original_country}"
      param[:original_county] = line[13] #{place.original_county}"
      param[:original_chapman_code] = line[14] #{place.original_chapman_code}"
      param[:original_place_name] = line[15]
      param[:original_grid_reference] = line[16] #{place.original_grid_reference}"
      param[:original_latitude] = line[17] #{place.original_latitude}"
      param[:original_longitude] = line[18] #{place.original_longitude}"
      param[:original_source] = line[19]
      param[:reason_for_change] = line[20]
      param[:other_reason_for_change] = line[21]
      param[:disabled] = line[22] #{place.disabled}"
      param[:master_place_lat] = line[23] #{place.master_place_lat}"
      param[:master_place_lon] = line[24] #{place.master_place_lon}"
      alternates = []
      index = 25
      while index <= line.length
        alternates << line[index].strip if line[index].present?
        index += 1
      end



      if param[:grid_reference].present? && param[:grid_reference].is_gridref?
        param[:location] = param[:grid_reference].to_latlng.to_a
        param[:latitude] = location[0]
        param[:longitude] = location[1]
      end
      standard_place_name = Freecen2Place.standard_place(param[:place_name])
      place = Freecen2Place.find_by(standard_place_name: standard_place_name)
      if place.present?
        p 'Place already exists'
        @number_skipped += 1
      else
        place = Freecen2Place.new(params)
        alternates.each do |alternate|
          place.alternate_freecen2_place_names << AlternateFreecen2PlaceName.new(alternate_name: alternate)
          #place.save
          #place.reload
        end
        p place
        #result = place.save
        if result
          p "#{place_name} created"
          message_file.puts "#{chapman_code}, #{place_name}, created"
          @number_added += 1
        else
          p "#{place_name} creation failed"
          p line
        end
      end
    end
    p "#{@number_of_line} records processed with #{@number_added} added and #{@number_skipped}"
  end

end #end process
