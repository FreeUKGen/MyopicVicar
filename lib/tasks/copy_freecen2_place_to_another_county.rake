desc "Copy a place between counties"
task :copy_freecen2_place_to_another_county, [:chapman1, :chapman2] => :environment do |t, args|
  source_chapman_code = args.chapman1
  target_chapman_code = args.chapman2
  p "Started copy places for #{source_chapman_code} to #{target_chapman_code}"
  Freecen2Place.where(chapman_code: source_chapman_code).each do |place|
    new_place = place.clone
    new_place.chapman_code = target_chapman_code
    new_place.county = ChapmanCode.name_from_code(target_chapman_code)
    new_place.original_chapman_code = place.chapman_code
    new_place.original_county = place.county
    result = new_place.save
    p "#{place.place_name}, #{place.chapman_code} failed #{new_place.errors.full_messages}" unless result
  end
  p "finished"
end
