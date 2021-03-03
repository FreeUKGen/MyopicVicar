desc "Fill_places_soundex: Populate Freecen2_places place_name_soundex and alternate_name_soundex."

task fill_places_soundex:  :environment do

  Freecen2Place.skip_callback(:save, :after, :update_places_cache)

  puts "Fill_places_soundex: Started."

  start_time = Time.now
  place_records = 0
  place_successful_records = 0
  alternate_records = 0
  alternate_successful_records = 0


  Freecen2Place.no_timeout.each do |place|

    place_records += 1
    if place.update_attribute(:place_name_soundex, Text::Soundex.soundex(place.standard_place_name))
      place_successful_records += 1
    end

    if (place_records % 1000 == 0)
      puts "Fill_places_soundex: #{place_records} records processed so far."
    end

    place.alternate_freecen2_place_names.each do |alt|

      alternate_records += 1
      if alt.update_attribute(:alternate_name_soundex, Text::Soundex.soundex(alt.standard_alternate_name))
        alternate_successful_records += 1
      end
    end
  end
  Freecen2Place.set_callback(:save, :after, :update_places_cache)
  puts "Fill_places_soundex: Out of #{place_records} total freecen2 place records, #{place_successful_records} records updated successfully"
  puts "Fill_places_soundex: Out of #{alternate_records} total alternate freecen2 place records, #{alternate_successful_records} records updated successfully"
  puts "Fill_places_soundex: Completed in #{Time.now - start_time} seconds."

end
