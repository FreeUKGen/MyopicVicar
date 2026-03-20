namespace :freecen do
  desc 'Extract Freecen2 county contents for Records display and archive/historic data'
  task :calculate_county_contents, [:all_counties] => [:environment] do |t, args|
    if args.all_counties.present?
      mode = 'FULL'
    else
      mode = 'CHANGED-ONLY'  # only update counties with changed data
    end
    time = Time.current
    p "Starting #{time} - Mode = #{mode}"
    Freecen2CountyContent.calculate(time, mode)
    Freecen2CountyContentArchive.archive
    Freecen2CountyContentArchive.delete
    p 'Finished'
  end
end
