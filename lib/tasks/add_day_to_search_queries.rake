desc "Correct a place"
task :add_day_to_search_queries => :environment do


  p "Started to add a day to search queries"

  SearchQuery.all.no_timeout.each do |query|
    day = query.c_at.strftime("%F")
    query.update_attribute(:day, day)
  end
  p "finished"
end
