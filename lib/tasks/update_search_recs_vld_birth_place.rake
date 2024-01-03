desc 'Update Search records to populate birth_place from the vld entry rec as the Monthly vld load did not do this but the manual VLD upload VLD did'
task :update_search_recs_vld_birth_place, [:county, :limit, :fix, :email] => :environment do |t, args|
  require 'user_mailer'

  def self.output_to_log(message_file, message)
    message_file.puts message.to_s
    if @send_email
      @report_log += "\n"
      @report_log += message
    end
    p message.to_s
  end

  # START

  start_time = Time.current
  @send_email = args.email.to_s == 'N' ? false : true
  @email_to = args.email.to_s if @send_email == true
  args.with_defaults(:limit => 1000)

  file_for_log = "log/update_search_recs_vld_birth_place_#{start_time.strftime('%Y%m%d%H%M')}.log"
  FileUtils.mkdir_p(File.dirname(file_for_log)) unless File.exist?(file_for_log)
  file_for_log = File.new(file_for_log, 'w')
  county = args.county.to_s
  @rec_limit = args.limit.to_i
  fixit = args.fix.to_s == 'Y'
  @report_log = ''

  initial_message = "Started Update Search records with birth_place from the vld entry rec - County = #{county} - fix = #{fixit} - record limit = #{@rec_limit}"
  start_message = initial_message
  output_to_log(file_for_log, start_message)
  length_start_message = start_message.length
  recs_processed = 0

  SearchRecord.where(chapman_code: county, freecen_csv_file_id: { '$eq' => nil }, freecen1_vld_file_id: { '$eq' => nil }, birth_place: { '$eq' => nil }).order_by(_id: 1).each do |search_rec|

    individual_rec = FreecenIndividual.find_by(_id: search_rec.freecen_individual_id)
    next if individual_rec.blank?

    birth_place = individual_rec.birth_place.presence || individual_rec.verbatim_birth_place
    search_rec.set(birth_place: birth_place) if fixit
    unless fixit
      output_to_log(file_for_log, "Search rec #{search_rec._id} - Search rec birth_place #{search_rec.birth_place} will update to #{birth_place}")
    end
    recs_processed += 1
    break if recs_processed >= @rec_limit

  end
  output_to_log(file_for_log, "Processed #{recs_processed} records")

  end_time = Time.current
  run_time = end_time - start_time

  message = "Finished Update Search records with birth_place from the vld entry rec - County = #{county} - fix = #{fixit}  - rec limit = #{@rec_limit} - run time = #{run_time}"
  output_to_log(file_for_log, message)
  p "Processed #{total_recs_processed} VLD Entry records - see log/update_search_recs_vld_birth_place_YYYYMMDDHHMM.log for output"

  if @send_email
    user_rec = UseridDetail.userid(@email_to).first
    p "Sending email to #{user_rec.email_address}"
    subject_line_length = length_start_message - 8
    email_subject = "FREECEN:: #{start_message[8, subject_line_length]}"
    email_body = "Processed #{total_recs_processed} records"
    report_name = "update_search_recs_vld_birth_place_#{county}_#{start_time.strftime('%Y%m%d%H%M')}.log"
    UserMailer.report_for_data_manager(email_subject, email_body, @report_log, report_name, user_rec.email_address).deliver_now
  end

  # end task
end
