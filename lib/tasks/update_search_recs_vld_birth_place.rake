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
  @file_limit = args.limit.to_i
  fixit = args.fix.to_s == 'Y'
  @report_log = ''

  initial_message = "Started Update Search records with birth_place from the vld entry rec - County = #{county} - fix = #{fixit} - vld file limit = #{@file_limit}"
  start_message = initial_message
  output_to_log(file_for_log, start_message)
  length_start_message = start_message.length
  recs_processed = 0
  vld_files_processed = 0
  total_recs_processed = 0
  @vld_file_name = 'xxxx'

  SearchRecord.where(chapman_code: county, freecen1_vld_file_id: { '$ne' => nil }, birth_place: { '$eq' => nil }).order_by(freecen1_vld_file_id: 1).each do |search_rec|

    vld_file_rec = Freecen1VldFile.find_by(_id: search_rec.freecen1_vld_file_id)
    if vld_file_rec.file_name != @vld_file_name
      output_to_log(file_for_log, "Processed #{recs_processed} records") if @vld_file_name != 'xxxx'
      recs_processed = 0
      vld_files_processed += 1
      break if vld_files_processed > @file_limit

      @vld_file_name = vld_file_rec.file_name
      output_to_log(file_for_log, "Processing VLD file #{vld_file_rec.file_name}")
    end

    individual_rec = FreecenIndividual.find_by(_id: search_rec.freecen_individual_id)
    next if individual_rec.blank?

    birth_place = individual_rec.birth_place.presence || individual_rec.verbatim_birth_place
    search_rec.set(birth_place: birth_place) if fixit
    recs_processed += 1
    total_recs_processed += 1

  end
  output_to_log(file_for_log, "Processed #{recs_processed} records") if @vld_file_name != 'xxxx' && vld_files_processed <= @file_limit
  output_to_log(file_for_log, "Total records processed #{total_recs_processed}")

  end_time = Time.current
  run_time = end_time - start_time

  message = "Finished Update Search records with birth_place from the vld entry rec - County = #{county} - fix = #{fixit}  - vld file limit = #{@file_limit} - run time = #{run_time}"
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
