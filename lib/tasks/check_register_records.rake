namespace :check_register_records do

  desc "Export Church entries into excel"
  task :check_register, [:chapman_code] => :environment do |t, args|

  	file_for_output = "#{Rails.root}/log/register_records.csv"
    FileUtils.mkdir_p(File.dirname(file_for_output) )
    output_file = File.new(file_for_output, "w")
  	
    id = 0
    record = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
  	
  	puts "========Get Register records"

    chapman_code = args.chapman_code == 'ALL' ? nil : args.chapman_code
  	registers = Register.all

    registers.each do |entry|
      entry.attributes.each do |k,v|
        if k == '_id'
          record[v] = Hash.new if record[k].nil?
          id = v
        end
      end

      entry.attributes.each do |k,v| 
        if ['_id', 'place_id', 'register_notes'].include? k
          record[id][k] = v.to_s.gsub("\r\n", "")
        else
          record[id][k] = v
        end

        if k == 'transcribers' || k == 'contributors'
          record[id][k].delete('total') if record[id][k].key?('total')
        end
      end

      if !chapman_code.nil? && record[id]['chapman_code'] != chapman_code
        record.delete(id)
      end
    end

    record.each do |k1,v1|
      record[k1]['alternate_register_name'] = '' if not record[k1].key?('alternate_register_name')
      record[k1]['church_id'] = '' if not record[k1].key?('church_id')
      record[k1]['church_names'] = '' if not record[k1].key?('church_names')
      record[k1]['contributors'] = '' if not record[k1].key?('contributors')
      record[k1]['copyright'] = '' if not record[k1].key?('copyright')
      record[k1]['credit'] = '' if not record[k1].key?('credit')
      record[k1]['credit_from_files'] = '' if not record[k1].key?('credit_from_files')
      record[k1]['datemax'] = '' if not record[k1].key?('datemax')
      record[k1]['datemin'] = '' if not record[k1].key?('datemin')
      record[k1]['daterange'] = '' if not record[k1].key?('daterange')
      record[k1]['minimum_year_for_register'] = '' if not record[k1].key?('minimum_year_for_register')
      record[k1]['maximum_year_for_register'] = '' if not record[k1].key?('maximum_year_for_register')
      record[k1]['place_name'] = '' if not record[k1].key?('place_name')
      record[k1]['quality'] = '' if not record[k1].key?('quality')
      record[k1]['record_type'] = '' if not record[k1].key?('record_type')
      record[k1]['register_name'] = '' if not record[k1].key?('register_name')
      record[k1]['register_notes'] = '' if not record[k1].key?('register_notes')
      record[k1]['register_type'] = '' if not record[k1].key?('register_type')
      record[k1]['records'] = '' if not record[k1].key?('records')
      record[k1]['source'] = '' if not record[k1].key?('source')
      record[k1]['status'] = '' if not record[k1].key?('status')
      record[k1]['transcribers'] = '' if not record[k1].key?('transcribers')
   end

    sorted_record = record.inject({}) do |h, (k, v)|
      h[k] = Hash[v.sort_by {|k1,v1| k1}]
      h
    end

    csv_string = ['id','status','register_name','alternate_register_name','register_type','quality','source','copyright','register_notes','credit','minimum_year_for_register','maximum_year_for_register','credit_from_files','records','last_amended','datemin','datemax','transcribers','contributors'].to_csv
    output_file.puts csv_string

    sorted_record.each do |k1,v1|
      record_str = Array.new

      record_str << k1
      record_str << v1['status']
      record_str << v1['register_name']
      record_str << v1['alternate_register_name']
      record_str << v1['register_type']
      record_str << v1['quality']
      record_str << v1['source']
      record_str << v1['copyright']
      record_str << v1['register_notes']
      record_str << v1['credit']
      record_str << v1['minimum_year_for_register']
      record_str << v1['maximum_year_for_register']
      record_str << v1['credit_from_files']
      record_str << v1['records']
      record_str << v1['last_amended']
      record_str << v1['datemin']
      record_str << v1['datemax']
      record_str << v1['transcribers']
      record_str << v1['contributors']

      csv_string = record_str.to_csv
      output_file.puts csv_string
    end
    output_file.close 
  end
end
