namespace :freecen do
  desc 'Extract Freecen2 contents'
  task :calculate_contents, [:day, :month, :year] => [:environment] do |t, args|
    if args.day.present?
      time = Time.new(args.year.to_i, args.month.to_i, args.day.to_i)
      p "Starting #{time}"
      Freecen2Content.calculate(time)
    else
      p "Starting #{Time.current}"
      Freecen2Content.calculate
    end
    p 'Finished'
  end
end
