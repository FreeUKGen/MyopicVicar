desc "set_fc2 parameter linkgaes for VLD files, dwelling, individuals and search records"
task :set_fc2_paramters, [:start, :finish] => [:environment] do |t, args|
  file_for_messages = File.join(Rails.root, 'log/create fc2 parameter linkages')
  message_file = File.new(file_for_messages, 'w')
  start = args.start.to_i
  finish = args.finish.to_i
  p "Producing report of creation of fc2 paramter linkages from VLDs starting at #{start} and an end of #{finish}"
  message_file.puts "Producing report of creation of fc2 paramter linkages from VLDs starting at #{start} and an end of #{finish}"
  @number = start - 1
  time_start = Time.now
  vld_files = Freecen1VldFile.all.order_by(_id: 1)

  while @number <= finish
    @number += 1
    p @number
    file = vld_files[@number]
    p file
    next if file[:freecen2_distict].present?

  end
  time_end = Time.now
  finished = start - @number
  seconds = (time_end - time_start).to_i
  p "Finished #{finished} files in #{seconds}"

end
