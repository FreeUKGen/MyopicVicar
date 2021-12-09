namespace :freecen do
  desc 'Extract Freecen2 contents for Records display'
  task :calculate_contents, [:all_counties] => [:environment] do |t, args|
    if args.all_counties.present?
      mode = 'FULL'
    else
      mode = 'CHANGED-ONLY'  # only update counties with changed data
    end
    time = Time.current
    p "Starting #{time} - Mode = #{mode}"
    Freecen2Content.calculate(time,mode)
    p 'Finished'
  end
end
