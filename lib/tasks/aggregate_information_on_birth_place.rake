task :aggregate_information_on_birth_place, [:limit] => [:environment] do |t, args|
  file_for_warning_messages = "#{Rails.root}/log/birth_places.csv"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  output_file = File.new(file_for_warning_messages, "w")
  start = Time.now
  output_file.puts 'chapman,birth county,birth place,verbatim birth county, verbatim birth place,location'
  record_number = 0
  found = 0

  process = { '$match': { 'verbatim_birth_place': { '$ne': '-' } } }

  group = { '$group': { '_id': '$verbatim_birth_place', 'number': { '$sum': 1 } } }

  sort = { '$sort':   { 'number': -1 } }
  p 'Verbatim'

  FreecenIndividual.collection.aggregate([process, group, sort], { allowDiskUse: true }).each do |distinct|
    record_number += 1
    break if record_number == args.limit.to_i

    p distinct
  end
  p 'Birth'
  record_number = 0
  found = 0
  process = { '$match': { 'birth_place': { '$ne': '-' } } }

  group = { '$group': { '_id': '$birth_place', 'number': { '$sum': 1 } } }
  FreecenIndividual.collection.aggregate([process, group, sort], { allowDiskUse: true }).each do |distinct|
    record_number += 1
    break if record_number == args.limit.to_i

    p distinct
  end


  elapse = Time.now - start
  p "#{record_number} processed in #{elapse} seconds with #{found} located"
  p "finished"
end
