namespace :freecen do

  desc 'Prevalidation of CSV data'
  task :csv_prevalidate, [:csv_file_name, :userid] => [:environment] do |t, args|

    require 'freecen_csv_prevalidator'
    require 'user_mailer'

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
      UserMailer.freecen_processing_report(friendly_email, "FreeCEN Prevalidation for #{scope} completed", report).deliver
    end

    def self.output_to_log(log_file, message)
      log_file.puts message.to_s
    end

    def self.open_log_file(log_file_name)
      FileUtils.mkdir_p(File.dirname(log_file_name)) unless File.exist?(log_file_name)
      File.new(log_file_name, 'w')
    end

    def self.prevalidate_file(csv_file, userid, log_file)
      csv_err_messages = []
      updated_records = []
      begin
        updated_records = prevalidate(csv_file, userid)
      rescue => e
        csv_err_messages << e.message
        csv_err_messages << "#{e.backtrace.inspect}"
      end
      if updated_records.size > 0
        report = "Alternate POB / Notes were updated on the following entry numbers #{updated_records}."
      else
        report = 'No updates were made by Prevalidation.'
      end
      unless csv_err_messages.empty?
        report += "The following processing error messages were reported:\n"
        csv_err_messages.each do |msg|
          report += "  #{msg}\n"
        end
      end
      output_to_log(log_file, report)

      return if userid.blank?

      scope = "#{csv_file.file_name}"
      email_summary_to_user(userid, scope, report, log_file)
    end

    def self.prevalidate(csv_file, userid)
      validator = Freecen::FreecenCsvPrevalidator.new
      recs_updated = validator.process_csv_file(csv_file, userid)
      recs_updated
    end

    #
    # START
    #

    run_start = Time.current
    csv_file_name = args.csv_file_name
    userid = args.userid

    file_for_log = "#{Rails.root}/log/csv_prevalidate_pob_#{csv_file_name}_#{run_start.strftime('%Y%m%d%H%M')}.log"
    log_file = open_log_file(file_for_log)

    message = "Starting Prevalidation of CSV data for #{csv_file_name} for user #{userid}"
    p message
    output_to_log(log_file, message)
    start_time = Time.now.to_f
    csv_file = FreecenCsvFile.where(file_name: csv_file_name).first
    prevalidate_file(csv_file, userid, log_file)
    end_time = Time.now.to_f
    run_time = ((end_time - start_time) / 60).round(2).to_s
    message = "Finished Prevalidation of CSV data for #{csv_file_name} for user #{userid} (runtime = #{run_time} mins)\n"
    output_to_log(log_file, message)
    p message
  end
end
