class DownloadPlaceAsCsvFile
  def self.process(file, limit, chapman_code)
    limit = limit.to_i
    file = file.to_s
    chapman_code = chapman_code.to_s
    base = Rails.root.join('tmp', file)
    @number_of_line = 0
    data_file = File.new(base, 'w')
    data_file.puts 'chapman_code,place_name,grid_reference,latitude,longitude,source,website_url,place_notes,alternates'
    if chapman_code.casecmp('ALL').zero?
      Place.not_disabled.order_by(place_name: 1).each do |place|
        break if @number_of_line > limit

        @number_of_line += 1
        message = "#{place.chapman_code}"
        message += ",\"#{place.place_name}\""
        message += ",#{place.grid_reference}"
        message += ",#{place.latitude}"
        message += ",#{place.longitude}"
        message += ",\"#{place.source}\""
        message += ",\"#{place.genuki_url}\""
        message += ",\"#{place.place_notes}\""
        if place.alternateplacenames.present?
          place.alternateplacenames.each do |alternate|
            message += ",\"#{alternate.alternate_name}\""
          end
        end
        data_file.puts message
      end
    else
      Place.chapman_code(chapman_code).not_disabled.order_by(place_name: 1).each do |place|
        break if @number_of_line > limit

        @number_of_line += 1
        message = "#{place.chapman_code}"
        message += ",\"#{place.place_name}\""
        message += ",#{place.grid_reference}"
        message += ",#{place.latitude}"
        message += ",#{place.longitude}"
        message += ",\"#{place.source}\""
        message += ",\"#{place.genuki_url}\""
        message += ",\"#{place.place_notes}\""
        if place.alternateplacenames.present?
          place.alternateplacenames.each do |alternate|
            message += ",\"#{alternate.alternate_name}\""
          end
        end
        data_file.puts message
      end

    end
    data_file.close
    p "#{@number_of_line} records processed"
  end
end
