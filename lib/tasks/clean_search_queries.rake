namespace :freereg do

  desc "Save freereg databases to a backup file"
  task :clean_search_queries, [:days_old] => [:environment] do  |t,args|


    days_old = args[:days_old].to_i

    SearchStatistic.calculate
    SearchQuery.where(:c_at.lt => (Time.now.to_datetime - days_old)).delete_all
  end

end

