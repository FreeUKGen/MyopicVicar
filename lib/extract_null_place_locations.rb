class ExtractNullPlaceLocations
  class << self
    def process(limit)
      file_for_messages = 'log/extract_null_place_locations.log'
      message_file = File.new(file_for_messages, 'w')
      limit = limit.to_i
      p 'Producing report of the extract_null_place_locationss'
      message_file.puts 'Producing report of the extract_null_place_locations'
      num = 0
      time_start = Time.now

      Place.each do |blank_piece|
        if blank_piece.latitude == "60"
          num = num + 1
          message_file.puts "#{blank_piece.chapman_code},#{blank_piece.place_name} "
        end
      end


      time_elapsed = Time.now - time_start
      p "Finished #{num} places in #{time_elapsed}"
    end
  end
end
