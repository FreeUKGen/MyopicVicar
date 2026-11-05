namespace :freecen do
  desc "Freecen2PlaceExtractUniqueNames"
  task :Freecen2PlaceExtractUniqueNames, [:full_update] => [:environment] do |t, args|
    require 'freecen2_place_extract_unique_name'
    full_update = args.full_update.present? ? 'FULL UPDATE' : ''
    puts "Extracting freecen2_place unique names #{full_update}"
    Freecen2PlaceExtractUniqueName.process(full_update)
    puts "Completed Extracting unique names for freecen2_place records #{full_update}"
  end
end
