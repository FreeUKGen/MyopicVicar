namespace :freereg do
  desc 'Extract site statistics'
  task calculate_site_statistics: [:environment] do
    p Time.current
    SiteStatistic.calculate
  end
end

namespace :freecen do
  desc 'Extract Freecen2 site statistics'
  task calculate_site_statistics: [:environment] do
    p Time.current
    Freecen2SiteStatistic.calculate
  end
end
