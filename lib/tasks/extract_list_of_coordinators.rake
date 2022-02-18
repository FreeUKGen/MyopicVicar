task :extract_list_of_coordinators, %i[group limit] => :environment do |_t, args|
  # lists either county or syndicate coordinators
  limit = args.limit.to_i
  coordinators = args.group.to_s
  file_for_messages = "log/list_of_coordinators_#{coordinators}.csv"
  message_file = File.new(file_for_messages, 'w')
  puts "Producing report of the population of #{coordinators} coordinators"

  record_number = 0
  case coordinators
  when 'syndicate'
    message_file.puts 'Code, Coordinator Userid, Description, Previous Coordinator, Notes, Accepting Volunteers'
    Syndicate.order_by(syndicate_code: 1).each do |syndicate|
      message_file.puts "#{syndicate.syndicate_code},#{syndicate.syndicate_coordinator},#{syndicate.syndicate_description},#{syndicate.previous_syndicate_coordinator},#{syndicate.syndicate_notes},#{syndicate.accepting_transcribers}"
      record_number += 1
      break if record_number >= limit
    end
  when 'county'
    message_file.puts 'Code, Coordinator Userid, Description, Previous Coordinator, Notes '
    County.order_by(chapman_code: 1).each do |county|
      message_file.puts "#{county.chapman_code},#{county.county_coordinator},#{county.county_description},#{county.previous_county_coordinator},#{county.county_notes}"
      record_number += 1
      break if record_number >= limit
    end
  end
end
