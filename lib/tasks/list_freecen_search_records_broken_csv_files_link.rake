desc "List FreeCEN Search record Ids where the link to freecen_csv_files is broken"
task :list_freecen_search_records_broken_csv_files_link, [:batch_size, :limit, :user_for_email, :start_after] => :environment do |_t, args|
  require 'user_mailer'

  start_time = Time.current
  file_date = Time.current.strftime('%Y%m%d%H%M')
  processed = 0

  file_for_log = "#{Rails.root}/log/freecen_search_records_broken_csv_files_link_#{file_date}.log"
  FileUtils.mkdir_p(File.dirname(file_for_log))
  log_file = File.new(file_for_log, 'w')

  file_for_txt = "#{Rails.root}/log/freecen_search_records_broken_csv_files_link.txt"
  FileUtils.mkdir_p(File.dirname(file_for_txt))
  @txt_file = File.open(file_for_txt, 'a')

  # Check arguments

  batch_size = args.batch_size.to_i
  abort 'Invalid Batch size argument. Must be a positive integer' if batch_size <= 0
  limit = args.limit.to_i
  abort 'Invalid Limit argument. Must be a positive integer' if limit <= 0
  email_userid = args.user_for_email
  user_email = UseridDetail.where(userid: email_userid).first
  abort 'Invalid user for email argument. User not found' unless user_email
  friendly_email = "#{user_email.person_forename} #{user_email.person_surname} <#{user_email.email_address}>"
  start_after_id = nil
  start_after_id = args.start_after if args.start_after.present?

  message = "Listing FreeCEN Search_record Ids where the link to freecen_csv_files is broken : Batch size = #{batch_size} Limit = #{limit}, User for email = #{email_userid}, Start Id = #{start_after_id} at #{start_time}"
  log_file.puts message
  p message

  # Commented out as timeout issues on LIVE (although ran ok on TEST with a similar number of search_records) - AEV 17/06
  # search_recs_to_process = SearchRecord.where(:freecen_csv_file_id.ne => nil).count
  # message = "Total records with freecen_csv_file_id specified = #{search_recs_to_process}"
  # log_file.puts message
  # p message

  last_id = BSON::ObjectId(start_after_id) rescue nil
  broken_ids = []

  # Main process Loop

  loop do
    base_query = SearchRecord.where(:freecen_csv_file_id.ne => nil)
    query = last_id ? base_query.where(:_id.gt => last_id) : base_query
    batch = query.only(:_id, :freecen_csv_file_id).order_by(_id: 1).limit(batch_size).to_a
    break if batch.empty?

    freecen_csv_file_ids = batch.map(&:freecen_csv_file_id).uniq
    existing_ids = FreecenCsvFile.where(:id.in => freecen_csv_file_ids).pluck(:id).to_set

    batch_broken = batch.reject { |search_rec| existing_ids.include?(search_rec.freecen_csv_file_id) }.map(&:id)

    if batch_broken.any?
      batch_broken.each { |id| @txt_file.puts id.to_s }
      broken_ids.concat(batch_broken)
    end

    last_id = batch.last.id
    processed += batch.size

    message = "Last processed ID: #{last_id}"
    log_file.puts message
    p message

    message = "Processed so far: #{processed} | Broken so far #{broken_ids.size}"
    log_file.puts message
    p message

    break if limit && processed >= limit
  end

  message = "Sending csv file via email to #{email_userid}"
  log_file.puts message
  p message

  email_subject = 'FREECEN:: Listing FreeCEN Search record Ids where the link to freecen_csv_files is broken.'
  email_body = "Records to process limit = #{limit}."
  email_body += "\n"
  email_body += "#{broken_ids.size} orphaned Search records found."
  email_body += "\n"
  if broken_ids.size.positive?
    email_body += "See file #{file_for_txt} for list of Search record ids."
    email_body += "\n"
  end
  UserMailer.freecen_processing_report(friendly_email, email_subject, email_body).deliver

  end_time = Time.current
  run_time = end_time - start_time
  message = "Finished. Processed: #{processed} Search records. Last ID: #{last_id}, Run Time = #{run_time.round(2)} secs" # Save this to resume later
  log_file.puts message
  p message
end
