class MissingPlaceFields
  require "place"

  def self.process(limit)
    file_for_warning_messages = "#{Rails.root}/log/missing_place_fields.log"
    FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
    output_file = File.new(file_for_warning_messages, "w")
    start = Time.now
    output_file.puts start
    record_number = 0
    errors = 0
    Place.no_timeout.each do |place|
      record_number = record_number + 1
      break if record_number == limit.to_i
      if place.genuki_url.blank? && place.disabled == 'false' 
        errors = errors + 1
         output_file.puts ("#{place.id}, #{place.chapman_code}, #{place.place_name}, no genuki"  )
      end
      if place.county.blank? && place.disabled == 'false' 
        errors = errors + 1
         output_file.puts ("#{place.id}, #{place.chapman_code}, #{place.place_name}, county added"  )
         county = ChapmanCode.name_from_code(place.chapman_code)
         place.update_attributes(:county => county)
      end
      if place.chapman_code.blank? && place.disabled == 'false' 
        errors = errors + 1
         output_file.puts ("#{place.id}, #{place.chapman_code}, #{place.place_name}, no chapman code"  )
      end
      if (place.latitude.nil? && place.longitude.nil?) && place.disabled == 'false'  
        errors = errors + 1
        output_file.puts ("#{place.id}, #{place.chapman_code}, #{place.place_name}, no location coordinates"  )
      end

    end
    puts " #{errors} errors" 
    output_file.puts " #{errors} errors"    
    output_file.puts Time.now 
    elapse = Time.now - start
    output_file.puts elapse
    output_file.close
    p "finished"
  end
end
