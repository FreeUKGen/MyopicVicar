namespace :freecen do

  desc 'Check Welsh Places are in Gezetteer'
  task :check_welsh_places_in_gazetteer, [:userid, :limit] => [:environment] do |t, args|

    require 'user_mailer'

    def self.email_csv_file(userid, report, report_csv, log_file)
      user_rec = UseridDetail.userid(userid).first

      email_subject = "FreeCEN: Check Welsh Places are in Gazetteer"
      email_body = report_csv == '' ? report += 'No places to check' : report += ' See attached CSV file.'
      email_body += "\n"
      report_name = "FreeCEN_Welsh_places_report.csv"
      email_to = user_rec.email_address

      message = "Sending email to #{userid} - report attached"
      output_to_log(log_file, message)

      UserMailer.report_for_data_manager(email_subject, email_body, report_csv, report_name, email_to).deliver_now
    end

    def self.output_csv_header
      dline = ''
      dline << 'parish (english),'
      dline << 'chapman_code,'
      dline << 'society_which_cover,'
      dline << 'in_gazetteer'
      dline
    end

    def self.output_csv_line(parish, chapman_code, society, in_gaz)
      dline = ''
      dline << "#{parish},"
      dline << "#{chapman_code},"
      dline << "#{society},"
      dline << "#{in_gaz}"
      dline
    end

    def self.output_to_log(log_file, message)
      log_file.puts message.to_s
    end

    def self.open_log_file(log_file_name)
      FileUtils.mkdir_p(File.dirname(log_file_name)) unless File.exist?(log_file_name)
      File.new(log_file_name, 'w')
    end

    def self.read_in_csv_file(csv_filename)
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

    def self.place_in_gaz?(chapman_code, place)
      Freecen2Place.valid_place_name?(chapman_code, place)
    end

    #
    # START
    #

    start_time = Time.now
    userid = args.userid
    record_limit = args.limit.to_i
    csv_filename = "#{Rails.root}/tmp/FREECEN_WELSH_PLACES.CSV"
    processed_total = 0
    missing_total = 0
    file_for_log = "#{Rails.root}/log/check_welsh_places_in_gazetteer_#{start_time.strftime('%Y%m%d%H%M')}.log"
    log_file = open_log_file(file_for_log)
    message = "Starting FreeCEN Check Welsh Places with limit of #{record_limit} records"
    output_to_log(log_file, message)
    p message
    report_csv = ''
    if File.file?(csv_filename)
      _success, welsh_places_array = read_in_csv_file(csv_filename)
      welsh_places_array.each do |place|
        break if processed_total - 1 >= record_limit && processed_total.positive?

        parish_string = place[0].to_s
        chapman__string = place[1].to_s
        society = place[2].to_s
        processed_total += 1

        next if processed_total == 1

        # check for place on freccen2_places
        result = place_in_gaz?(chapman__string, parish_string)

        report_csv  += output_csv_header if report_csv.empty?
        report_csv  += "\n"
        report_csv  += output_csv_line(parish_string, chapman__string, society, result)

        missing_total += 1 unless result
      end
      actual_processed = processed_total - 1 if processed_total.positive?

      report = "Processed #{actual_processed} places - #{missing_total} places not found in Gazetteer."
      email_csv_file(userid, report, report_csv, log_file)
      end_time = Time.now
      run_time = ((end_time - start_time) / 60).round(2).to_s
      message = "Finished FreeCEN Check Welsh Places with limit of records = #{record_limit} (runtime = #{run_time} mins)"
      output_to_log(log_file, message)
      p message
    else
      p "ERROR - #{csv_filename} does not exist in Rails root tmp folder"
    end
  end
end
