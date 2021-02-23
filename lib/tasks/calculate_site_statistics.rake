namespace :freereg do
  desc 'Extract site statistics'
  task calculate_site_statistics: [:environment] do
    p Time.current
    SiteStatistic.calculate
  end
end

namespace :freecen do
  desc 'Extract Freecen2 site statistics'
  task :calculate_site_statistics, [:day, :month, :year] => [:environment] do |t, args|
    if args.day.present?
      time = Time.new(args.year.to_i, args.month.to_i, args.day.to_i)
      p "Starting #{time}"
      Freecen2SiteStatistic.calculate(time)
    else
      p "Starting #{Time.current}"
      Freecen2SiteStatistic.calculate
    end
    p 'Finished'
  end
end
