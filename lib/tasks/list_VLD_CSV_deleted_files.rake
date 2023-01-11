namespace :freecen do

  desc 'List VLD CSV deleted files'
  task :list_VLD_CSV_deleted_files, [:days]  => :environment do | t, args|
    require 'user_mailer'

    last_midnight = Time.now.utc

    earliest_date = last_midnight - args.days.to_i.days

    email_subject = "FreeCEN: VLD and CSVProc files deleted before #{earliest_date.strftime('%d %b %Y')} that have not subsequently been incorporated"

    p "Started listing of #{email_subject}}"
    vld_files_deleted_cnt = 0
    csvproc_files_deleted_cnt = 0
    report_csv = ''
    report_name = 'FreeCEN_VLD_CSV_deleted_files.csv'
    report_header = 'chapman_code,file_type,file_name,num_entries,load_type,loaded_date,loaded_by,transcriber,action_type,action_date,actioned_by,piece_status'

    vlds_deleted = Freecen1VldFileAudit.where(c_at: { '$lt': earliest_date }).all.order_by(dir_name: 1, c_at: 1)

    vlds_deleted.each do |vld|

      piece_status = ''
      unless vld.fc2_piece_id.blank?
        fc2_piece = Freecen2Piece.find_by(_id: vld.fc2_piece_id)
        piece_status = fc2_piece.status
      end

      unless piece_status == 'Online'

        report_csv = report_header  if report_csv.length == 0

        report_csv += "\n"
        report_csv += "#{vld.dir_name},VLD,#{vld.file_name},#{vld.num_entries},#{vld.action},#{vld.loaded_at.strftime('%d %b %Y')},#{vld.userid},#{vld.transcriber_name},Deleted,#{vld.c_at.strftime('%d %b %Y')},#{vld.deleted_by},#{piece_status}"
        vld_files_deleted_cnt += 1
      end
    end

    line1 = "#{vld_files_deleted_cnt} VLD files were deleted before #{earliest_date.strftime('%d %b %Y')} and have not subsequently been incorporated as CSVProc files."
    line2 = "#{csvproc_files_deleted_cnt} CSVProc files were deleted before #{earliest_date.strftime('%d %b %Y')} and have not subsequently been re-incorporated."

    if vld_files_deleted_cnt.positive? || csvproc_files_deleted_cnt.positive?
      line3 = 'See attached csv file for details.'
      email_body = line1 + "\n" + line2 + "\n" + line3 + "\n"
    else
      email_body = line1 + "\n" + line2
    end

    p 'Sending email to Data Manager(s)'
    UserMailer.report_for_data_manager(email_subject, email_body, report_csv, report_name).deliver_now

    p "Finished listing of #{email_subject}}"
  end
end
