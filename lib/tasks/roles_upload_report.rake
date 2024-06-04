desc "Upload report for each role"
task :roles_upload_rpeort => :environment do
  start_time = Time.now
  start_date, end_date = prepare_report_dates
  @uploaders_count, @email_confirmed, @users_count = PhysicalFile.new.upload_report_data(start_date, end_date)
  @transcribers_count, @active_transcribers_count, @email_confimed = UseridDetail.get_transcriber_stats(@start_date, @end_date)
  UserMailer.send_upload_stats(start_date, end_date)
  
  private
  def prepare_report_dates
    current_month_start_date = Date.today.beginning_of_month
    start_date = current_month_start_date - 1.month
    end_date = current_month_start_date - 1
    start_date = format_date_for_report(start_date)
    end_date = format_date_for_report(end_date)
    [start_date, end_date]
  end

  def format_date_for_report date, default=nil
    formatted_date = date.present? ? date.to_datetime : default.to_datetime
    formatted_date
  end
end
