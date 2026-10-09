desc 'List FreeCEN Search record Ids whose freecen_csv_file no longer exists (index-only version for LIVE)'
task :list_freecen_orphan_search_records, [:user_for_email] => :environment do |_t, args|
  require 'user_mailer'

  start_time = Time.current
  file_date = start_time.strftime('%Y%m%d%H%M')

  file_for_log = "#{Rails.root}/log/list_freecen_orphan_search_records_#{file_date}.log"
  FileUtils.mkdir_p(File.dirname(file_for_log))
  log_file = File.new(file_for_log, 'w')

  # The file delete_orphaned_freecen_search_records reads. Rewritten on each run so it never holds old ids.
  file_for_txt = "#{Rails.root}/log/freecen_search_records_broken_csv_files_link.txt"

  email_userid = args.user_for_email
  user_email = UseridDetail.where(userid: email_userid).first
  abort 'Invalid user for email argument. User not found' unless user_email
  friendly_email = "#{user_email.person_forename} #{user_email.person_surname} <#{user_email.email_address}>"

  message = "Listing FreeCEN Search_record Ids where the freecen_csv_file no longer exists, User for email = #{email_userid} at #{start_time}"
  log_file.puts message
  p message

  # list_freecen_search_records_broken_csv_files_link walks search_records in _id order and times out on LIVE.
  # distinct is answered from the freecen_csv_file_id index (one entry per file, no documents read), and the
  # per-file lookups below use the same index, so this only touches the orphaned records themselves.
  referenced_ids = SearchRecord.where(:freecen_csv_file_id.ne => nil).distinct(:freecen_csv_file_id)
  existing_ids = FreecenCsvFile.where(:_id.in => referenced_ids).pluck(:_id)
  missing_ids = referenced_ids - existing_ids

  message = "Referenced freecen_csv_files: #{referenced_ids.size} | Missing: #{missing_ids.size}"
  log_file.puts message
  p message

  total_orphans = 0
  file_lines = []
  File.open(file_for_txt, 'w') do |txt_file|
    missing_ids.each do |file_id|
      records = SearchRecord.where(freecen_csv_file_id: file_id)
      record_ids = records.pluck(:_id)
      record_ids.each { |id| txt_file.puts id.to_s }
      total_orphans += record_ids.size

      line = "freecen_csv_file_id #{file_id} (created #{file_id.generation_time.to_date}): " \
             "#{record_ids.size} search records, chapman_code #{records.distinct(:chapman_code).join(' ')}"
      file_lines << line
      log_file.puts line
      p line
    end
  end

  message = "Sending report via email to #{email_userid}"
  log_file.puts message
  p message

  email_subject = 'FREECEN:: Listing FreeCEN Search record Ids where the link to freecen_csv_files is broken.'
  email_body = "#{missing_ids.size} of #{referenced_ids.size} referenced freecen_csv_files no longer exist."
  email_body += "\n"
  email_body += "#{total_orphans} orphaned Search records found."
  email_body += "\n"
  email_body += file_lines.join("\n")
  email_body += "\n"
  email_body += "See file #{file_for_txt} for list of Search record ids." if total_orphans.positive?
  UserMailer.freecen_processing_report(friendly_email, email_subject, email_body).deliver

  run_time = Time.current - start_time
  message = "Finished. #{total_orphans} orphaned Search records in #{missing_ids.size} missing files written to #{file_for_txt}. Run Time = #{run_time.round(2)} secs"
  log_file.puts message
  p message
end
