task :extract_name_populations,[:limit] => :environment do |t, args|
  file_for_messages = "log/name_populations.log" 
    message_file = File.new(file_for_messages, "w")
  	limit = args.limit.to_i
    puts "Producing report of the population of names"
    message_file.puts "Field,Surname/Forename/County,Distinct sur/forenames,Num of surname entries,All fore/surname indexes, Match fore/surname indexes, Distint Counies, Total Counties\n"
    record_number = 0
    total_index_and_entries = 0
    total_index_entries = 0
    total_number_surnames = 0
    total_number_counties = 0
    total_distinct_counties = 0
    surnames = SearchRecord.collection.aggregate([{ '$group' => {"_id" => "$search_names.last_name" }}])
    reduced_surnames = Array.new
    sur = Array.new
    surnames.each do |surname|
      sur = surname["_id"].uniq unless surname["_id"].nil?
      sur.each do |name|
        reduced_surnames << name unless reduced_surnames.include?(name)
      end
    end
    puts "#{reduced_surnames.length} distinct surnames"
    reduced_surnames.each do |surname|
      break if record_number > limit
      puts "#{record_number}" if (record_number/1000)*1000 == record_number
      record_number = record_number + 1
      number_surname = SearchRecord.where({"search_names.last_name": surname}).count
      forenames = SearchRecord.where({"search_names.last_name": surname}).distinct("search_names.first_name")
      counties = SearchRecord.where({"search_names.last_name": surname}).distinct("chapman_code")
      counties.present? ? distinct_counties = counties.length : distinct_counties = 0
      total_distinct_counties = total_distinct_counties + distinct_counties
      forenames.present? ? distinct_forenames = forenames.length : distinct_forenames = 0
      county_entries = 0
      counties.each do |county|
        number_counties = SearchRecord.where({"chapman_code": county,"search_names.last_name": surname }).count
        message_file.puts "Surname-county,#{surname}-#{county},#{distinct_counties},,#{number_counties}"
        county_entries = county_entries + number_counties
        total_number_counties = total_number_counties + number_counties
      end
      total_number_surnames = total_number_surnames + number_surname
      index_entries = 0
      index_and_entries = 0 
      forenames.each do |forename|
        number_and_forename = SearchRecord.collection.find({"search_names":{"$elemMatch":{"last_name": surname,"first_name": forename}}}).count
        index_and_entries =  index_and_entries + number_and_forename
        number_forename = SearchRecord.where({"search_names.last_name": surname,"search_names.first_name": forename}).count
        index_entries = index_entries + number_forename
        total_index_entries = total_index_entries + number_forename
        total_index_and_entries = total_index_and_entries + number_and_forename
        message_file.puts "Surname-forename,#{surname}-#{forename},,,#{number_forename},#{number_and_forename}"
      end
      message_file.puts "Surname,#{surname},#{distinct_forenames},#{number_surname},#{index_entries},#{index_and_entries}, #{distinct_counties},#{county_entries}"
    end
    message_file.puts "Total,Total,#{record_number},#{total_number_surnames},#{total_index_entries},#{total_index_and_entries},#{total_distinct_counties},#{total_number_counties}" 
  end
