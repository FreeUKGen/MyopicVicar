desc 'Check length of freereg processor queue and report if greater than limit'
task :check_length_processor_queue, %i[limit] => :environment do |_t, args|
  limit = args.limit.to_i
  file_for_messages = Rails.root.join('log/processor_queue_length.log')
  message_file = File.new(file_for_messages, 'a')
  batches = PhysicalFile.waiting.all.order_by(waiting_date: -1).length
  message_file.puts "Queue length #{batches} at #{Time.now.utc.strftime('%c')}"
  if batches >= limit
    message_file.puts "Reporting length of #{limit}"
    UserMailer.report_processor_limit_exceeded(batches, limit).deliver_now
  end
  message_file.close
end
