desc 'Automatic validation of VLD POB data'
task :vld_auto_validate_pob, [:chapman_code, :vld_file_name, :userid, :limit, :fix] => :environment do |_t, args|

  require 'user_mailer'

  def self.output_to_log(message_file, message)
    message_file.puts message.to_s
    p message.to_s
  end

  def self.output_to_csv(csv_file, line)
    csv_file.puts line.to_s
  end

  def self.write_csv_line(csv_file, id, dwelling_number, sequence_in_household, verbatim_birth_county, verbatim_birth_place, birth_county, birth_place, pob_valid, notes)
    dline = ''
    dline << "#{id},"
    dline << "#{dwelling_number},"
    dline << "#{sequence_in_household},"
    dline << "#{verbatim_birth_county},"
    dline << "#{verbatim_birth_place},"
    dline << "#{birth_county},"
    dline << "#{birth_place},"
    dline << "#{pob_valid},"
    dline << "#{notes},"
    output_to_csv(csv_file, dline)
    @report_csv += "\n"
    @report_csv += dline
  end

  # START

  args.with_defaults(:limit => 50000)
  start_time = Time.current

  file_name = args.vld_file_name[0, args.vld_file_name.length - 4]

  file_for_log = "log/vld_auto_validate_pob_#{args.chapman_code}_#{file_name}_#{args.userid}_#{start_time.strftime('%Y%m%d%H%M')}.log"
  FileUtils.mkdir_p(File.dirname(file_for_log)) unless File.exist?(file_for_log)
  file_for_log = File.new(file_for_log, 'w')

  args_valid = true

  chapman_code = args.chapman_code
  if chapman_code.blank?
    args_valid = false
    message = 'The chapman code is blank/missing'
    output_to_log(file_for_log, message)
  end

  vld_file_name = args.vld_file_name
  if vld_file_name.blank?
    args_valid = false
    message = 'The vld file name argument is blank/missing'
    output_to_log(file_for_log, message)
  end

  vld_file = Freecen1VldFile.where(dir_name: chapman_code, file_name: vld_file_name).first
  if vld_file.blank?
    args_valid = false
    message = "The vld file name argument #{args.vld_file_name} is invalid - vld file does not exist"
    output_to_log(file_for_log, message)
  end

  userid = args.userid
  if userid.blank?
    args_valid = false
    message = 'The userid argument is missing'
    output_to_log(file_for_log, message)
  end

  user = UseridDetail.where(userid: userid).first
  if user.blank?
    args_valid = false
    message = "The userid argument #{args.userid} is invalid - user does not exist"
    output_to_log(file_for_log, message)
  end

  record_limit = args.limit.to_i
  fixit = args.fix.to_s == 'Y'

  if args_valid == true
    file_for_listing = "log/vld_auto_validate_pob_#{vld_file.dir_name}_#{file_name}_#{userid}_#{start_time.strftime('%Y%m%d%H%M')}.csv"
    FileUtils.mkdir_p(File.dirname(file_for_listing)) unless File.exist?(file_for_listing)
    file_for_listing = File.new(file_for_listing, 'w')

    message = "Automatic Validation of VLD POB data for #{vld_file.dir_name} - #{vld_file_name} with fix = #{fixit} for user #{userid}"
    start_message = "#{start_time} Started: #{message}"
    @report_csv = ''

    output_to_log(file_for_log, start_message)

    hline = 'VldEntryId,Dwelling_number,Sequence_in_household,Verbatim_birth_county,Verbatim_birth_place,Birth_county,Birth_place,POB_valid,Notes'
    output_to_csv(file_for_listing, hline)
    @report_csv = hline

    vld_entries = Freecen1VldEntry.where(freecen1_vld_file_id: vld_file.id)
    num_pob_valid = 0
    num_individuals = 0

    vld_entries.each do |vld_entry|
      next if FreecenIndividual.where(freecen1_vld_entry_id: vld_entry.id).count.zero? # IE not an individual

      break if num_individuals >= record_limit

      num_individuals += 1

      if vld_entry.pob_valid.present? && vld_entry.pob_valid == true # IE POB already set to VALID
        num_pob_valid += 1
      else

        place_valid = false

        if vld_entry.birth_place == 'UNK'
          reason = 'Automatic update of birth place UNK to hyphen'
          if fixit
            vld_entry.add_freecen1_vld_entry_edit(userid, reason, vld_entry.verbatim_birth_county, vld_entry.verbatim_birth_place, vld_entry.birth_county, '-')
            vld_entry.update_attributes(birth_place: '-')
            Freecen1VldEntry.update_linked_records_pob(vld_entry._id, vld_entry.verbatim_birth_county, vld_entry.verbatim_birth_place, vld_entry.birth_county, '-')
          end
          write_csv_line(file_for_listing, vld_entry.id, vld_entry.dwelling_number, vld_entry.sequence_in_household, vld_entry.verbatim_birth_county, vld_entry.verbatim_birth_place, vld_entry.birth_county, vld_entry.birth_place, 'N/A', reason)
        end

        place_valid = Freecen1VldEntry.valid_pob?(vld_file, vld_entry)

        vld_entry.update_attributes(pob_valid: place_valid) if fixit
        if place_valid == false
          write_csv_line(file_for_listing, vld_entry.id, vld_entry.dwelling_number, vld_entry.sequence_in_household, vld_entry.verbatim_birth_county, vld_entry.verbatim_birth_place, vld_entry.birth_county, vld_entry.birth_place, place_valid, '')
        end

        num_pob_valid += 1 if place_valid

      end

      p "#{num_individuals} individuals processed" if (num_individuals / 1000).to_i * 1000 == num_individuals

      # vld entries loop
    end

    message_recs = "#{vld_file.file_name} individuals / valid POB recs = #{num_individuals} / #{num_pob_valid}"
    output_to_log(file_for_log, message_recs)

  end

  end_time = Time.current
  run_time = end_time - start_time

  if args_valid == true
    end_message = "#{end_time} Finished: #{message} - run time = #{run_time} secs"
    output_to_log(file_for_log, end_message)
    message_processed = "Processed #{vld_file_name} - see log/vld_auto_validate_pob_#{chapman_code}_#{file_name}_#{args.userid}_#{start_time.strftime('%Y%m%d%H%M')}.csv for output"
    output_to_log(file_for_log, message_processed)
    email_message = "Sending email to #{user.email_address}"
    output_to_log(file_for_log, email_message)
    email_subject = "FREECEN:: #{message}"
    email_body = "Processed #{vld_file.dir_name} - #{file_name} - Individuals: #{num_individuals} - POB Valid: #{num_pob_valid}"
    if num_individuals == num_pob_valid
      UserMailer.report_for_data_manager(email_subject, email_body, '', '', user.email_address).deliver_now
    else
      report_name = "vld_auto_validate_pob_#{file_name}_invalid_pobs.csv"
      UserMailer.report_for_data_manager(email_subject, email_body, @report_csv, report_name, user.email_address).deliver_now
    end
  end
  # end task
end
