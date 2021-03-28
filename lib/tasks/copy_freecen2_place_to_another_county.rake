desc "Copy a place between counties"
task :copy_freecen2_place_to_another_county, [:chapman] => :environment do |t, args|
  chapman_code = args.chapman
  p "Started copy places for #{chapman_code}"
  %w[ALD JSY GSY SRK].each do |code|
    Freecen2Place.where(chapman_code: code).each do |place|
      new_place = place.clone
      new_place.chapman_code = chapman_code
      new_place.county = ChapmanCode.name_from_code(chapman_code)
      new_place.country = 'Islands'
      new_place.original_chapman_code = place.chapman_code
      new_place.original_county = place.county
      new_place.original_country = place.country
      result = new_place.save
      p "#{place.place_name}, #{place.chapman_code} failed #{new_place.erroe.full_messages}" unless result
    end
  end
  p "finished"
end
