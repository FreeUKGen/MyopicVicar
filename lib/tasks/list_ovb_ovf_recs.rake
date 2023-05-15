desc "List VLD data and CSV data with POB OVB or OVF"
task :list_ovb_ovf_recs, [:chapman_code] => :environment do |t, args|

  start_time = Time.current

  file_for_log = "log/list_ovb_ovf_recs_#{start_time.strftime('%Y%m%d%H%M')}.log"
  file_for_listing = "log/list_ovb_ovf_recs_#{start_time.strftime('%Y%m%d%H%M')}.csv"
  FileUtils.mkdir_p(File.dirname(file_for_log)) unless File.exist?(file_for_log)
  FileUtils.mkdir_p(File.dirname(file_for_listing)) unless File.exist?(file_for_listing)
  file_for_log = File.new(file_for_log, 'w')
  file_for_listing = File.new(file_for_listing, 'w')
  args_valid = false
  initial_message = 'Started Listing of  VLD/CSV records with POB OVB or OVF'
  start_message = initial_message

  if args.chapman_code.present?
    args_valid = true
    single_county = args.chapman_code.to_s
    start_message = "#{initial_message} - #{single_county} only"
  else
    message = 'The chapman_code parameter is invalid'
    output_to_log(file_for_log, message)
  end

  if args_valid == true
    output_to_log(file_for_log, start_message)

    search_recs_processed = 0

    hline = 'File,census year,folio,schedule,surname,POB Chapman,POB Place,Verbatim POB County,Verbatim POB Place,Nationality,Notes'
    output_to_csv(file_for_listing, hline)

    Freecen::CENSUS_YEARS_ARRAY.each do |yyyy|
      census_year = yyyy.to_s

      num_search_recs_ovb = SearchRecord.where(record_type: census_year, chapman_code: single_county, birth_chapman_code: 'OVB').count
      num_search_recs_ovf = SearchRecord.where(record_type: census_year, chapman_code: single_county, birth_chapman_code: 'OVF').count
      num_search_recs = num_search_recs_ovb + num_search_recs_ovf
      message = num_search_recs.zero? ? "Census Year #{census_year} for #{single_county} has 0 records to process" : "Working on Census Year #{census_year} for #{single_county} - #{num_search_recs} to process"

      output_to_log(file_for_log, message)
      next if num_search_recs.zero?


      search_recs = SearchRecord.where(record_type: census_year, chapman_code: single_county)


      search_recs.each do |search_rec|

        next unless %w[OVB OVF].include?(search_rec.birth_chapman_code)

        get_search_record_info(search_rec)

        if search_rec.freecen_csv_entry_id.present?
          csv_entry_rec = FreecenCsvEntry.find_by(_id: search_rec.freecen_csv_entry_id)
          if csv_entry_rec.present?
            get_csv_entry_info(csv_entry_rec)
          else
            message = "**** CSVEntry record not found - search record #{search_rec.id} - csv entry id #{search_rec.freecen_csv_entry_id}"
            output_to_log(file_for_log, message)
          end
        elsif search_rec.freecen_individual_id.present?
          individual_rec = FreecenIndividual.find_by(_id: search_rec.freecen_individual_id)
          if individual_rec.present?
            get_individual_record_info(individual_rec)
            vld_entry_rec = Freecen1VldEntry.find_by(_id: individual_rec.freecen1_vld_entry_id)
            if vld_entry_rec.present?
              get_vld_entry_record_info(vld_entry_rec)
            else
              message = "**** VLD record not found - search record #{search_rec.id} - csv entry id #{search_rec.freecen1_vld_entry_id}"
              output_to_log(file_for_log, message)
            end
          else
            message = "**** Individual record not found - search record #{search_rec.id} - csv entry id #{search_rec.freecen_individual_id}"
            output_to_log(file_for_log, message)
          end
        end

        write_csv_line(file_for_listing) unless @file_for_listing == ''
        search_recs_processed += 1
      end
    end

    end_time = Time.current
    run_time = end_time - start_time

    message = "Finished Listing of  VLD/CSV records with POB OVB or OVF - run time = #{run_time}"
    output_to_log(file_for_log, message)
    message = "Processed #{search_recs_processed} OVB/OVF Search Records records - see list_ovb_ovf_recs_YYYYMMDDHHMM.csv and .log for output"
    output_to_log(file_for_log, message)

  end
  # end task
end

def self.output_to_log(message_file, message)
  message_file.puts message.to_s
  p message.to_s
end

def self.output_to_csv(csv_file, line)
  csv_file.puts line.to_s
end

def self.write_csv_line(csv_file)
  dline = ''
  dline << "#{@file_for_listing},"
  dline << "#{@census_year_for_listing},"
  dline << "#{@folio_for_listing},"
  dline << "#{@schedule_for_listing},"
  dline << "#{@surname_for_listiing},"
  dline << "#{@pob_chapman_for_listing},"
  dline << "#{@pob_place_for_listing},"
  dline << "#{@verbatim_pob_chapman_for_listing},"
  dline << "#{@verbatim_pob_place_for_listing},"
  dline << "#{@nationality_for_listing},"
  dline << "#{@notes_for_listing},"
  output_to_csv(csv_file, dline)
end

def self.get_search_record_info(rec)
  clear_fields_for_listing
  @census_year_for_listing = rec.record_type
end

def self.clear_fields_for_listing
  @census_year_for_listing = ''
  @file_for_listing = ''
  @folio_for_listing = ''
  @schedule_for_listing = ''
  @surname_for_listiing = ''
  @pob_chapman_for_listing = ''
  @pob_place_for_listing = ''
  @verbatim_pob_chapman_for_listing = ''
  @verbatim_pob_place_for_listing = ''
  @nationality_for_listing = ''
  @notes_for_listing = ''
end

def self.get_csv_entry_info(rec)
  if rec.freecen_csv_file_id.present?
    csv_file_rec = FreecenCsvFile.find_by(_id: rec.freecen_csv_file_id)
    @file_for_listing = csv_file_rec.present? ? csv_file_rec.file_name : "****CSV File not found #{rec.freecen_csv_file_id}"
  else
    @file_for_listing = "****CSV File missing for CSV Entry #{rec.id}"
  end
  @folio_for_listing = rec.folio_number
  @schedule_for_listing = rec.schedule_number
  @surname_for_listiing = rec.surname
  @pob_chapman_for_listing = rec.birth_county
  @pob_place_for_listing = rec.birth_place
  @verbatim_pob_chapman_for_listing = rec.verbatim_birth_county
  @verbatim_pob_place_for_listing = rec.verbatim_birth_place
  @nationality_for_listing = rec.nationality
  @notes_for_listing = rec.notes
end

def self.get_individual_record_info(rec)
  if rec.freecen1_vld_file_id.present?
    vld_file_rec = Freecen1VldFile.find_by(_id: rec.freecen1_vld_file_id)
    @file_for_listing = vld_file_rec.present? ? vld_file_rec.file_name : "****VLD File not found #{rec.freecen1_vld_file_id}"
  else
    @file_for_listing = "****VLD File missing for Individual #{rec.id}"
  end
end

def self.get_vld_entry_record_info(rec)
  @folio_for_listing = rec.folio_number
  @schedule_for_listing = rec.schedule_number
  @surname_for_listiing = rec.surname
  @pob_chapman_for_listing = rec.birth_county
  @pob_place_for_listing = rec.birth_place
  @verbatim_pob_chapman_for_listing = rec.verbatim_birth_county
  @verbatim_pob_place_for_listing = rec.verbatim_birth_place
  @nationality = ''
  @notes_for_listing = rec.notes
end
