class CheckRecordsPlace

  def self.process(chapmancode)
  	file_for_output = "#{Rails.root}/log/place_records.csv"
    FileUtils.mkdir_p(File.dirname(file_for_output) )
    output_file = File.new(file_for_output, "w")
  	
    id = 0
    record = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
    sorted_record = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
  	
  	puts "========Get Place records"

    chapman_code = chapmancode == 'ALL' ? nil : args.chapman_code
    places = Place.where(:disabled=>false)

    places.each do |entry|
      entry.attributes.each do |k,v|
        if k == '_id'
          record[v] = Hash.new if record[k].nil?
          id = v
        end
      end

      entry.attributes.each do |k,v| 
        if ['place_notes','reason_for_change','other_reason_for_change','genuki_url'].include? k
          record[id][k] = v.to_s.gsub("\r\n", "")
          record[id][k] = record[id][k].to_s.gsub("\r\n", "")
        else
          record[id][k] = v
        end

        if k == 'transcribers' || k == 'contributors'
          record[id][k].delete('total') if record[id][k].key?('total')
        end

        record[id][k] = '' if k == 'alternate' && v == ' '
      end

      if !chapman_code.nil? && place[record[id]['place_id']]['chapman_code'] != chapman_code
        record.delete(id)
      end
    end

    record.each do |k1,v1|
      record[k1]['county'] = '' if not record[k1].key?('county')
      record[k1]['chapman_code'] = '' if not record[k1].key?('chapman_code')
      record[k1]['place_name'] = '' if not record[k1].key?('place_name')
      record[k1]['alternate_name'] = '' if not record[k1].key?('alternate_name')
      record[k1]['last_amended'] = '' if not record[k1].key?('last_amended')
      record[k1]['place_notes'] = '' if not record[k1].key?('place_notes')
      record[k1][':genuki_url'] = '' if not record[k1].key?(':genuki_url')
      record[k1]['location'] = '' if not record[k1].key?('location')
      record[k1]['grid_reference'] = '' if not record[k1].key?('grid_reference')
      record[k1][':latitude'] = '' if not record[k1].key?(':latitude')
      record[k1]['longitude'] = '' if not record[k1].key?('longitude')
      record[k1]['original_place_name'] = '' if  not record[k1].key?('original_place_name')
      record[k1]['original_county'] = '' if  not record[k1].key?('original_county')
      record[k1]['original_chapman_code'] = '' if  not record[k1].key?('original_chapman_code')
      record[k1]['original_country'] = '' if  not record[k1].key?('original_country')
      record[k1]['original_grid_reference'] = '' if  not record[k1].key?('original_grid_reference')
      record[k1]['original_latitude'] = '' if  not record[k1].key?('original_latitude')
      record[k1]['original_longitude'] = '' if  not record[k1].key?('original_longitude')
      record[k1]['original_source'] = '' if  not record[k1].key?('original_source')
      record[k1]['source'] = '' if  not record[k1].key?('source')
      record[k1]['reason_for_change'] = '' if  not record[k1].key?('reason_for_change')
      record[k1]['other_reason_for_change'] = '' if  not record[k1].key?('other_reason_for_change')
      record[k1]['modified_place_name'] = '' if  not record[k1].key?('modified_place_name')
      record[k1]['disabled'] = '' if  not record[k1].key?('disabled')
      record[k1]['error_flag'] = '' if  not record[k1].key?('error_flag')
      record[k1]['data_present'] = '' if  not record[k1].key?('data_present')
      record[k1]['alternate'] = '' if  not record[k1].key?('alternate')
      record[k1]['ucf_list'] = '' if  not record[k1].key?('ucf_list')
      record[k1]['records'] = '' if  not record[k1].key?('records')
      record[k1]['datemax'] = '' if not record[k1].key?('datemax')
      record[k1]['datemin'] = '' if not record[k1].key?('datemin')
      record[k1]['daterange'] = '' if not record[k1].key?('daterange')
      record[k1]['transcribers'] = '' if not record[k1].key?('transcribers')
      record[k1][':contributors'] = '' if not record[k1].key?(':contributors')
      record[k1].delete('u_at')
      record[k1].delete('c_at')
    end

    sorted_record = record.inject({}) do |h, (k, v)|
      h[k] = Hash[v.sort_by {|k1,v1| k1}]
      h
    end

    csv_string = ['id','county','chapman_code','place_name','alternate_name','last_amended','place_notes','genuki_url','location','grid_reference','latitude','longitude','original_place_name','original_county','original_chapman_code','original_country','original_grid_reference','original_latitude','original_longitude','original_source','source','reason_for_change','other_reason_for_change','modified_place_name','disabled','error_flag','data_present','alternate','ucf_list','records','datemin','datemax','daterange','transcribers','contributors'].to_csv
    output_file.puts csv_string

    sorted_record.each do |k1,v1|
      record_str = Array.new

      record_str << k1
      record_str << v1['county']
      record_str << v1['chapman_code']
      record_str << v1['place_name']
      record_str << v1['alternate_name']
      record_str << v1['last_amended']
      record_str << v1['place_notes']
      record_str << v1['genuki_url']
      record_str << v1['location']
      record_str << v1['grid_reference']
      record_str << v1['latitude']
      record_str << v1['longitude']
      record_str << v1['original_place_name']
      record_str << v1['original_county']
      record_str << v1['original_chapman_code']
      record_str << v1['original_country']
      record_str << v1['original_grid_reference']
      record_str << v1['original_latitude']
      record_str << v1['original_longitude']
      record_str << v1['original_source']
      record_str << v1['source']
      record_str << v1['reason_for_change']
      record_str << v1['other_reason_for_change']
      record_str << v1['modified_place_name']
      record_str << v1['disabled']
      record_str << v1['error_flag']
      record_str << v1['data_present']
      record_str << v1[':alternate']
      record_str << v1['ucf_list']
      record_str << v1['records']
      record_str << v1['datemin']
      record_str << v1['datemax']
      record_str << v1['daterange']
      record_str << v1['transcribers']
      record_str << v1['contributors']

      csv_string = record_str.to_csv
      output_file.puts csv_string
    end
    output_file.close 
  end
end
