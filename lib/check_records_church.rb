class CheckRecordsChurch

  def self.process(chapmancode)
    file_for_output = "#{Rails.root}/log/church_records.csv"
    FileUtils.mkdir_p(File.dirname(file_for_output) )
    output_file = File.new(file_for_output, "w")
  	
    id = 0
    h = Hash.new
    place = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
    record = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
    sorted_record = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
  	
  	puts "========Get Church records"

    chapman_code = chapmancode == 'ALL' ? nil : chapmancode
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

        alt_church_names = ''
        if k == 'alternatechurchnames' && !record[id][k].empty?
          record[id][k].each do |v|
            alt_church_names += ', ' if !alt_church_names.empty?
            alt_church_names += v['alternate_name'].to_s
          end
          record[id]['alternate_church_names'] = alt_church_names
          alt_church_names = ''
        end

        record[id]['alternate_church_name'] = record[id]['alternatechurchname']['alternate_name'] if k == 'alternatechurchname' && !record[id][k].empty?

        if k == 'transcribers' || k == 'contributors'
          record[id][k].delete('total') if record[id][k].key?('total')
        end
      end

      if record[id]['place_id'].present? && (chapman_code.nil? || place[record[id]['place_id']]['chapman_code'] == chapman_code)
          record[id]['place_name'] = place[record[id]['place_id']]['place_name']
          record[id]['chapman_code'] = place[record[id]['place_id']]['chapman_code']
      else
        record.delete(id)
      end
    end

    record.each do |k1,v1|
      record[k1]['alternate_church_name'] = '' if not record[k1].key?('alternate_church_name')
      record[k1]['alternate_church_names'] = '' if not record[k1].key?('alternate_church_names')
      record[k1]['chapman_code'] = '' if not record[k1].key?('place_id')
      record[k1]['church_name'] = '' if not record[k1].key?('church_name')
      record[k1]['church_notes'] = '' if not record[k1].key?('church_notes')
      record[k1]['contributors'] = '' if not record[k1].key?('contributors')
      record[k1]['datemax'] = '' if not record[k1].key?('datemax')
      record[k1]['datemin'] = '' if not record[k1].key?('datemin')
      record[k1]['daterange'] = '' if not record[k1].key?('daterange')
      record[k1]['denomination'] = '' if not record[k1].key?('denomination')
      record[k1]['last_amended'] = '' if not record[k1].key?('last_amended')
      record[k1]['location'] = '' if not record[k1].key?('location')
      record[k1]['place_name'] = '' if not record[k1].key?('place_id')
      record[k1]['records'] = '' if  not record[k1].key?('records')
      record[k1]['transcribers'] = '' if not record[k1].key?('transcribers')
      record[k1]['website'] = '' if not record[k1].key?('website')
      record[k1].delete('alternatechurchnames')
      record[k1].delete('alternatechurchname')
      record[k1].delete('daterange')
      record[k1].delete('place_id')
      record[k1].delete('u_at')
      record[k1].delete('c_at')
    end

    sorted_record = record.inject({}) do |h, (k, v)|
      h[k] = Hash[v.sort_by {|k1,v1| k1}]
      h
    end

    csv_string = ['id','chapman_code','place_name', 'official_church_name','alt_church_name','alt_church_names','denomination','website','records','last_amended','datemin','datemax','church_notes','transcribers','contributors','location'].to_csv
    output_file.puts csv_string

    sorted_record.each do |k1,v1|
      record_str = Array.new

      record_str << k1
      record_str << v1['chapman_code']
      record_str << v1['place_name']
      record_str << v1['church_name']
      record_str << v1['alternate_church_name']
      record_str << v1['alternate_church_names']
      record_str << v1['denomination']
      record_str << v1['website']
      record_str << v1['records']
      record_str << v1['last_amended']
      record_str << v1['datemin']
      record_str << v1['datemax']
      record_str << v1['church_notes']
      record_str << v1['transcribers']
      record_str << v1['contributors']
      record_str << v1['location']

      csv_string = record_str.to_csv
      output_file.puts csv_string
    end
    output_file.close 
  end
end
