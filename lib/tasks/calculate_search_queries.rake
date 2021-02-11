namespace :freereg do
  desc 'Extract search statistics'
  task calculate_search_queries: [:environment] do
    p Time.current
    SearchStatistic.calculate
  end
end

namespace :freecen do
  desc 'Extract search statistics'
  task calculate_search_queries: [:environment] do
    p Time.current
    Freecen2SearchStatistic.calculate
  end
end
