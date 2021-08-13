class CreateFreecen2PlaceEdit
  def self.process(limit)
    limit = limit.to_i
    @number_of_line = 0
    @number_processed = 0
    Freecen2Place.not_disabled.no_timeout.order_by(place_name: 1).each do |place|
      @number_processed += 1
      break if @number_of_line > limit

      modified = false
      modified = true if place.place_name.present? && place.place_name == place.original_place_name
      modified = true if place.chapman_code.present? && place.chapman_code == place.original_chapman_code
      modified = true if place.county.present? && place.county == place.original_county
      modified = true if place.country.present? && place.country == place.original_country
      modified = true if place.grid_reference.present? && place.grid_reference == place.original_grid_reference
      modified = true if place.latitude.present? && place.latitude == place.original_latitude
      modified = true if place.longitude.present? && place.longitude == place.original_longitude
      modified = true if place.source.present? && place.source == place.original_source
      next unless modified

      @number_of_line += 1
      edit = Freecen2PlaceEdit.new(editor: 'unknown', reason: place.reason_for_change)
      edit[:previous_chapman_code] = place.original_chapman_code
      edit[:previous_county] = place.original_county
      edit[:previous_country] = place.original_country
      edit[:previous_place_name] = place.original_place_name
      edit[:previous_grid_reference] = place.original_grid_reference
      edit[:previous_latitude] = place.original_latitude
      edit[:previous_longitude] = place.original_longitude
      edit[:previous_source] = place.original_source
      edit[:previous_website] = place.genuki_url
      edit[:previous_notes] = place.place_notes
      edit[:created] = place.u_at
      edit[:previous_alternate_place_names] = []
      place.alternate_freecen2_place_names.each do |alternate|
        edit[:previous_alternate_place_names] << alternate.alternate_name
      end
      place.freecen2_place_edits << edit
    end
    p "#{@number_processed} records processed with #{@number_of_line} edits"
  end
end
