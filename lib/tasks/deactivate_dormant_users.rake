desc "Deactivate active users who have not uploaded a CSV file since the specified  months"
task :deactivate_dormant_users, [:mode, :months, :email_user, :exclude_syndicates] => :environment do |_t, args|

  require 'user_mailer'
  require 'chapman_code'

  def self.output_to_log(message_file, message)
    message_file.puts message.to_s
  end

  def self.output_to_csv(csv_file, line)
    csv_file.puts line.to_s
  end

  def self.write_csv_line(syndicate, userid, username, joined, confirmed_email, lastupload, users_to_deacivate)

    if users_to_deacivate.zero?
      synd_text = syndicate.gsub(/[\s,]/, '_').gsub('__', '_')
      @file_for_listing = "log/Deactivate_dormant_users_#{synd_text}_#{@file_date}.csv"
      FileUtils.mkdir_p(File.dirname(@file_for_listing)) unless File.exist?(@file_for_listing)
      @file_for_listing = File.new(@file_for_listing, 'w')
      hline = 'UserId,Username,Joined,ConfirmedEmail,LastUpload'
      output_to_csv(@file_for_listing, hline)
      @report_csv = hline
    end

    dline = ''
    dline << "#{userid},"
    dline << "#{username},"
    dline << "#{joined},"
    dline << "#{confirmed_email},"
    dline << "#{lastupload}"
    output_to_csv(@file_for_listing, dline)
    @report_csv += "\n"
    @report_csv += dline
  end

  def self.send_email(file_for_log)
    cc_email_to = @cc_email
    email_to = @mode == 'PREVIEW' || @synd_coord_email.blank? ? @cc_email : @synd_coord_email
    email_message = "Sending csv file via email to #{email_to}"
    output_to_log(file_for_log, email_message)

    email_subject = "FREECEN:: Deactivation of dormant users in #{@syndicate}  (run mode: #{@mode})."
    list_status = @mode == 'UPDATE' ? 'These users have been deactivated' : 'These users will be deactivated when this process is next run in UPDATE mode.'
    email_body = "We have performed an exercise to mark all volunteers with roles #{@the_roles} in your #{@syndicate} who have not uploaded a file"
    email_body += " in the last #{@months / 12} years as 'inactive' in the FreeCEN system. "
    email_body += "\n"
    email_body += "#{list_status}"
    email_body += "\n"
    email_body += "We have listed the relevant members of your syndicate in the attached file. Please review this list and update their profile in the FreeCEN system to active if they are actually active volunteers. "
    email_body += "We are looking to reduce the time without uploading a file to one year in the next few months." unless @months < 13
    email_body += "\n"
    email_body += "\n"
    report_name = "Deactivate_dormant_users_#{@syndicate}_#{@file_date}.csv"
    UserMailer.report_for_syndicate_coord(email_subject, email_body, @report_csv, report_name, email_to, cc_email_to).deliver_now
  end

  # START

  args.with_defaults(months: 48, mode: 'PREVIEW')

  start_time = Time.current
  @file_date = Time.current.strftime('%Y%m%d%H%M')
  total_users_to_deactive = 0
  @report_csv = ''

  file_for_log = "log/Deactivate_dormant_users_#{@file_date}.log"
  FileUtils.mkdir_p(File.dirname(file_for_log)) unless File.exist?(file_for_log)
  file_for_log = File.new(file_for_log, 'w')

  # check arguments

  @mode = args.mode.upcase
  valid_modes = %w[PREVIEW REVIEW UPDATE]

  abort 'Invalid mode argument. Must be PREVIEW, REVIEW or UPDATE' unless valid_modes.include?(@mode)

  @ignore_syndicates = []
  if args.exclude_syndicates.present?
    abort 'Invalid exclude_syndicates argument. Only relevant if mode = UPDATE' unless @mode == 'UPDATE'
    abort 'Invalid exclude_syndicates argument. Chapman code must be enclosed in round brackets' unless args.exclude_syndicates.first == '(' && args.exclude_syndicates.last == ')'
    syndicates = args.exclude_syndicates[1..-2].split(';')
    syndicates.each do |synd|
      county_name = ChapmanCode.name_from_code(synd)
      synd_code = "#{county_name} Syndicate"
      syndicate = Syndicate.find_by(syndicate_code: synd_code)
      abort "Invalid exclude_syndicate value #{synd}=(#{synd_code})" if syndicate.blank?
      @ignore_syndicates << "#{synd_code} "
    end
    log_message = "Ignoring:  #{@ignore_syndicates}"
    output_to_log(file_for_log, log_message)
    p log_message
  end

  @months = args.months.to_i
  abort 'Invalid months argumant. Must be a positive integer' if @months <= 0
  bcc_userid = args.email_user
  @user_for_cc_email = UseridDetail.where(userid: bcc_userid).first
  abort 'Invalid email argumant. Email user not found' unless @user_for_cc_email
  @cc_email = @user_for_cc_email.email_address

  @cutoff_date = @months.months.ago.to_date
  log_message = "Cutoff date = #{@cutoff_date.strftime('%d%m%Y')}"
  output_to_log(file_for_log, log_message)
  p log_message

  @roles_to_review = %w[transcriber validator checker]
  @the_roles = @roles_to_review.to_s.gsub('"', '')

  deactivated_users = 0

  initial_message = "Started deactivation of dormant users : Mode = #{args.mode}, Months = #{args.months}, Email = #{args.email_user} at #{start_time}"
  output_to_log(file_for_log, initial_message)
  p initial_message

  Syndicate.all.asc(:syndicate_code).each do |synd|
    next if synd.syndicate_code == 'Technical' || synd.syndicate_code == 'Any Questions Ask Us'

    next if @ignore_syndicates.include?(synd.syndicate_code)

    # next unless synd.syndicate_code == 'Essex Syndicate'    # AEV TESTING

    @syndicate = synd.syndicate_code

    log_message = "Processing syndicate:  #{@syndicate}"
    output_to_log(file_for_log, log_message)
    p log_message

    synd_coord = UseridDetail.where(userid: synd.syndicate_coordinator).first
    unless synd_coord
      logger.warn 'Coordinator not found — skipping syndicate'
      next
    end

    @synd_coord_email = synd_coord.email_address

    active_users = UseridDetail.where(:syndicate => synd.syndicate_code, :active => true, :sign_up_date.lt => @cutoff_date, :email_address_last_confirmned.lt => @cutoff_date).order_by(userid_lower_case: 1)

    users_to_deacivate = 0

    active_users.each do |user|
      next unless @roles_to_review.include? user.person_role

      last_file = FreecenCsvFile.where(userid: user.userid).desc(:uploaded_date).limit(1).first

      next if last_file.present? && last_file.uploaded_date.to_date >= @cutoff_date

      user_full_name = "#{user.person_forename} #{user.person_surname}"
      joined = user.sign_up_date.strftime('%d/%m/%Y')
      confirmed_email = user.email_address_last_confirmned.strftime('%d/%m/%Y')
      last_upload = last_file.nil? ? 'None' : last_file.uploaded_date.strftime('%d/%m/%Y')

      write_csv_line(@syndicate, user.userid, user_full_name, joined, confirmed_email, last_upload, users_to_deacivate)
      users_to_deacivate += 1

      if @mode == 'UPDATE'
        user.update_attributes(active: false)

        # user.update_attributes(active: false) unless deactivated_users.positive?       # AEV TESTING

        deactivated_users += 1
      end
    end

    if users_to_deacivate.positive?

      send_email(file_for_log)
      log_message = @mode == 'UPDATE' ? log_message = "#{users_to_deacivate} users were deactivated" : log_message = "#{users_to_deacivate} users would be deactivated"
      output_to_log(file_for_log, log_message)
      total_users_to_deactive += users_to_deacivate

    else

      log_message = 'Syndicate has no users that meet deactivation criteria'
      output_to_log(file_for_log, log_message)
      p log_message

    end

  end

  log_message = @mode == 'UPDATE' ? "Total users deactivated = #{deactivated_users}" : "Total users that would be deactivated = #{total_users_to_deactive}"
  output_to_log(file_for_log, log_message)
  p log_message

  end_time = Time.current
  run_time = end_time - start_time

  log_message = "Runtime #{run_time}"
  output_to_log(file_for_log, log_message)
  p log_message
end
