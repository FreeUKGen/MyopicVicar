namespace :freereg do

  desc "Extract site statistics"
  task :calculate_site_statistics => [:environment] do 


#    days_old = Rails.application.config.days_to_retain_search_queries
    p Time.now
    SiteStatistic.calculate
#    SearchQuery.where(:c_at.lt => (Time.now.to_datetime - days_old)).delete_all
  end

end

