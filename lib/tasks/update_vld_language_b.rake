desc "Update VLD data language B to WE"
task :update_vld_language_b, [:limit, :fix, :email,:restriction] => :environment do |t, args|

  require 'user_mailer'

  def self.output_to_log(message_file, message)
    message_file.puts message.to_s
    p message.to_s
  end

  def self.output_to_csv(csv_file, line)
    csv_file.puts line.to_s
  end

  def self.write_csv_line(csv_file, year, collection_type, rec_id, info, action)
    dline = ''
    dline << "#{year},"
    dline << "#{collection_type},"
    dline << "#{rec_id},"
    dline << "#{info},"
    dline << action.to_s
    output_to_csv(csv_file, dline)
    return unless @send_email

    @report_csv += "\n"
    @report_csv += dline
  end

  def self.update_individual_record(year, rec, fix, listing)
    retuen unless rec.language == 'B'

    rec.set(language: 'WE') if fix
    write_csv_line(listing, year, 'FreecenIndividual', rec._id, "#{rec.forenames} #{rec.surname}", 'Language update B -> WE')
  end

  def self.update_vld_entry_record(year, rec, fix, listing)
    return unless rec.language  == 'B'

    rec.set(language: 'WE') if fix
    write_csv_line(listing, year, 'Freecen1VldEntry', rec._id, "#{rec.forenames} #{rec.surname}", 'Language update B -> WE')
  end


  # START

  args.with_defaults(:limit => 1000)
  start_time = Time.current

  @send_email = args.email == 'N' ? false : true
  @email_to = args.email if @send_email == true

  file_for_log = "log/update_vld_language_b_#{start_time.strftime('%Y%m%d%H%M')}.log"
  file_for_listing = "log/update_vld_language_b_#{start_time.strftime('%Y%m%d%H%M')}.csv"
  FileUtils.mkdir_p(File.dirname(file_for_log)) unless File.exist?(file_for_log)
  FileUtils.mkdir_p(File.dirname(file_for_listing)) unless File.exist?(file_for_listing)
  file_for_log = File.new(file_for_log, 'w')
  file_for_listing = File.new(file_for_listing, 'w')
  fixit = args.fix.to_s == 'Y'
  record_limit = args.limit.to_i
  args_valid = true
  one_year = false
  single_year = 'XXXX'
  one_county = false
  single_county = 'XXX'
  initial_message = "Started Update of VLD Records language - B to WE with fix = #{fixit} - VLD record limit = #{record_limit}"
  start_message = initial_message
  @report_csv = ''

  if args.restriction.present?
    case args.restriction.length
    when 4
      one_year = true
      single_year = args.restriction.to_s
      start_message = "#{initial_message} - #{single_year} only"
    when 3
      one_county = true
      single_county = args.restriction.to_s
      start_message = "#{initial_message} - #{single_county} only"
    when 7 # NOTE: must be county followed by year
      one_county = true
      single_county = args.restriction.to_s[0, 3]
      one_year = true
      single_year = args.restriction.to_s[3, 4]
      start_message = "#{initial_message} - #{single_county} #{single_year} only"
    else
      args_valid = false
      message = "The restriction argument #{args.restriction} is invalid - it must be either a welsh chapman_code eg AGY or a census year eg 1891 or chapman_code followed by a census year eg AGY1891"
      output_to_log(file_for_log, message)
    end
  end

  if args_valid == true
    output_to_log(file_for_log, start_message)
    length_start_message = start_message.length

    vld_recs_processed = 0

    hline = 'Year,Collection,Id,Info,Action'
    output_to_csv(file_for_listing, hline)
    @report_csv = hline if @send_email

    census_years_with_language = one_year ? [single_year] : %w[1891 1901 1911]

    welsh_counties = one_county ? [single_county] : ChapmanCode::CODES['Wales'].values

    census_years_with_language.each do |yyyy|
      census_year = yyyy.to_s

      next unless one_year == false || census_year == single_year

      welsh_counties.each do |chapman_code|

        num_vld_files_for_county = Freecen1VldFile.where(full_year: census_year, dir_name: chapman_code).count
        message = num_vld_files_for_county.zero? ? "Census Year #{census_year} County #{chapman_code} has 0 VLD files" : "Working on Census Year #{census_year} County #{chapman_code} - #{num_vld_files_for_county} VLD Files"

        output_to_log(file_for_log, message)
        next if num_vld_files_for_county.zero?

        if one_county
          vld_files_to_process = Freecen1VldFile.where(full_year: census_year, dir_name: single_county)
        else
          vld_files_to_process = Freecen1VldFile.where(full_year: census_year)
        end

        if record_limit.positive?
          vld_files_to_process.each do |vld_file|

            vld_entries = Freecen1VldEntry.where(freecen1_vld_file_id: vld_file._id, language: 'B')

            vld_entries.each do |vld_entry|

              update_vld_entry_record(census_year, vld_entry, fixit, file_for_listing)

              individual_rec = FreecenIndividual.find_by(freecen1_vld_entry_id: vld_entry._id)
              if individual_rec.present?
                update_individual_record(census_year, individual_rec, fixit, file_for_listing)
              else
                write_csv_line(file_for_listing, census_year, 'Freecen1VldEntry', vld_entry._id, 'ERROR: Individual record not found', 'ERROR')
              end

              vld_recs_processed += 1
              break if vld_recs_processed >= record_limit

            end
            break if vld_recs_processed >= record_limit

          end
        end
        break if vld_recs_processed >= record_limit

      end
      break if vld_recs_processed >= record_limit

    end

    end_time = Time.current
    run_time = end_time - start_time

    message = "Update of VLD Records and associated FreeCen_Individual records - B to WE - run time = #{run_time}"
    output_to_log(file_for_log, message)
    message = "Updated #{vld_recs_processed} VLD Records records - see log/update_vld_language_b_YYYYMMDDHHMM.csv and .log for output"
    output_to_log(file_for_log, message)

    unless args.email == 'N'
      user_rec = UseridDetail.userid(@email_to).first
      email_message = "Sending csv file via email to #{user_rec.email_address}"
      output_to_log(file_for_log, email_message)
      subject_line_length = length_start_message - 7
      email_subject = "FREECEN:: #{start_message[7, subject_line_length]}"
      email_body = "Updated #{vld_recs_processed} records - update_vld_language_b_YYYYMMDDHHMM csv output file attached"
      report_name = "update_vld_language_b_#{start_time.strftime('%Y%m%d%H%M')}.csv"
      UserMailer.report_for_data_manager(email_subject, email_body, @report_csv, report_name, user_rec.email_address).deliver_now
    end
  end
  # end task
end
