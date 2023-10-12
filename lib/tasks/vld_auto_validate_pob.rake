namespace :freecen do

  desc 'Automatic validation of VLD POB data'
  task :vld_auto_validate_pob, [:mode, :chapman_code, :vld_file_name, :userid, :limit] => [:environment] do |t, args|

    require 'freecen1_vld_pob_validator'
    require 'user_mailer'

    def self.email_csv_file(userid, ccuserid, scope, report, report_csv, log_file)
      user_rec = UseridDetail.userid(userid).first
      ccuser_rec = UseridDetail.userid(ccuserid).first

      email_subject = "FreeCEN: VLD files POB Validation for #{scope}"
      email_body = report_csv == '' ? report += 'No invalid POBs found.' : report += 'See attached CSV file.'
      email_body += "\n"
      report_name = "FreeCEN_VLD_invalid_pob_#{scope}.csv"
      email_to = user_rec.email_address
      ccemail_to = ccuser_rec.email_address

      message = "Sending email to #{userid} - list of VLD files with invalid pob attached"
      output_to_log(log_file, message)

      UserMailer.freecen_vld_invalid_pob_report(email_subject, email_body, report_csv, report_name, email_to, ccemail_to).deliver_now
    end

    def self.email_summary_to_user(userid, scope, report, log_file)
      user = UseridDetail.userid(userid).first
      if user.present?
        friendly_email = "#{user.person_forename} #{user.person_surname} <#{user.email_address}>"
        message = "Sending email to #{userid} to notify of task completion"
      else
        friendly_email = "#{appname} Servant <#{appname}-processing@#{appname}.org.uk>"
        message = "Sending email to #{appname} Servant to notify of task completion"
      end
      output_to_log(log_file, message)
      UserMailer.freecen_processing_report(friendly_email, "FreeCEN VLD POB Validation for #{scope} ended", report).deliver
    end

    def self.output_csv_header
      dline = ''
      dline << 'file_name,'
      dline << 'dwelling_number,'
      dline << 'sequence_in_household,'
      dline << 'forenames,'
      dline << 'surname,'
      dline << 'pob_valid,'
      dline << 'pob_warning,'
      dline << 'verbatim_birth_county,'
      dline << 'verbatim_birth_place,'
      dline << 'birth_county,'
      dline << 'birth_place,'
      dline << 'notes'
      dline
    end

    def self.output_csv_line(file_name, entry)
      dline = ''
      dline << "#{file_name},"
      dline << "#{entry.dwelling_number},"
      dline << "#{entry.sequence_in_household},"
      dline << "#{entry.forenames},"
      dline << "#{entry.surname},"
      dline << "#{entry.pob_valid},"
      dline << "#{entry.pob_warning},"
      dline << "#{entry.verbatim_birth_county},"
      dline << "#{entry.verbatim_birth_place},"
      dline << "#{entry.birth_county},"
      dline << "#{entry.birth_place},"
      dline << "#{entry.notes}"
      dline
    end

    def self.output_to_log(log_file, message)
      log_file.puts message.to_s
    end

    def self.open_log_file(log_file_name)
      FileUtils.mkdir_p(File.dirname(log_file_name)) unless File.exist?(log_file_name)
      File.new(log_file_name, 'w')
    end

    def self.read_in_county_csv_file(csv_filename)
      begin
        array_of_data_lines = CSV.read(csv_filename)
        success = true
      rescue Exception => msg
        success = false
        message = "#{msg}, #{msg.backtrace.inspect}"
        p message
        success = false
      end
      [success, array_of_data_lines]
    end

    def self.validate_vld_pob_one_county(chapman_code, userid, ccuserid, limit, log_file)
      vld_err_messages = []
      num_individuals = 0
      num_valid = 0
      file_limit = limit.to_i
      max_files = file_limit.zero? ? 999_999 : file_limit
      files_processed = 0
      previously_unvalidated_processed = 0
      total_individuals = 0
      total_invalid_pobs = 0
      report = ''
      report_csv = ''

      files = Freecen1VldFile.where(dir_name: chapman_code).order_by(file_name: 1)

      files.each do |file|
        previously_validated = Freecen1VldEntry.where(freecen1_vld_file_id: file.id, pob_valid: false).or(Freecen1VldEntry.where(freecen1_vld_file_id: file.id, pob_valid: true)).first
        previously_unvalidated_processed += 1 if previously_validated.blank?
        next if previously_unvalidated_processed > max_files

        files_processed += 1
        begin
          num_individuals, num_valid = vld_validate_pobs(chapman_code, file, userid)
        rescue => e
          vld_err_messages << e.message
          vld_err_messages << "#{e.backtrace.inspect}"
        end

        break unless vld_err_messages.empty?

        num_invalid_pobs = num_individuals - num_valid
        total_individuals += num_individuals
        total_invalid_pobs += num_invalid_pobs

        invalid_pob_entries = Freecen1VldEntry.where(freecen1_vld_file_id: file.id, pob_valid: false).order_by(id: 1)

        invalid_pob_entries.each do |entry|
          report_csv  += output_csv_header if report_csv.empty?
          report_csv  += "\n"
          report_csv  += output_csv_line(file.file_name, entry)
        end
        message = "Processed #{file.file_name} - #{num_individuals} individuals - found #{num_invalid_pobs} invalid POBs\n"
        report += message
      end

      message = "Processed #{chapman_code} - #{files_processed} vld files with #{total_individuals} individuals - found #{total_invalid_pobs} invalid POBs\n"
      report += message
      unless vld_err_messages.empty?
        report += "The following processing error messages were reported:\n"
        vld_err_messages.each do |msg|
          report += "  #{msg}\n"
        end
      end
      return if userid.blank?

      output_to_log(log_file, report)
      email_csv_file(userid, ccuserid, chapman_code, report, report_csv, log_file)
    end

    def self.validate_vld_pob_one_file(chapman_code, vld_file, userid, log_file)
      vld_err_messages = []
      num_individuals = 0
      num_valid = 0
      begin
        num_individuals, num_valid = vld_validate_pobs(chapman_code, vld_file, userid)
      rescue => e
        vld_err_messages << e.message
        vld_err_messages << "#{e.backtrace.inspect}"
      end
      num_invalid_pobs = num_individuals - num_valid
      report = "Processed #{num_individuals} individuals - found #{num_invalid_pobs} invalid POBs"
      unless vld_err_messages.empty?
        report += "The following processing error messages were reported:\n"
        vld_err_messages.each do |msg|
          report += "  #{msg}\n"
        end
      end
      output_to_log(log_file, report)
      return unless userid.present?

      scope = vld_file.file_name
      email_summary_to_user(userid, scope, report, log_file)
    end

    def self.vld_validate_pobs(chapman_code, vld_file, userid)
      num_individuals = vld_file.num_individuals
      validator = Freecen::Freecen1VldPobValidator.new
      num_valid = validator.process_vld_file(chapman_code, vld_file, userid)
      [num_individuals, num_valid]
    end

    #
    # START
    #

    run_start = Time.current
    if args.mode == 'F'
      chapman_code = args.chapman_code
      vld_file_name = args.vld_file_name
      userid = args.userid

      file_for_log = "log/vld_auto_validate_pob_#{chapman_code}_#{vld_file_name}_#{run_start.strftime('%Y%m%d%H%M')}.log"
      log_file = open_log_file(file_for_log)

      message = "Starting Automatic Validation of VLD POB data for #{chapman_code} - #{vld_file_name} for user #{userid}"
      p message
      output_to_log(log_file, message)
      start_time = Time.now.to_f
      vld_file = Freecen1VldFile.where(dir_name: chapman_code, file_name: vld_file_name).first
      validate_vld_pob_one_file(chapman_code, vld_file, userid, log_file)
      end_time = Time.now.to_f
      run_time = ((end_time - start_time) / 60).round(2).to_s
      message = "Finished Automatic Validation of VLD POB data for #{chapman_code} - #{vld_file_name} for user #{userid} (runtime = #{run_time} mins)\n"
      output_to_log(log_file, message)
      p message
    else
      csv_filename = Rails.root.join('tmp', 'VLD_POB_COUNTY.CSV')
      if File.file?(csv_filename)
        _success, county_def_array = read_in_county_csv_file(csv_filename)
        county_def_array.each do |params|
          @chapman_code = params[0].to_s
          @userid = params[1].to_s
          @ccuserid = params[2].to_s
          @limit = params[3].to_s
        end
        file_for_log = "log/vld_auto_validate_pob_#{@chapman_code}_#{run_start.strftime('%Y%m%d%H%M')}.log"
        log_file = open_log_file(file_for_log)
        message = "Starting Automatic Validation of VLD POB data for #{@chapman_code} - for user #{@userid} (cc user #{@ccuserid}) with limit of previously unvalidated files = #{@limit}"
        output_to_log(log_file, message)
        p message
        start_time = Time.now.to_f
        validate_vld_pob_one_county(@chapman_code, @userid, @ccuserid, @limit, log_file)
        end_time = Time.now.to_f
        run_time = ((end_time - start_time) / 60).round(2).to_s
        message = "Finished Automatic Validation of VLD POB data for #{@chapman_code} - for user #{@userid} (cc user #{@ccuserid}) with limit of previously unvalidated files = #{@limit} (runtime = #{run_time} mins)\n"
        output_to_log(log_file, message)
        p message
      else
        p "ERROR - #{csv_filename} does not exist in Rails root tmp folder"
      end
    end
  end
end
