namespace :check_church_records do

  desc "Export Church entries into excel"
  task :check_church, [:limit,:fix] => :environment do |t, args|

  	file_for_output = "#{Rails.root}/log/church_records.csv"
    FileUtils.mkdir_p(File.dirname(file_for_output) )
    output_file = File.new(file_for_output, "w")
  	
    place = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
    record = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
    sorted_record = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
    h = Hash.new
  	
  	puts "========Get Church records"

    places = Place.all
    places.each do |entry|
      place[entry.id]['chapman_code'] = entry.chapman_code
      place[entry.id]['place_name'] = entry.place_name
    end
  	
  	churches = Church.all
    churches.each do |entry|
      entry.attributes.each do |k,v|
        if k == '_id'
          record[v] = Hash.new if record[k].nil?
          id = v
        end
      end

      entry.attributes.each { |k,v| record[id][k] = v }
      record[id]['place_name'] = place[record[id]['place_id']]['place_name']
      record[id]['chapman_code'] = place[record[id]['place_id']]['chapman_code']
    end  

    sorted_record = record.inject({}) do |h, (k, v)|
      h[k] = Hash[v.sort_by {|k1,v1| k1}]
      h
    end

    sorted_record.each do |k1,v1|
      sorted_record[k1]['church_notes'] = '' if sorted_record[k1]['church_notes'].nil?
      sorted_record[k1]['contributors'] = '' if sorted_record[k1]['contributors'].nil?
      sorted_record[k1]['datemax'] = '' if sorted_record[k1]['datemax'].nil?
      sorted_record[k1]['datemin'] = '' if sorted_record[k1]['datemin'].nil?
      sorted_record[k1]['daterange'] = '' if sorted_record[k1]['daterange'].nil?
      sorted_record[k1]['last_amended'] = '' if sorted_record[k1]['last_amended'].nil?
      sorted_record[k1]['location'] = '' if sorted_record[k1]['location'].nil?
      sorted_record[k1]['place_name'] = '' if sorted_record[k1]['place_id'].nil?
      sorted_record[k1]['chapman_code'] = '' if sorted_record[k1]['place_id'].nil?
      sorted_record[k1]['records'] = '' if sorted_record[k1]['records'].nil?
      sorted_record[k1]['transcribers'] = '' if sorted_record[k1]['transcribers'].nil?
      sorted_record[k1]['website'] = '' if sorted_record[k1]['website'].nil?
    end

    csv_string = ['id','chapman_code','church_name','church_notes','contributors','datemax','datemin','daterange','last_amended','location','place_id','place_name','records','transcribers','website'].to_csv
    output_file.puts csv_string

    sorted_record.each do |k1,v1|
      record_str = Array.new
      v1.each { |k2,v2| record_str << v2 if not ['c_at','u_at'].include? k2 }

      csv_string = record_str.to_csv
      output_file.puts csv_string
    end
    output_file.close 
  end
end
