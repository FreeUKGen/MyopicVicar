namespace :check_church_records do

  desc "Export Church entries into excel"
  task :check_church, [:limit,:fix] => :environment do |t, args|

  	file_for_output = "#{Rails.root}/log/church_records.csv"
    FileUtils.mkdir_p(File.dirname(file_for_output) )
    output_file = File.new(file_for_output, "w")
  	
    id = 0
    h = Hash.new
    place = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
    record = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
    sorted_record = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
  	
  	puts "========Get Church records"

    places = Place.all
    places.each do |entry|
      place[entry.id.to_s]['chapman_code'] = entry.chapman_code
      place[entry.id.to_s]['place_name'] = entry.place_name
    end
  	
  	churches = Church.all
    churches.each do |entry|
      entry.attributes.each do |k,v|
        if k == '_id'
          record[v] = Hash.new if record[k].nil?
          id = v
        end
      end

      entry.attributes.each do |k,v| 
        if ['_id', 'place_id', 'church_notes'].include? k
          record[id][k] = v.to_s.gsub("\r\n", "")
        else
          record[id][k] = v
        end

        record[id]['alternate_church_name'] = record[id][k][0]['alternate_name'] if k == 'alternatechurchnames' && !record[id][k].empty?
      end

      if record[id]['place_id'].nil? || record[id]['place_id'].empty?
        record[id]['place_name'] = ''
        record[id]['chapman_code'] = ''
      else
        record[id]['place_name'] = place[record[id]['place_id']]['place_name']
        record[id]['chapman_code'] = place[record[id]['place_id']]['chapman_code']
      end
    end

    record.each do |k1,v1|
      record[k1]['alternate_church_name'] = '' if not record[k1].key?('alternate_church_name')
      record[k1]['alternatechurchname'] = '' if not record[k1].key?('alternatechurchname')
      record[k1]['chapman_code'] = '' if not record[k1].key?('place_id')
      record[k1]['church_name'] = '' if not record[k1].key?('church_name')
      record[k1]['church_notes'] = '' if not record[k1].key?('church_notes')
      record[k1]['contributors'] = '' if not record[k1].key?('contributors')
      record[k1]['datemax'] = '' if not record[k1].key?('datemax')
      record[k1]['datemin'] = '' if not record[k1].key?('datemin')
      record[k1]['daterange'] = '' if not record[k1].key?('daterange')
      record[k1]['denomination'] = '' if not record[k1].key?('denomination')
      record[k1]['last_amended'] = '' if not record[k1].key('last_amended')
      record[k1]['location'] = '' if not record[k1].key?('location')
      record[k1]['place_name'] = '' if not record[k1].key?('place_id')
      record[k1]['records'] = '' if  not record[k1].key?('records')
      record[k1]['transcribers'] = '' if not record[k1].key?('transcribers')
      record[k1]['website'] = '' if not record[k1].key?('website')
      record[k1].delete('alternatechurchnames')
    end

    sorted_record = record.inject({}) do |h, (k, v)|
      h[k] = Hash[v.sort_by {|k1,v1| k1}]
      h
    end

    csv_string = ['id','church_name','alternatechurchname','chapman_code','official_church_name','church_notes','contributors','datemax','datemin','daterange','denomination','last_amended','location','place_id','place_name','records','transcribers','website'].to_csv
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
