namespace :freecen do
  desc "Freecen2PlaceExtractUniqueNames"
  task :Freecen2PlaceExtractUniqueNames, [:days] => [:environment] do |t, args|
    require 'freecen2_place_extract_unique_name'
    days = args.days.to_i
    puts "Extracting freecen2_place unique names"
    Freecen2PlaceExtractUniqueName.process(days)
    if days == 0
      puts "Completed Extracting unique names for all freecen2_place records"
    else
      puts "Completed Extracting unique names for freecen2_place records modified in last #{days} days"
    end
  end
end
