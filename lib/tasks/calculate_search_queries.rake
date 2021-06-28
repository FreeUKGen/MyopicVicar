namespace :freereg do
  desc 'Extract search statistics'
  task calculate_search_queries: [:environment] do
    p Time.current
    SearchStatistic.calculate
    p 'finished'
  end
end

namespace :freecen do
  desc 'Extract search statistics'
  task calculate_search_queries: [:environment] do

    Freecen2SearchStatistic.calculate
    p 'finished'
  end
end
