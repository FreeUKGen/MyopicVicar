task :extract_name_populations,[:limit] => :environment do |t, args|
  file_for_messages = "log/name_populations.log" 
    message_file = File.new(file_for_messages, "w")
  	limit = args.limit.to_i
    puts "Producing report of the population of names"
    message_file.puts "Field,Surname/Forename,Distinct surnames,Num of surname entries,All fore/surname indexes, Match fore/surname indexes\n"
    record_number = 0
    total_index_and_entries = 0
    total_index_entries = 0
    total_number_surnames = 0
    surnames = SearchRecord.all.distinct("search_names.last_name")
    puts "#{surnames.length} distinct surnames"
    surnames.each do |surname|
      break if record_number > limit
      puts "#{record_number}" if (record_number/1000)*1000 == record_number
      record_number = record_number + 1
      number_surname = SearchRecord.where({"search_names.last_name": surname}).count
      forenames = SearchRecord.where({"search_names.last_name": surname}).distinct("search_names.first_name")
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
      message_file.puts "Surname,#{surname},,#{number_surname},#{index_entries},#{index_and_entries}"
    end
    message_file.puts "Total,Total,#{record_number},#{total_number_surnames},#{total_index_entries},#{total_index_and_entries}" 
  end
