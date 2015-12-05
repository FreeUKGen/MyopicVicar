namespace :freereg do

  desc "Extract search and site statistics"
  task :clean_search_queries => [:environment] do 


#    days_old = Rails.application.config.days_to_retain_search_queries
    p Time.now
    SearchStatistic.calculate
    SiteStatistic.calculate
#    SearchQuery.where(:c_at.lt => (Time.now.to_datetime - days_old)).delete_all
  end

end

