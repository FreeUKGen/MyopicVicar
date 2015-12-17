desc "update county statistics"
task :extract_county_stats => [:environment] do 
  p "start"
  start = Time.now
  puts start 
  County.all.each do |county|
    records = County.records(county.chapman_code) 
    county.update_attributes(:total_records => records[0], :baptism_records => records[1], :burial_records => records[2], 
                             :marriage_records => records[3], :files => records[4]) unless  county.blank?
  end
  p "finished"
  puts Time.now 
  elapse = Time.now - start
  puts elapse 
  
end
