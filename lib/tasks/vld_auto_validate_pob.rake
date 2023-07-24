require 'freecen1_vld_pob_validator'
namespace :freecen do

  def vld_validate_pobs(chapman_code, vld_file_name, userid)
    vld_file = Freecen1VldFile.where(dir_name: chapman_code, file_name: vld_file_name).first
    raise "VLD File #{vld_file_name} in #{chapman_code} does not exist" if vld_file.blank?

    num_individuals = vld_file.num_individuals
    run_time_estimate = (num_individuals.to_f / 1000).to_f.round(1).to_s
    puts "Estimated Run Time = #{run_time_estimate} mins"
    validator = Freecen::Freecen1VldPobValidator.new
    num_valid = validator.process_vld_file(chapman_code, vld_file_name, userid)
    [num_individuals, num_valid]
  end

  desc 'Automatic validation of VLD POB data'
  task :vld_auto_validate_pob, [:chapman_code, :vld_file_name, :userid] => [:environment] do |t, args|
    start_time = Time.now.to_f
    vld_err_messages = []
    num_individuals = 0
    num_valid = 0
    puts "Starting Automatic Validation of VLD POB data for #{args.chapman_code} - #{args.vld_file_name} for user #{args.userid}"
    begin
      num_individuals, num_valid = vld_validate_pobs(args.chapman_code, args.vld_file_name, args.userid)
    rescue => e
      puts e.message
      vld_err_messages << e.message
      vld_err_messages << "#{e.backtrace.inspect}"
    end
    num_invalid_pobs = num_individuals - num_valid
    report = "Processed #{num_individuals} individuals - found #{num_invalid_pobs} invalid POBs"
    if vld_err_messages.length > 0
      report = "The following processing error messages were reported:\n"
      vld_err_messages.each do |msg|
        report += "  #{msg}\n"
      end
    end
    puts report
    if args.userid.present?
      require 'user_mailer'
      user = UseridDetail.userid(args.userid).first
      if user.present?
        friendly_email = "#{user.person_forename} #{user.person_surname} <#{user.email_address}>"
      else
        friendly_email = "#{appname} Servant <#{appname}-processing@#{appname}.org.uk>"
      end
      puts "sending email to #{args.userid} to notify of task completion"
      UserMailer.freecen_processing_report(friendly_email, "FreeCEN VLD POB Validation for #{args.vld_file_name} ended", report).deliver
    end
    end_time = Time.now.to_f
    run_time = ((end_time - start_time) / 60).round(2).to_s
    puts "Finished Automatic Validation of VLD POB data for #{args.chapman_code} - #{args.vld_file_name} for user #{args.userid} (Runtime = #{run_time} mins)\n"
  end
end
