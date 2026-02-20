desc "Deactivate active users who have not uploaded a CSV file since the specified  months"
task :deactivate_dormant_users [:mode, :months, :email_user] => :environment do |_t, args|

  require 'user_mailer'

  def self.output_to_log(message_file, message)
    message_file.puts message.to_s
    p message.to_s
  end

  def self.output_to_csv(csv_file, line)
    csv_file.puts line.to_s
  end

  def self.write_csv_line(csv_file, userid, username, joined, lastupload)
    dline = ''
    dline << "#{userid},"
    dline << "#{username},"
    dline << "#{joined},"
    dline << "#{lastupload},"
    output_to_csv(csv_file, dline)
    @report_csv += "\n"
    @report_csv += dline
  end

  # START

  args.with_defaults(:months => 48, :mode => "REVIEW")
  start_time = Time.current

  file_for_log = "log/Deactivate_dormant_users_#{start_time.strftime('%Y%m%d%H%M')}.log"
  FileUtils.mkdir_p(File.dirname(file_for_log)) unless File.exist?(file_for_log)
  file_for_log = File.new(file_for_log, 'w')

  # check arguments


  args_valid = args.mode.present? && %w[PREVIEW REVIEW UPDATE].include?(args.mode) ? true : false
  args_valid = false unless args.months.present? && args.months == /\A+?0*[1-9]\d*\Z/
  args_valid = false if args.email_user.blank?

  if args_valid == true

    user_for_cc_email = UseridDetails.find_by(userid: args.email_user)
    @cc_email = user_for_cc_email.present? ? user_for_cc_email.email_address : 'NOT FOUND'

    p "cc_email = #{@cc_email}"

    @months = arg.months.to_i
    @mode = args.mode
    @cutoff_date = start_time + @months.months

    p "cutoff date = #{@cutoff_date}"

    @roles_to_review = %w[transcriber validator checker]

    deactivated_users = 0

    initial_message = "Started deactivation of dormant users : Mode = #{args.mode}, Months = #{args.months}, Email = #{args.email_user} at #{start_time}"
    output_to_log(file_for_log, initial_message)

    syndicates_to_review = Syndicates.all.order_by(syndicate_code: 1)

    syndicates_to_review.each  do |synd|
      next if synd.syndicate_code == 'Technical' || synd.syndicate_code == 'Any Questions Ask Us'

      log_message = "Working on syndicate #{synd.syndicate_code}"
      output_to_log(file_for_log, log_message)
      p log_message

      synd_coord = synd.syndicate_coordinator
      @synd_coord_email = UseridDetails.find_by(userid: synd_coord)

      active_users = UseridDetails.where(:syndicate => synd.syndicate_code, :person_role => { '$in' => @roles_to_review }, :active => true)

      if active_users.blank?
        log_message = "Syndicate has no active users in roles #{@roles_to_review}"
        output_to_log(file_for_log, log_message)
        p log_message

      else

        users_to_deacivate = 0

        active_users.each do |user|

          next if user.sign_up_date > @cutoff_date

          most_recent_upload = FreecenCsvFiles.where(:userid => user.userid).order_by(uploaded_date: :desc).first

          if most_recent_upload.blank? || most_recent_upload < @cutoff_date

            if users_to_deacivate.zero?

              file_for_listing = "log/Deactivate_dormant_users_#{synd.syndicate_code}_#{start_time.strftime('%Y%m%d%H%M')}.csv"
              FileUtils.mkdir_p(File.dirname(file_for_listing)) unless File.exist?(file_for_listing)
              file_for_listing = File.new(file_for_listing, 'w')
              hline = 'UserId,Username,Joined,LastUpload'
              output_to_csv(file_for_listing, hline)
              @report_csv = hline

              users_to_deacivate += 1

            end

            user_name = user.forename + ' ' + user.surname
            joined = user.sign_up_date.strftime('%d/%m/%Y')
            last_upload = most_recent_upload.blank? ? 'None' : most_recent_upload.uploaded_date.strftime('%d/%m/%Y')

            write_csv_line(ile_for_listing, user.userid, user_name, joined, last_upload)

            if @mode == 'UPDATE'
              user.update_attributes(active: false)
              deactivated_users += 1
            end

          end

        end

        if users_to_deacivate.positive?

          # send email

          cc_email_to = user_for_cc_email
          email_to = @mode == 'PREVEIW' || @synd_coord_email.blank? ? user_for_cc_email : @synd_coord_email
          email_message = "Sending csv file via email to #{email_to}"
          output_to_log(file_for_log, email_message)
          email_subject = "FREECEN:: Deactivation of dormant users in your syndicate (run mode; #{@mode}"
          list_status = @mode == 'UPDATE' ? 'these users have been deactivated' : 'these users will be deactivated when this process is next run in UPDATE mode'
          email_body = "We have performed an exercise to mark all volunteers (transcribers, proofreaders and validators) in your #{synd.syndicate_code} who have not uploaded a file"
          email_body += " in the last #{@months / 12} years as 'inactive' in the FreeCEN system. "
          email_body += "We have listed the relevant members of your syndicate in the attached file. Please review this list and mark anyone you think is actually active as such. "
          email_body += "We are looking to reduce the time without uploading a file to one year in the next few months, so please monitor this regularly" unless @months < 13
          report_name = "Deactivate_dormant_users_#{synd.syndicate_code}_#{start_time.strftime('%Y%m%d%H%M')}.csv"
          UserMailer.report_for_syndicate_coord(email_subject, email_body, @report_csv, report_name, email_to, cc_email_to).deliver_now

          if @mode == 'UPDATE'
            log_message = "#{users_to_deacivate} users were deactivated"
          else
            log_message = "#{users_to_deacivate} users that would be deactivated "
          end
          output_to_log(file_for_log, log_message)

        end

      end

      # syndicates
    end

    if @mode == 'UPDATE'
      log_message = "Total users deactivated = #{deactivated_users}"
    else
      log_message = "Total users that would be deactivated = #{deactivated_users}"
    end
    output_to_log(file_for_log, log_message)

    end_time = Time.current
    run_time = end_time - start_time

    log_message = "Runtime #{run_time}"
    output_to_log(file_for_log, log_message)
    p log_message

  else

    p 'INVALID ARGUMENTS'
    message = "**** Invalid arguments: mode = #{args.mode}, months = #{args.months}, email = #{args.email_user} ****"
    output_to_log(file_for_log, message)


  end


  # end task
end
