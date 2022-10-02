namespace :freecen do
  desc 'Archive Freecen2 site statistics'
  task :archive_site_statistics, [:day, :month, :year] => [:environment] do |t, args|
    if args.day.present?
      time = Time.new(args.year.to_i, args.month.to_i, args.day.to_i)
      p "Starting #{time}"
      Freecen2SiteStatisticArchive.archive(time)
    else
      p "Starting #{Time.current}"
      Freecen2SiteStatisticArchive.archive
    end
    p "Finished #{Time.current}"
  end
end
