class CheckRecordsSearchRecord

  def self.process
  	file_for_empty_entry_id = "#{Rails.root}/log/search_record_records1.csv"
    FileUtils.mkdir_p(File.dirname(file_for_empty_entry_id) )
    empty_entry_id_file = File.new(file_for_empty_entry_id, "w")
  	
    id = 0
    record = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
    sorted_record = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
  	
  	puts "========Get empty freereg1_csv_entry_id SearchRecord records"

    search_records = SearchRecord.all

    search_records.each do |entry|
      entry.attributes.each do |k,v|
        if k == '_id'
          record[v] = Hash.new if record[k].nil?
          id = v
        end
      end

      entry.attributes.each do |k,v| 
        record[id][k] = v
     end
    end

    record.each do |k1,v1|
      record[k1]['filed_id'] = '' if not record[k1].key?('field_id')
      record[k1]['location'] = '' if not record[k1].key?('location')
      record.delete(k1) if record[k1].key?('freereg1_csv_entry_id')
    end

    sorted_record = record.inject({}) do |h, (k, v)|
      h[k] = Hash[v.sort_by {|k1,v1| k1}]
      h
    end

    csv_string = ['id','field_id','location'].to_csv
    empty_entry_id_file.puts csv_string

    sorted_record.each do |k1,v1|
      record_str = Array.new

      record_str << k1
      record_str << v1['field_id']
      record_str << v1['location']

      csv_string = record_str.to_csv
      empty_entry_id_file.puts csv_string
    end
    empty_entry_id_file.close 



    file_for_empty_place_id = "#{Rails.root}/log/search_record_records2.csv"
    FileUtils.mkdir_p(File.dirname(file_for_empty_place_id) )
    empty_place_id_file = File.new(file_for_empty_place_id, "w")
    
    puts "========Get empty place_id SearchRecord records"

    search_records = SearchRecord.all

    search_records.each do |entry|
      entry.attributes.each do |k,v|
        if k == '_id'
          record[v] = Hash.new if record[k].nil?
          id = v
        end
      end

      entry.attributes.each do |k,v| 
       record[id][k] = v
     end
    end

    record.each do |k1,v1|
      record[k1]['filed_id'] = '' if not record[k1].key?('field_id')
      record[k1]['location'] = '' if not record[k1].key?('location')
      record.delete(k1)  if record[k1].key?('place_id')
    end

    sorted_record = record.inject({}) do |h, (k, v)|
      h[k] = Hash[v.sort_by {|k1,v1| k1}]
      h
    end

    csv_string = ['id','field_id','location'].to_csv
    empty_place_id_file.puts csv_string

    sorted_record.each do |k1,v1|
      record_str = Array.new

      record_str << k1
      record_str << v1['field_id']
      record_str << v1['location']

      csv_string = record_str.to_csv
      empty_place_id_file.puts csv_string
    end
    empty_place_id_file.close 
  end
end

