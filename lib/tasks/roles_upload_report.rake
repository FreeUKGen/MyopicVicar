desc "Upload report for each role"
task :roles_upload_report => :environment do
  start_time = Time.now
  
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

  start_date, end_date = prepare_report_dates
  UserMailer.send_upload_stats(start_date, end_date)

end
