desc "Count and optionally fix whitespaces in SearchRecord transcript_names (first_name and last_name fields)"
task :count_and_fix_whitespaces_in_search_record_names, [:limit, :fix, :email, :start_date, :end_date] => :environment do |t, args|

  require 'user_mailer'

  def self.output_to_log(message_file, message)
    message_file.puts message.to_s
    p message.to_s
  end

  def self.output_to_csv(csv_file, line)
    csv_file.puts line.to_s
  end

  def self.write_csv_line(csv_file, rec_id, original_names, cleaned_names, action)
    dline = ''
    dline << "#{rec_id},"
    dline << "\"#{original_names}\","
    dline << "\"#{cleaned_names}\","
    dline << action.to_s
    output_to_csv(csv_file, dline)
    if @send_email
      @report_csv += "\n"
      @report_csv += dline
    end
  end

  def self.strip_whitespaces_from_names(transcript_names)
    cleaned_names = transcript_names.map do |name_hash|
      cleaned_hash = name_hash.dup
      
      if cleaned_hash['first_name'].present?
        cleaned_hash['first_name'] = cleaned_hash['first_name'].strip.gsub(/\s+/, ' ')
      end
      
      if cleaned_hash['last_name'].present?
        cleaned_hash['last_name'] = cleaned_hash['last_name'].strip.gsub(/\s+/, ' ')
      end
      
      cleaned_hash
    end
    cleaned_names
  end

  def self.has_whitespace_issue?(str)
    return false if str.blank?
    str != str.strip || str =~ /\s{2,}/
  end

  def self.check_record_for_whitespace(rec)
    rec.transcript_names.any? do |name|
      has_whitespace_issue?(name['first_name']) || has_whitespace_issue?(name['last_name'])
    end
  end

  def self.update_search_record(rec, fix, listing)
    original_names = rec.transcript_names
    cleaned_names = strip_whitespaces_from_names(original_names)
    
    if original_names != cleaned_names
      rec.set(transcript_names: cleaned_names) if fix
      original_str = original_names.map { |n| "#{n['first_name']} #{n['last_name']}" }.join(' | ')
      cleaned_str = cleaned_names.map { |n| "#{n['first_name']} #{n['last_name']}" }.join(' | ')
      write_csv_line(listing, rec._id, original_str, cleaned_str, fix ? 'UPDATED' : 'WOULD_UPDATE')
      return true
    end
    false
  end

  # START

  args.with_defaults(:limit => 0, :fix => 'N', :email => 'N')
  start_time = Time.current

  @send_email = args.email != 'N'
  @email_to = args.email if @send_email

  file_for_log = "log/count_and_fix_whitespaces_#{start_time.strftime('%Y%m%d%H%M')}.log"
  file_for_listing = "log/count_and_fix_whitespaces_#{start_time.strftime('%Y%m%d%H%M')}.csv"
  FileUtils.mkdir_p(File.dirname(file_for_log)) unless File.exist?(file_for_log)
  FileUtils.mkdir_p(File.dirname(file_for_listing)) unless File.exist?(file_for_listing)
  file_for_log = File.new(file_for_log, 'w')
  file_for_listing = File.new(file_for_listing, 'w')
  fixit = args.fix.to_s == 'Y'
  record_limit = args.limit.to_i
  batch_size = 2000

  # Parse date range if provided
  start_date = nil
  end_date = nil
  if args.start_date.present?
    begin
      start_date = Date.parse(args.start_date).beginning_of_day
    rescue ArgumentError
      output_to_log(file_for_log, "Invalid start_date format: #{args.start_date}. Use YYYY-MM-DD")
    end
  end
  if args.end_date.present?
    begin
      end_date = Date.parse(args.end_date).end_of_day
    rescue ArgumentError
      output_to_log(file_for_log, "Invalid end_date format: #{args.end_date}. Use YYYY-MM-DD")
    end
  end

  # Default date range: August 1, 2025 to December 31, 2025 if not specified
  start_date ||= Date.new(2025, 8, 1).beginning_of_day
  end_date ||= Date.new(2025, 12, 31).end_of_day

  initial_message = "Started counting/fixing whitespaces in SearchRecord names with fix = #{fixit}"
  if start_date && end_date
    initial_message += " - Date range: #{start_date.to_date} to #{end_date.to_date}"
  end
  initial_message += " - record limit = #{record_limit > 0 ? record_limit : 'unlimited'}"
  start_message = initial_message
  @report_csv = ''

  output_to_log(file_for_log, start_message)
  length_start_message = start_message.length

  search_recs_processed = 0
  search_recs_with_issues = 0
  search_recs_updated = 0

  hline = 'Record_ID,Original_Names,Cleaned_Names,Action'
  output_to_csv(file_for_listing, hline)
  @report_csv = hline if @send_email

  # Build query
  query = SearchRecord.where(:transcript_names.exists => true)
  query = query.where(:c_at.gte => start_date) if start_date
  query = query.where(:c_at.lte => end_date) if end_date
  
  total_records = query.count
  message = "Found #{total_records} SearchRecords to check"
  output_to_log(file_for_log, message)

  # Process records in batches
  processed = 0
  query.only(:transcript_names)
       .no_timeout
       .each_slice(batch_size) do |batch|
    
    batch.each do |search_rec|
      if check_record_for_whitespace(search_rec)
        search_recs_with_issues += 1
        
        if fixit
          updated = update_search_record(search_rec, fixit, file_for_listing)
          search_recs_updated += 1 if updated
        else
          # Just log it for counting
          original_str = search_rec.transcript_names.map { |n| "#{n['first_name']} #{n['last_name']}" }.join(' | ')
          write_csv_line(file_for_listing, search_rec._id, original_str, original_str, 'HAS_WHITESPACE')
        end
      end
      
      search_recs_processed += 1
      break if record_limit > 0 && search_recs_processed >= record_limit
    end
    
    processed += batch.length
    if processed % 10000 == 0 || processed >= total_records
      output_to_log(file_for_log, "Processed #{processed}/#{total_records} (#{(processed.to_f/total_records*100).round(1)}%), found #{search_recs_with_issues} with issues#{fixit ? ", updated #{search_recs_updated}" : ''}")
    end
    
    break if record_limit > 0 && search_recs_processed >= record_limit
  end

  end_time = Time.current
  run_time = end_time - start_time

  message = "Finished counting/fixing whitespaces in SearchRecord names - run time = #{run_time.round(2)} seconds"
  output_to_log(file_for_log, message)
  message = "Processed #{search_recs_processed} SearchRecord records, found #{search_recs_with_issues} with whitespace issues#{fixit ? ", updated #{search_recs_updated} records" : ''}"
  output_to_log(file_for_log, message)
  message = "See log/count_and_fix_whitespaces_YYYYMMDDHHMM.csv and .log for output"
  output_to_log(file_for_log, message)

  unless args.email == 'N'
    user_rec = UseridDetail.userid(@email_to).first
    if user_rec.present?
      email_message = "Sending csv file via email to #{user_rec.email_address}"
      output_to_log(file_for_log, email_message)
      subject_line_length = length_start_message - 66
      email_subject = "#{App.name_upcase}:: #{start_message[66, subject_line_length]}"
      email_body = "Processed #{search_recs_processed} records, found #{search_recs_with_issues} with whitespace issues#{fixit ? ", updated #{search_recs_updated} records" : ''} - Count and fix whitespaces csv output file attached"
      report_name = "count_and_fix_whitespaces_#{start_time.strftime('%Y%m%d%H%M')}.csv"
      UserMailer.report_for_data_manager(email_subject, email_body, @report_csv, report_name, user_rec.email_address).deliver_now
    else
      output_to_log(file_for_log, "ERROR: Userid #{@email_to} not found - email not sent")
    end
  end
  # end task
end

desc "Count SearchRecords with whitespaces in transcript_names (first_name and last_name fields)"
task :count_whitespaces_in_search_record_names, [:start_date, :end_date] => :environment do |t, args|

  def self.output_to_log(message_file, message)
    message_file.puts message.to_s
    p message.to_s
  end

  def self.has_whitespace_issue?(str)
    return false if str.blank?
    str != str.strip || str =~ /\s{2,}/
  end

  def self.check_record_for_whitespace(rec)
    rec.transcript_names.any? do |name|
      has_whitespace_issue?(name['first_name']) || has_whitespace_issue?(name['last_name'])
    end
  end

  # START

  start_time = Time.current

  file_for_log = "log/count_whitespaces_#{start_time.strftime('%Y%m%d%H%M')}.log"
  FileUtils.mkdir_p(File.dirname(file_for_log)) unless File.exist?(file_for_log)
  file_for_log = File.new(file_for_log, 'w')
  
  batch_size = 2000

  # Parse date range if provided
  start_date = nil
  end_date = nil
  if args.start_date.present?
    begin
      start_date = Date.parse(args.start_date).beginning_of_day
    rescue ArgumentError
      output_to_log(file_for_log, "Invalid start_date format: #{args.start_date}. Use YYYY-MM-DD")
      exit
    end
  end
  if args.end_date.present?
    begin
      end_date = Date.parse(args.end_date).end_of_day
    rescue ArgumentError
      output_to_log(file_for_log, "Invalid end_date format: #{args.end_date}. Use YYYY-MM-DD")
      exit
    end
  end

  # Default date range: August 1, 2025 to December 31, 2025 if not specified
  start_date ||= Date.new(2025, 8, 1).beginning_of_day
  end_date ||= Date.new(2025, 12, 31).end_of_day

  initial_message = "Started counting whitespaces in SearchRecord names"
  initial_message += " - Date range: #{start_date.to_date} to #{end_date.to_date}"
  output_to_log(file_for_log, initial_message)

  count = 0
  processed = 0

  # Build query
  query = SearchRecord.where(:transcript_names.exists => true)
  query = query.where(:c_at.gte => start_date) if start_date
  query = query.where(:c_at.lte => end_date) if end_date
  
  total_records = query.count
  message = "Found #{total_records} SearchRecords to check"
  output_to_log(file_for_log, message)

  # Process records in batches
  query.only(:transcript_names)
       .no_timeout
       .each_slice(batch_size) do |batch|
    
    batch.each do |search_rec|
      if check_record_for_whitespace(search_rec)
        count += 1
      end
      processed += 1
    end
    
    if processed % 10000 == 0 || processed >= total_records
      percentage = (processed.to_f/total_records*100).round(1)
      output_to_log(file_for_log, "Processed #{processed}/#{total_records} (#{percentage}%), found #{count} with whitespace issues")
    end
  end

  end_time = Time.current
  run_time = end_time - start_time

  message = "Finished counting whitespaces in SearchRecord names - run time = #{run_time.round(2)} seconds"
  output_to_log(file_for_log, message)
  message = "Total SearchRecords with whitespace issues: #{count} out of #{total_records} checked"
  output_to_log(file_for_log, message)
  if total_records > 0
    percentage = (count.to_f/total_records*100).round(2)
    message = "Percentage: #{percentage}%"
    output_to_log(file_for_log, message)
  end
  message = "See log/count_whitespaces_YYYYMMDDHHMM.log for details"
  output_to_log(file_for_log, message)

  # end task
end