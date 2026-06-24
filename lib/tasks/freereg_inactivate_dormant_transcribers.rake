namespace :freereg do
  desc "Inactivate FreeREG transcribers who have not uploaded a file in the past 6 months and have not set their password"
  task :inactivate_dormant_transcribers, [:mode, :email_user] => :environment do |_t, args|

    require 'user_mailer'
    require 'chapman_code'

    CUTOFF_MONTHS = 6

    def self.output_to_log(message_file, message)
      message_file.puts message.to_s
    end

    def self.output_to_csv(csv_file, line)
      csv_file.puts line.to_s
    end

    def self.write_csv_line(syndicate, userid, username, joined, last_upload, users_to_inactivate)
      if users_to_inactivate.zero?
        synd_text = syndicate.gsub(/[\s,]/, '_').gsub('__', '_')
        @file_for_listing = "log/Inactivate_dormant_transcribers_#{synd_text}_#{@file_date}.csv"
        FileUtils.mkdir_p(File.dirname(@file_for_listing)) unless File.exist?(@file_for_listing)
        @file_for_listing = File.new(@file_for_listing, 'w')
        hline = 'UserId,Username,Joined,LastUpload'
        output_to_csv(@file_for_listing, hline)
        @report_csv = hline
      end

      dline = "#{userid},#{username},#{joined},#{last_upload}"
      output_to_csv(@file_for_listing, dline)
      @report_csv += "\n#{dline}"
    end

    def self.send_email(file_for_log)
      cc_email_to = @cc_email
      email_to = @mode == 'PREVIEW' || @synd_coord_email.blank? ? @cc_email : @synd_coord_email
      output_to_log(file_for_log, "Sending csv report via email to #{email_to}")

      list_status = if @mode == 'UPDATE'
                      'These transcribers have been inactivated.'
                    else
                      'These transcribers will be inactivated when this process is next run in UPDATE mode.'
                    end

      email_subject = "FREEREG:: Inactivation of dormant transcribers in #{@syndicate} (run mode: #{@mode})."
      email_body = "We have reviewed transcribers in #{@syndicate} who have not uploaded a file in the last " \
                   "#{CUTOFF_MONTHS} months and have never signed in to the system.\n\n" \
                   "#{list_status}\n\n" \
                   "The attached file lists the affected transcribers. Please review this list and reactivate " \
                   "anyone who should remain active.\n"
      report_name = "Inactivate_dormant_transcribers_#{@syndicate}_#{@file_date}.csv"
      UserMailer.report_for_syndicate_coord(email_subject, email_body, @report_csv, report_name, email_to, cc_email_to).deliver_now
    end

    # START

    args.with_defaults(mode: 'PREVIEW')

    start_time = Time.current
    @file_date = Time.current.strftime('%Y%m%d%H%M')
    @report_csv = ''
    total_to_inactivate = 0
    total_inactivated = 0

    file_for_log = "log/Inactivate_dormant_transcribers_#{@file_date}.log"
    FileUtils.mkdir_p(File.dirname(file_for_log)) unless File.exist?(file_for_log)
    file_for_log = File.new(file_for_log, 'w')

    @mode = args.mode.upcase
    abort 'Invalid mode argument. Must be PREVIEW or UPDATE' unless %w[PREVIEW UPDATE].include?(@mode)

    bcc_userid = args.email_user
    @user_for_cc_email = UseridDetail.where(userid: bcc_userid).first
    abort 'Invalid email_user argument. Userid not found' unless @user_for_cc_email
    @cc_email = @user_for_cc_email.email_address

    @cutoff_date = CUTOFF_MONTHS.months.ago.to_date

    initial_message = "Started inactivation of dormant FreeREG transcribers: " \
                      "mode=#{@mode}, cutoff=#{@cutoff_date.strftime('%d/%m/%Y')}, " \
                      "email_user=#{bcc_userid}, started at #{start_time}"
    output_to_log(file_for_log, initial_message)
    p initial_message

    Syndicate.all.asc(:syndicate_code).each do |synd|
      next if synd.syndicate_code == 'Technical' || synd.syndicate_code == 'Any Questions Ask Us'

      @syndicate = synd.syndicate_code

      log_message = "Processing syndicate: #{@syndicate}"
      output_to_log(file_for_log, log_message)
      p log_message

      synd_coord = UseridDetail.where(userid: synd.syndicate_coordinator).first
      unless synd_coord
        output_to_log(file_for_log, "Coordinator not found for #{@syndicate} — skipping")
        next
      end

      @synd_coord_email = synd_coord.email_address

      active_transcribers = UseridDetail.where(
        syndicate: synd.syndicate_code,
        active: true,
        person_role: 'transcriber'
      ).order_by(userid_lower_case: 1)

      users_to_inactivate = 0

      active_transcribers.each do |user|
        # Condition 1: no FreeREG file uploaded within the cutoff window
        last_file = Freereg1CsvFile.where(userid: user.userid).desc(:uploaded_date).limit(1).first
        next if last_file.present? && last_file.uploaded_date.to_date >= @cutoff_date

        # Condition 2: has never signed in since tracking was enabled
        devise_user = User.where(username: user.userid).first
        next unless devise_user.present? && devise_user.last_sign_in_at.nil?

        user_full_name = "#{user.person_forename} #{user.person_surname}"
        joined = user.sign_up_date.present? ? user.sign_up_date.strftime('%d/%m/%Y') : 'Unknown'
        last_upload = last_file.nil? ? 'None' : last_file.uploaded_date.strftime('%d/%m/%Y')

        write_csv_line(@syndicate, user.userid, user_full_name, joined, last_upload, users_to_inactivate)
        users_to_inactivate += 1

        if @mode == 'UPDATE'
          user.update_attributes(
            active: false,
            disabled_date: Time.current,
            disabled_reason_standard: 'no-response'
          )
          total_inactivated += 1
        end
      end

      if users_to_inactivate.positive?
        send_email(file_for_log)
        log_message = @mode == 'UPDATE' ? "#{users_to_inactivate} transcribers were inactivated" : "#{users_to_inactivate} transcribers would be inactivated"
        output_to_log(file_for_log, log_message)
        p log_message
        total_to_inactivate += users_to_inactivate
      else
        log_message = 'Syndicate has no transcribers that meet inactivation criteria'
        output_to_log(file_for_log, log_message)
        p log_message
      end
    end

    log_message = @mode == 'UPDATE' ? "Total transcribers inactivated = #{total_inactivated}" : "Total transcribers that would be inactivated = #{total_to_inactivate}"
    output_to_log(file_for_log, log_message)
    p log_message

    run_time = Time.current - start_time
    log_message = "Runtime #{run_time}"
    output_to_log(file_for_log, log_message)
    p log_message
  end
end
