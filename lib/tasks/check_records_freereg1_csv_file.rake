namespace :check_records_freereg1_csv_file do

  desc "Export freereg1_csv_file_records into excel"
  task :check => :environment do |t, args|

  	file_for_output = "#{Rails.root}/log/freereg1_csv_file_records.csv"
    FileUtils.mkdir_p(File.dirname(file_for_output) )
    output_file = File.new(file_for_output, "w")

  	file_for_special = "#{Rails.root}/log/freereg1_csv_file_special_records.csv"
    FileUtils.mkdir_p(File.dirname(file_for_special) )
    special_file = File.new(file_for_special, "w")
  	
    id = 0
    place = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
    church = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
    register = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
    userid_detail_id = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
    record = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
  	
  	puts "========Get Freereg1CsvFile records"
    places = Place.all
    places.each do |entry|
      place[entry.id]['chapman_code'] = entry.chapman_code
      place[entry.id]['place_name'] = entry.place_name
    end
    
    churches = Church.all
    churches.each do |entry|
      church[entry.id]['church_name'] = entry.church_name
      church[entry.id]['place_name'] = place[entry.place_id]['place_name']
      church[entry.id]['chapman_code'] = place[entry.place_id]['chapman_code']
    end

    registers = Register.all
    registers.each do |entry|
      register[entry.id]['register_type'] = entry.register_type
      register[entry.id]['church_name'] = church[entry.church_id]['church_name']
      register[entry.id]['place_name'] = church[entry.church_id]['place_name']
      register[entry.id]['chapman_code'] = church[entry.church_id]['chapman_code']
    end

    userid_detail_ids = UseridDetail.all
    userid_detail_ids.each do |entry|
    	userid_detail_id[entry.id]['userid'] = entry.userid
    	userid_detail_id[entry.id]['userid_lower_case'] = entry.userid_lower_case
    end

		freereg1csvfiles = Freereg1CsvFile.all

		freereg1csvfiles.each do |entry|
      entry.attributes.each do |k,v|
        if k == '_id'
          record[v] = Hash.new if record[k].nil?
          id = v
        end
      end

      entry.attributes.each do |k,v| 
        record[id][k] = v
      end

      if record[id]['register_id'].present? 
        record[id]['chapman_code'] = register[record[id]['register_id']]['chapman_code']
        record[id]['place_name'] = register[record[id]['register_id']]['place_name']
        record[id]['church_name'] = register[record[id]['register_id']]['church_name']
        record[id]['register_type'] = register[record[id]['register_id']]['register_type']

        record[id]['church_id'] = register[record[id]['register_id']]['church_id']
        record[id]['place_id'] = register[record[id]['register_id']]['place_id']
      end

      if record[id]['userid_detail_id'].present?
      	record[id]['userid'] = userid_detail_id[record[id]['userid_detail_id']]['userid']
      	record[id]['userid_lower_case'] = userid_detail_id[record[id]['userid_detail_id']]['userid_lower_case']
      end
		end

    record.each do |k1,v1|
      record[k1]['chapman_code'] = '' if !record[k1].key?('chapman_code') || v1['chapman_code'].empty?
      record[k1]['place_name'] = '' if !record[k1].key?('place_name') || v1['place_name'].empty?
      record[k1]['church_name'] = '' if !record[k1].key?('church_name') || v1['church_name'].empty?
      record[k1]['register_type'] = '' if !record[k1].key?('register_type') || v1[k1]['register_type'].empty?
      record[k1]['file_name'] = '' if not record[k1].key?('file_name')
      record[k1]['userid'] = '' if !record[k1].key?('userid') || v1['userid'].empty?
      record[k1]['userid_lower_case'] = '' if !record[k1].key?('userid_lower_case') || v1['userid_lower_case'].empty?
      record[k1]['reocrd_type'] = '' if not record[k1].key?('reocrd_type')
      record[k1]['reocrds'] = '' if not record[k1].key?('records')
      record[k1]['datemin'] = '' if not record[k1].key?('datemin')
      record[k1]['datemax'] = '' if not record[k1].key?('datemax')
      record[k1]['daterange'] = '' if not record[k1].key?('daterange')
      record[k1]['transcriber_name'] = '' if not record[k1].key?('transcriber_name')
      record[k1]['transcriber_email'] = '' if not record[k1].key?('transcriber_email')
      record[k1]['transcriber_syndicate'] = '' if not record[k1].key?('transcriber_syndicate')
      record[k1]['credit_email'] = '' if not record[k1].key?('credit_email')
      record[k1]['credit_name'] = '' if not record[k1].key?('credit_name')
      record[k1]['first_comment'] = '' if not record[k1].key?('first_comment')
      record[k1]['second_comment'] = '' if not record[k1].key?('second_comment')
      record[k1]['transcription_date'] = '' if not record[k1].key?('transcription_date')
      record[k1]['modification_date'] = '' if not record[k1].key?('modification_date')
      record[k1]['uploaded_date'] = '' if not record[k1].key?('uploaded_date')
      record[k1]['error'] = '' if not record[k1].key?('error')
      record[k1]['digest'] = '' if not record[k1].key?('digest')
      record[k1]['locked_by_transcriber'] = '' if not record[k1].key?('locked_by_transcriber')
      record[k1]['locked_by_coordinator'] = '' if not record[k1].key?('locked_by_coordinator')
      record[k1]['lds'] = '' if not record[k1].key?('lds')
      record[k1]['characterset'] = '' if not record[k1].key?('characterset')
      record[k1]['alternate_register_name'] = '' if not record[k1].key?('alternate_register_name')
      record[k1]['csvfile'] = '' if not record[k1].key?('csvfile')
      record[k1]['processed'] = '' if not record[k1].key?('processed')
      record[k1]['processed_date'] = '' if not record[k1].key?('processed_date')
      record[k1]['def'] = '' if not record[k1].key?('def')
      record[k1]['software_version'] = '' if not record[k1].key?('software_version')
      record[k1]['search_record_version'] = '' if not record[k1].key?('search_record_version')
    end

    sorted_record = record.inject({}) do |h, (k, v)|
      h[k] = Hash[v.sort_by {|k1,v1| k1}]
      h
    end

    csv_string = ['id','chapman_code','place_name','church_name','register_type','file_name','userid','userid_lower_case','reocrd_type','reocrds','datemin','datemax','daterange','transcriber_name','transcriber_email','transcriber_syndicate','credit_email','credit_name','first_comment','second_comment','transcription_date','modification_date','uploaded_date','error','digest','locked_by_transcriber','locked_by_coordinator','lds','characterset','alternate_register_name','csvfile','processed','processed_date','def','software_version','search_record_version'].to_csv
    output_file.puts csv_string

    sorted_record.each do |k1,v1|
      record_str = Array.new

      record_str << k1
      record_str << v1['chapman_code']
      record_str << v1['place_name']
      record_str << v1['church_name']
      record_str << v1['register_type']
      record_str << v1['file_name']
      record_str << v1['userid']
      record_str << v1['userid_lower_case']
      record_str << v1['reocrd_type']
      record_str << v1['reocrds']
      record_str << v1['datemin']
      record_str << v1['datemax']
      record_str << v1['daterange']
      record_str << v1['transcriber_name']
      record_str << v1['transcriber_email']
      record_str << v1['transcriber_syndicate']
      record_str << v1['credit_email']
      record_str << v1['credit_name']
      record_str << v1['first_comment']
      record_str << v1['second_comment']
      record_str << v1['transcription_date']
      record_str << v1['modification_date']
      record_str << v1['uploaded_date']
      record_str << v1['error']
      record_str << v1['digest']
      record_str << v1['locked_by_transcriber']
      record_str << v1['locked_by_coordinator']
      record_str << v1['lds']
      record_str << v1['characterset']
      record_str << v1['alternate_register_name']
      record_str << v1['csvfile']
      record_str << v1['processed']
      record_str << v1['processed_date']
      record_str << v1['def']
      record_str << v1['software_version']
      record_str << v1['search_record_version']

      csv_string = record_str.to_csv
      output_file.puts csv_string
    end

    csv_string = ['id','file_name','userid','userid_lower_case','transcriber_name','credit_name'].to_csv
    special_file.puts csv_string

    sorted_record.each do |k1,v1|
      record_str = Array.new

      if (!v1['transcriber_name'].nil? && (v1['transcriber_name'].include? "@")) || (!v1['credit_name'].nil? && (v1['credit_name'].include? "@"))
	      record_str << k1
  	    record_str << v1['file_name']
    	  record_str << v1['userid']
      	record_str << v1['userid_lower_case']
	      record_str << v1['transcriber_name']
  	    record_str << v1['credit_name']

    	  csv_string = record_str.to_csv
      	special_file.puts csv_string
      end
    end
    output_file.close 
  end
end