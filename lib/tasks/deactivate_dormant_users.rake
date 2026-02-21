desc "Deactivate active users who have not uploaded a CSV file since the specified  months"
task :deactivate_dormant_users, [:mode, :months, :email_user] => :environment do |_t, args|

  require 'user_mailer'

  def self.output_to_log(message_file, message)
    message_file.puts message.to_s
  end

  def self.output_to_csv(csv_file, line)
    csv_file.puts line.to_s
  end

  def self.send_email(file_for_log)
    cc_email_to = @cc_email
    email_to = @mode == 'PREVIEW' || @synd_coord_email.blank? ? @cc_email : @synd_coord_email
    email_message = "Sending csv file via email to #{email_to}"
    output_to_log(file_for_log, email_message)

    email_subject = "FREECEN:: Deactivation of dormant users in #{@syndicate}  (run mode; #{@mode})."
    list_status = @mode == 'UPDATE' ? 'These users have been deactivated' : 'These users will be deactivated when this process is next run in UPDATE mode.'
    email_body = "We have performed an exercise to mark all volunteers with roles #{@the_roles} in your #{@syndicate} who have not uploaded a file"
    email_body += " in the last #{@months / 12} years as 'inactive' in the FreeCEN system. "
    email_body += "\n"
    email_body += "#{list_status}"
    email_body += "\n"
    email_body += "We have listed the relevant members of your syndicate in the attached file. Please review this list and mark anyone you think is actually active as such. "
    email_body += "We are looking to reduce the time without uploading a file to one year in the next few months, so please monitor this regularly." unless @months < 13
    email_body += "\n"
    email_body += "\n"
    report_name = "Deactivate_dormant_users_#{@syndicate}_#{@file_date}.csv"
    # UserMailer.report_for_syndicate_coord(email_subject, email_body, @report_csv, report_name, email_to, cc_email_to).deliver_now
  end

  def self.write_csv_line(syndicate, userid, username, joined, lastupload, users_to_deacivate)

    if users_to_deacivate.zero?
      synd_text = syndicate.gsub(/[\s,]/, '_').gsub('__', '_')
      @file_for_listing = "log/Deactivate_dormant_users_#{synd_text}_#{@file_date}.csv"
      FileUtils.mkdir_p(File.dirname(@file_for_listing)) unless File.exist?(@file_for_listing)
      @file_for_listing = File.new(@file_for_listing, 'w')
      hline = 'UserId,Username,Joined,LastUpload'
      output_to_csv(@file_for_listing, hline)
      @report_csv = hline
    end

    dline = ''
    dline << "#{userid},"
    dline << "#{username},"
    dline << "#{joined},"
    dline << "#{lastupload}"
    output_to_csv(@file_for_listing, dline)
  end


  # START

  args.with_defaults(:months => 48, :mode => 'PREVIEW')
  start_time = Time.current
  @file_date = Time.current.strftime('%Y%m%d%H%M')
  total_users_to_deactive = 0

  file_for_log = "log/Deactivate_dormant_users_#{@file_date}.log"
  FileUtils.mkdir_p(File.dirname(file_for_log)) unless File.exist?(file_for_log)
  file_for_log = File.new(file_for_log, 'w')

  # check arguments

  args_valid = args.mode.present? && %w[PREVIEW REVIEW UPDATE].include?(args.mode) ? true : false
  args_valid = false unless args.months.present? && /[0-9]/.match(args.months)
  args_valid = false if args.email_user.blank?

  if args_valid == true

    user_for_cc_email = UseridDetail.find_by(userid: args.email_user)
    @cc_email = user_for_cc_email.present? ? user_for_cc_email.email_address : 'NOT FOUND'
    @months = args.months.to_i
    @mode = args.mode

    @cutoff_date = start_time - @months.months
    p "@cutoff_date = #{@cutoff_date }"

    @roles_to_review = %w[transcriber validator checker]
    @the_roles = @roles_to_review.to_s.gsub('"', '')

    deactivated_users = 0

    initial_message = "Started deactivation of dormant users : Mode = #{args.mode}, Months = #{args.months}, Email = #{args.email_user} at #{start_time}"
    output_to_log(file_for_log, initial_message)

    syndicates_to_review = Syndicate.all.order_by(syndicate_code: 1)

    syndicates_to_review.each  do |synd|
      next if synd.syndicate_code == 'Technical' || synd.syndicate_code == 'Any Questions Ask Us'

      @syndicate = synd.syndicate_code

      log_message = "Working on #{@syndicate}"
      output_to_log(file_for_log, log_message)
      p log_message

      synd_coord = synd.syndicate_coordinator
      @synd_coord_rec = UseridDetail.find_by(userid: synd_coord)
      @synd_coord_email = @synd_coord_rec.email_address

      active_users = UseridDetail.where(:syndicate => @syndicate, :person_role => { '$in' => @roles_to_review }, :active => true)

      if active_users.blank?
        log_message = "Syndicate has no active users in roles #{@the_roles}"
        output_to_log(file_for_log, log_message)
        p log_message

      else

        users_to_deacivate = 0

        active_users.each do |user|
           next if user.sign_up_date > @cutoff_date

          most_recent_upload = ''
          most_recent_upload_file = FreecenCsvFile.where(:userid => user.userid).order_by(uploaded_date: :desc).first
          most_recent_upload = most_recent_upload_file.uploaded_date if most_recent_upload_file.present?

          if most_recent_upload.blank? || most_recent_upload < @cutoff_date

            user_name = user.person_forename + ' ' + user.person_surname
            joined = user.sign_up_date.strftime('%d/%m/%Y')
            last_upload = most_recent_upload.blank? ? 'None' : most_recent_upload.strftime('%d/%m/%Y')

            write_csv_line(@syndicate, user.userid, user_name, joined, last_upload, users_to_deacivate)
            users_to_deacivate += 1

            if @mode == 'UPDATE'
              user.update_attributes(active: false)
              deactivated_users += 1
            end

          end

        end

        if users_to_deacivate.positive?
          send_email(file_for_log)
          if @mode == 'UPDATE'
            log_message = "#{users_to_deacivate} users were deactivated"
          else
            log_message = "#{users_to_deacivate} users would be deactivated "
          end
          output_to_log(file_for_log, log_message)
          total_users_to_deactive += users_to_deacivate
        end

      end

    end

    if @mode == 'UPDATE'
      log_message = "Total users deactivated = #{deactivated_users}"
    else
      log_message = "Total users that would be deactivated = #{total_users_to_deactive}"
    end
    output_to_log(file_for_log, log_message)
    p log_message

    end_time = Time.current
    run_time = end_time - start_time

    log_message = "Runtime #{run_time}"
    output_to_log(file_for_log, log_message)
    p log_message

  else

    p 'INVALID ARGUMENTS'
    message = "**** Invalid arguments: mode = #{args.mode}, months = #{args.months}, email_user = #{args.email_user} ****"
    output_to_log(file_for_log, message)

  end

end
