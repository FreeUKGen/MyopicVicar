class DumpPlaceAsCsvFile
  def self.process(file, limit, chapman_code)
    limit = limit.to_i
    file = file.to_s
    chapman_code = chapman_code.to_s
    base = Rails.root.join('tmp', file)
    @number_of_line = 0
    data_file = File.new(base, 'w')
    data_file.puts 'country,county,chapman_code,place_name,last_amended,location,grid_reference,latitude,longitude,source,website_url,place_notes,original_country,original_county,original_chapman_code,original_place_name,original_grid_reference,original_latitude,original_longitude,original_source,reason_for_change,other_reason_for_change,disabled,master_place_lat,master_place_lon,alternate,alternate,alternate'
    if chapman_code.casecmp('ALL').zero?
      Place.not_disabled.order_by(chapman_code: 1, place_name: 1).each do |place|
        break if @number_of_line > limit

        @number_of_line += 1
        message = "#{place.country}"
        message += ",#{place.county}"
        message += ",#{place.chapman_code}"
        message += ",\"#{place.place_name}\""
        message += ",\"#{place.last_amended}\""
        message += ",#{place.grid_reference}"
        message += ",#{place.latitude}"
        message += ",#{place.longitude}"
        message += ",\"#{place.source}\""
        message += ",\"#{place.genuki_url}\""
        message += ",\"#{place.place_notes}\""
        message += ",#{place.original_country}"
        message += ",#{place.original_county}"
        message += ",#{place.original_chapman_code}"
        message += ",\"#{place.original_place_name}\""
        message += ",#{place.original_grid_reference}"
        message += ",#{place.original_latitude}"
        message += ",#{place.original_longitude}"
        message += ",\"#{place.original_source}\""
        message += ",\"#{place.reason_for_change}\""
        message += ",\"#{place.other_reason_for_change}\""
        message += ",#{place.disabled}"
        message += ",#{place.master_place_lat}"
        message += ",#{place.master_place_lon}"
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
        message = "#{place.country}"
        message += ",#{place.county}"
        message += ",#{place.chapman_code}"
        message += ",\"#{place.place_name}\""
        message += ",\"#{place.last_amended}\""
        message += ",#{place.grid_reference}"
        message += ",#{place.latitude}"
        message += ",#{place.longitude}"
        message += ",\"#{place.source}\""
        message += ",\"#{place.genuki_url}\""
        message += ",\"#{place.place_notes}\""
        message += ",#{place.original_country}"
        message += ",#{place.original_county}"
        message += ",#{place.original_chapman_code}"
        message += ",\"#{place.original_place_name}\""
        message += ",#{place.original_grid_reference}"
        message += ",#{place.original_latitude}"
        message += ",#{place.original_longitude}"
        message += ",\"#{place.original_source}\""
        message += ",\"#{place.reason_for_change}\""
        message += ",\"#{place.other_reason_for_change}\""
        message += ",#{place.disabled}"
        message += ",#{place.master_place_lat}"
        message += ",#{place.master_place_lon}"
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
