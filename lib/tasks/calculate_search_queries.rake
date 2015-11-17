namespace :freereg do

  desc "Extract search statistics"
  task :calculate_search_queries => [:environment] do 


#    days_old = Rails.application.config.days_to_retain_search_queries
    p Time.now
    SearchStatistic.calculate
    
#    SearchQuery.where(:c_at.lt => (Time.now.to_datetime - days_old)).delete_all
  end

end

