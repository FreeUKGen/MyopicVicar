desc "Update VLD Records, and Individual recs and Search recs POB county WAL to WLS"
task :update_vld_recs_POB_wal_to_wls, [:limit, :fix, :email, :restriction] => :environment do |t, args|

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
    if @send_email
      @report_csv += "\n"
      @report_csv += dline
    end
  end

  def self.update_search_record(year, rec, fix, listing)
    rec.set(birth_chapman_code: 'WLS') if fix
    write_csv_line(listing, year, 'SearchRecord', rec._id, rec.chapman_code, 'Birth_chapman_code update WAL -> WLS')
  end

  def self.update_individual_record(year, rec, fix, listing)
    county_update = false
    if rec.verbatim_birth_county == 'WAL'
      rec.set(verbatim_birth_county: 'WLS') if fix
      county_update = true
      write_csv_line(listing, year, 'FreecenIndividual', rec._id, "#{rec.forenames} #{rec.surname}", 'Verbatim_birth_county update WAL -> WLS')
    end
    if rec.birth_county == 'WAL'
      rec.set(birth_county: 'WLS') if fix
      county_update = true
      write_csv_line(listing, year, 'FreecenIndividual', rec._id, "#{rec.forenames} #{rec.surname}", 'Birth_county update WAL -> WLS')
    end
    return unless county_update
  end

  def self.update_vld_entry_record(year, rec, fix, listing)
    county_update = false
    if rec.verbatim_birth_county == 'WAL'
      rec.set(verbatim_birth_county: 'WLS') if fix
      county_update = true
      write_csv_line(listing, year, 'Freecen1VldEntry', rec._id, "#{rec.forenames} #{rec.surname}", 'Verbatim_birth_county update WAL -> WLS')
    end
    if rec.birth_county == 'WAL'
      rec.set(birth_county: 'WLS') if fix
      county_update = true
      write_csv_line(listing, year, 'Freecen1VldEntry', rec._id, "#{rec.forenames} #{rec.surname}", 'Birth_county update WAL -> WLS')
    end
    return unless county_update
  end


  # START


  args.with_defaults(:limit => 1000)
  start_time = Time.current

  @send_email = args.email == 'N' ? false : true
  @email_to = args.email if @send_email == true

  file_for_log = "log/update_vld_recs_POB_WAL_to_WLS_#{start_time.strftime('%Y%m%d%H%M')}.log"
  file_for_listing = "log/update_vld_recs_POB_WAL_to_WLS_#{start_time.strftime('%Y%m%d%H%M')}.csv"
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
  initial_message = "Started Update of VLD Records and associated individual/search records - POB County WAL to WLS with fix = #{fixit} - search record limit = #{record_limit}"
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
      message = "The restriction argument #{args.restriction} is invalid - it must be either a chapman_code eg SOM or a census year eg 1841 or chapman_code followed by a census year eg SOM1841"
      output_to_log(file_for_log, message)
    end
  end

  if args_valid == true
    output_to_log(file_for_log, start_message)
    length_start_message = start_message.length

    search_recs_processed = 0

    hline = 'Year,Collection,Id,Info,Action'
    output_to_csv(file_for_listing, hline)
    @report_csv = hline if @send_email

    Freecen::CENSUS_YEARS_ARRAY.each do |yyyy|
      census_year = yyyy.to_s
      next unless one_year == false || census_year == single_year

      if one_county
        num_search_recs_to_update = SearchRecord.where(record_type: census_year, chapman_code: single_county, birth_chapman_code: 'WAL', freecen_individual_id: {'$ne'=> ''}).count
        message = num_search_recs_to_update.zero? ? "Census Year #{census_year} for #{single_county} has 0 records to process" : "Working on Census Year #{census_year} for #{single_county} - #{num_search_recs_to_update} to process"
      else
        num_search_recs_to_update = SearchRecord.where(record_type: census_year, birth_chapman_code: 'WAL', freecen_individual_id: {'$ne'=> ''}).count
        message = num_search_recs_to_update.zero? ? "Census Year #{census_year} has 0 records to process" : "Working on Census Year #{census_year} - #{num_search_recs_to_update} to process"
      end

      output_to_log(file_for_log, message)
      next if num_search_recs_to_update.zero?

      if one_county
        search_recs_to_update = SearchRecord.where(record_type: census_year, chapman_code: single_county, birth_chapman_code: 'WAL', freecen_individual_id: {'$ne'=> ''})
      else
        search_recs_to_update = SearchRecord.where(record_type: census_year, birth_chapman_code: 'WAL', freecen_individual_id: {'$ne'=> ''})
      end

      if record_limit.positive?
        search_recs_to_update.each do |search_rec|

          update_search_record(census_year, search_rec, fixit, file_for_listing)
          individual_rec = FreecenIndividual.find_by(_id: search_rec.freecen_individual_id)
          if individual_rec.present?
            update_individual_record(census_year, individual_rec, fixit, file_for_listing)
            vld_entry_rec = Freecen1VldEntry.find_by(_id: individual_rec.freecen1_vld_entry_id)
            if vld_entry_rec.present?
              update_vld_entry_record(census_year, vld_entry_rec, fixit, file_for_listing)
            else
              write_csv_line(file_for_listing, census_year, 'SearchRecord', search_rec._id, "ERROR: Freecen1VldEntry record (#{individual_rec.freecen1_vld_entry_id}) not found", 'ERROR')
            end
          else
            write_csv_line(file_for_listing, census_year, 'SearchRecord', search_rec._id, "ERROR: Individual record (#{search_rec.freecen_individual_id}) not found", 'ERROR')
          end

          search_recs_processed += 1
          break if search_recs_processed >= record_limit
        end
      end
      break if search_recs_processed >= record_limit
    end

    end_time = Time.current
    run_time = end_time - start_time

    message = "Finished Update of VLD Records and associated individual/search records - POB County WAL to WLS - run time = #{run_time}"
    output_to_log(file_for_log, message)
    message = "Processed #{search_recs_processed} WAL Search Records records - see log/update_vld_recs_POB_WAL_to_WLS_YYYYMMDDHHMM.csv and .log for output"
    output_to_log(file_for_log, message)

    unless args.email == 'N'
      user_rec = UseridDetail.userid(@email_to).first
      email_message =  "Sending csv file via email to #{user_rec.email_address}"
      output_to_log(file_for_log, email_message)
      subject_line_length = length_start_message - 66
      email_subject = "FREECEN:: #{start_message[66, subject_line_length]}"
      email_body = "Processed #{search_recs_processed} records - update_vld_recs_POB_WAL_to_WLS csv output file attached"
      report_name = "update_vld_recs_POB_WAL_to_WLS_#{start_time.strftime('%Y%m%d%H%M')}.csv"
      UserMailer.report_for_data_manager(email_subject, email_body, @report_csv, report_name, user_rec.email_address).deliver_now
    end
  end
  # end task
end
