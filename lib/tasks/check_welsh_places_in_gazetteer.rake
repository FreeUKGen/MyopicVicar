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
      dline << 'alternative,'
      dline << 'chapman_code,'
      dline << 'society_which_cover,'
      dline << 'place_in_gazetteer,'
      dline << 'alternative_in_gazetteer'
      dline
    end

    def self.output_csv_line(parish, alternative, chapman_code, society, place_in_gaz, alt_in_gaz)
      dline = ''
      dline << "#{parish},"
      dline << "#{alternative},"
      dline << "#{chapman_code},"
      dline << "#{society},"
      dline << "#{place_in_gaz},"
      dline << "#{alt_in_gaz}"
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
    missing_place_total = 0
    missing_alt_total = 0
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
        alternative_string = place[1].to_s
        chapman__string = place[2].to_s
        society = place[3].to_s
        processed_total += 1

        next if processed_total == 1

        # check for place on freccen2_places
        place_result = ''
        alt_result  = ''
        place_result = place_in_gaz?(chapman__string, parish_string)
        alt_result = place_in_gaz?(chapman__string, alternative_string) if alternative_string.present?

        report_csv  += output_csv_header if report_csv.empty?
        report_csv  += "\n"
        report_csv  += output_csv_line(parish_string, alternative_string, chapman__string, society, place_result, alt_result)

        missing_place_total += 1 unless place_result
        missing_alt_total += 1 unless alt_result
      end
      actual_processed = processed_total - 1 if processed_total.positive?

      report = "Processed #{actual_processed} places - #{missing_place_total} places and #{missing_alt_total} alternative place names not found in Gazetteer."
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
