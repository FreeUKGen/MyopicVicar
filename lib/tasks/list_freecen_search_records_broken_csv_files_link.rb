desc "List FreeCEN Search_record Ids where the link to freecen_csv_files is broken"
task :list_freecen_search_records_broken_csv_files_link, [:batch_size, :user_for_email, :start_after] => :environment do |_t, args|

  require 'user_mailer'

  def self.output_to_log(message_file, message)
    message_file.puts message.to_s
  end

  def self.output_to_txt(txt_file, line)
    txt_file.puts line.to_s
  end

  def self.write_txt_line(search_record_id, recno)

    if recno == 1
      @file_for_listing = 'log/freecen_search_records_broken_csv_files_link.txt'
      FileUtils.mkdir_p(File.dirname(@file_for_listing)) unless File.exist?(@file_for_listing)
      @file_for_listing = File.new(@file_for_listing, 'w')
    end

    dline = ''
    dline << "#{id}"
    output_to_txt(@file_for_listing, dline)
    @report_txt += "\n"
    @report_txt += dline
  end

  # START

  @start_time = Time.current
  @file_date = Time.current.strftime('%Y%m%d%H%M')
  broken_rec_count = 0
  @report_txt = ''
  @first_line = true

  file_for_log = "log/freecen_search_records_broken_csv_files_link_#{@file_date}.log"
  FileUtils.mkdir_p(File.dirname(file_for_log)) unless File.exist?(file_for_log)
  file_for_log = File.new(file_for_log, 'w')

  # Check arguments

  @batch_size = args.batch_size.to_i
  abort 'Invalid Batch size argumant. Must be a positive integer' if @batch_size <= 0
  email_userid = args.user_for_email
  @user_email = UseridDetail.where(userid: email_userid).first
  abort 'Invalid user for email argumant. User not found' unless @user_email
  @email_address =  @user_email.email_address
  @start_after_id = nil
  @start_after_id = args_start_after if arges_start_after.present?

  initial_message = "List FreeCEN Search_record Ids where the link to freecen_csv_files is broken : Limit = #{args.limit}, User for email = #{args.user_for_email}, Start Id = #{@start_after_id} at #{start_time}"
  output_to_log(file_for_log, initial_message)
  p initial_message

  last_id = BSON::ObjectId(@start_after_id) rescue nil
  @broken_ids = []

  # Main process Loop

  loop do
    query = last_id ? SearchRecord.where(:_id.gt => last_id) : SearchRecord.all
    batch = query.order_by(_id: 1).limit(batch_size).to_a
    break if batch.empty?

    freecen_csv_file_ids = batch.map(&:freecen_csv_file_id).compact.uniq
    existing_ids = FreecenCsvFile.where(:id.in => freecen_csv_file_ids).pluck(:id).to_set

    batch.each do |search_rec|
      broken_ids << search_rec.id unless existing_ids.include?(search_rec.freecen_csv_file_id)
    end

    @last_id = search_recs.last.id
    end_time = Time.current
    run_time = end_time - @start_time
    @final_message = "Last processed ID: #{@last_id}, Run Time = #{run_time}" # Save this to resume later
    output_to_log(file_for_log, final_message)
    p final_message
  end

  txt_file_message = "Writing ids of ophaned search_records to #{@file_for_listing}"
  output_to_log(file_for_log, txt_file_message)

  broken_rec_count = broken_ids.size
  recno = 0
  broken_ids.each do |id|
    recno += 1
    write_txt_line(id, recno)
  end

  email_message = "Sending csv file via email to #{email_userid}"
  output_to_log(file_for_log, email_message)

  email_subject = 'FREECEN:: List FreeCEN Search_record Ids where the link to freecen_csv_files is broken.'
  email_body += "Limit = #{@limit} "
  email_body += "\n"
  email_body += "#{broken_rec_count} orphaned Search Records found"
  email_body += "\n"
  if broken_rec_count.positive?
    email_body += "See file #{@file_for_listing} for List."
    email_body += "\n"
  end
  email_body += @final_message
  email_body += "\n"
  UserMailer.report_for_syndicate_coord(email_subject, email_body, @report_csv, report_name, email_to, cc_email_to).deliver_now
end
