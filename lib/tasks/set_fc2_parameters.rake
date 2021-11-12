desc "set_fc2 parameter linkgaes for VLD files, dwelling, individuals and search records"
task :set_fc2_parameters, [:start, :finish, :search_records] => [:environment] do |t, args|
  require 'create_search_records_freecen2'

  file_for_messages = File.join(Rails.root, 'log/create fc2 parameter linkages.log')
  message_file = File.new(file_for_messages, 'w')
  start = args.start.to_i
  finish = args.finish.to_i
  search_record_creation = args.search_records.present? ? true : false
  p "Finish #{finish} must be greater than start #{start}" if start > finish
  crash if start > finish

  p "Producing report of creation of fc2 parameter linkages from VLDs starting at #{start} and an end of #{finish} with search record creation #{search_record_creation}"
  message_file.puts "Producing report of creation of fc2 parameter linkages from VLDs starting at #{start} and an end of #{finish} with search record creation #{search_record_creation}"
  @number = start - 1
  time_start = Time.now
  vld_files = Freecen1VldFile.all.order_by(_id: 1).pluck(:_id).compact
  max_files = vld_files.length
  finish = max_files if finish > max_files
  num = 0
  vld_files.each do |file|
    message_file.puts "File number #{num}, #{file}"
    num += 1
  end

  while @number < finish
    @number += 1
    p "#{@number} at #{Time.now}"
    file = vld_files[@number]
    skip, place, freecen2_place = CreateSearchRecordsFreecen2.setup(file, @number, message_file)
    next if skip

    CreateSearchRecordsFreecen2.process(file, freecen2_place) if search_record_creation
  end
  p 'refreshing place cache'
  Freecen2PlaceCache.refresh_all

  time_end = Time.now
  finished = finish - start + 1
  seconds = (time_end - time_start).to_i
  average = seconds / finished
  p "Finished #{finished} files in #{seconds} second; average rate #{average}"
end
