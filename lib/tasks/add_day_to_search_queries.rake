desc "Correct a place"
task :add_day_to_search_queries => :environment do


  p "Started to add a day to search queries #{SearchQuery.count}"


  n = 0
  SearchQuery.all.no_timeout.each do |query|
    n = n + 1
    if query.day.blank?
      day = query.c_at.strftime("%F")
      query.update_attribute(:day, day)
    end
    p "#{n} queries processed" if ((n/10000).to_i)* 10000 == n
  end
  p "finished"
end
