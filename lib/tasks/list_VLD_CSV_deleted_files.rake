namespace :freecen do
  desc 'List VLD CSV deleted files'
  task :list_VLD_CSV_deleted_files, [:days, :email_address] => :environment do |_t, args|

    print "Usage: list_VLD_CSV_deleted_files[days,email_address]

      \tEmail Data Manager a list of VLD/CSV files that have been Deleted/Unincorporated/Removed
      \tprior to run date minus the specified number of days
      \tand the fc2 Piece Status does not currently have a status = Online.
      \tdays is optional, default days = 7
      \temail_address is optional, if entered the email will be sent to that address rather than users with the data_manager role\n\n"


    args.with_defaults(:days => 7, :email_address => nil)
    print "List VLD_CSV deleted files args[:days]=#{args[:days]}\targs[:email_address]=#{args[:email_address]}\n"

    require 'user_mailer'

    email_to = args.email_address.present? ? args[:email_address] : 'data_manager'

    time = Time.now.utc
    last_midnight = Time.utc(time.year, time.month, time.day)

    earliest_date = last_midnight - args.days.to_i.days

    email_subject = "FreeCEN: VLD and CSVProc files deleted before #{earliest_date.strftime('%d %b %Y')} that have not subsequently been incorporated"

    p "Started listing of #{email_subject}}"
    vld_files_deleted_cnt = 0
    csvproc_files_deleted_cnt = 0
    report_csv = ''
    report_name = 'FreeCEN_VLD_CSV_deleted_files.csv'
    report_header = 'chapman_code,file_type,file_name,num_entries,load_type,loaded_date,loaded_by,transcriber,action_type,action_date,actioned_by,piece_status'

    vlds_deleted = Freecen1VldFileAudit.where(c_at: { '$lt': earliest_date }).all.order_by(dir_name: 1, file_name: 1, c_at: -1)

    vlds_deleted.each do |vld|

      piece_status = ''
      unless vld.fc2_piece_id.blank?
        fc2_piece = Freecen2Piece.find_by(_id: vld.fc2_piece_id)
        piece_status = fc2_piece.status
      end

      next if piece_status == 'Online'

      report_csv = report_header  if report_csv.length == 0

      report_csv += "\n"
      report_csv += "#{vld.dir_name},VLD,#{vld.file_name},#{vld.num_entries},#{vld.action},#{vld.loaded_at.strftime('%d %b %Y %H:%M')},#{vld.userid},#{vld.transcriber_name},Deleted,#{vld.c_at.strftime('%d %b %Y %H:%M')},#{vld.deleted_by},#{piece_status}"
      vld_files_deleted_cnt += 1

    end

    csvs_deleted = FreecenCsvFileAudit.where(c_at: { '$lt': earliest_date }).all.order_by(chapman_code: 1, file_name: 1, c_at: -1)

    csvs_deleted.each do |csv|

      piece_status = ''
      unless csv.fc2_piece_id.blank?
        fc2_piece = Freecen2Piece.find_by(_id: csv.fc2_piece_id)
        piece_status = fc2_piece.status
      end

      next if piece_status == 'Online'

      report_csv = report_header  if report_csv.length == 0

      report_csv += "\n"
      report_csv += "#{csv.chapman_code},CSV,#{csv.file_name},#{csv.total_records},CSVProcLoad,#{csv.loaded_at.strftime('%d %b %Y %H:%M')},#{csv.userid},#{csv.transcriber_name},#{csv.action_type},#{csv.c_at.strftime('%d %b %Y %H:%M')},#{csv.action_by},#{piece_status}"
      csvproc_files_deleted_cnt += 1

    end

    line1 = "#{vld_files_deleted_cnt} VLD files were deleted before #{earliest_date.strftime('%d %b %Y')} and have not subsequently been incorporated as CSVProc files."
    line2 = "#{csvproc_files_deleted_cnt} CSVProc files were unincorporated/removed/deleted before #{earliest_date.strftime('%d %b %Y')} and have not subsequently been incorporated."

    if vld_files_deleted_cnt.positive? || csvproc_files_deleted_cnt.positive?
      line3 = 'See attached csv file for details.'
      email_body = line1 + "\n" + line2 + "\n" + line3 + "\n"
    else
      email_body = line1 + "\n" + line2
    end

    p "Sending email"
    UserMailer.report_for_data_manager(email_subject, email_body, report_csv, report_name, email_to).deliver_now

    p "Finished listing of #{email_subject}}"
  end
end
