desc "Update Search Records, VLD data and CSV data OVB to OVF"
task :update_search_recs_ovb_to_ovf, [:limit, :fix, :year] => :environment do |t, args|

  args.with_defaults(:limit => 1000)
  start_time = Time.current

  file_for_log = "log/update_search_recs_ovb_to_ovf_#{start_time.strftime('%Y%m%d%H%M')}.log"
  file_for_listing = "log/update_search_recs_ovb_to_ovf_#{start_time.strftime('%Y%m%d%H%M')}.csv"
  FileUtils.mkdir_p(File.dirname(file_for_log)) unless File.exist?(file_for_log)
  FileUtils.mkdir_p(File.dirname(file_for_listing)) unless File.exist?(file_for_listing)
  file_for_log = File.new(file_for_log, 'w')
  file_for_listing = File.new(file_for_listing, 'w')
  fixit = args.fix.to_s == 'Y'
  record_limit = args.limit.to_i
  one_year = args.year.present? ? true : false
  single_year = args.year.present? ? args.year.to_s : 'XXXX'

  year_restriction = one_year ? " - restricted to year #{single_year}" : ' - all years'
  message = "Started Update of Search Records and associated VLD/CSV records - OVB to OVF with fix = #{fixit} - search record limit = #{record_limit}#{year_restriction}"
  output_to_log(file_for_log, message)

  search_recs_processed = 0

  hline = 'Year,Collection,Id,Info,Action'
  output_to_csv(file_for_listing, hline)

  Freecen::CENSUS_YEARS_ARRAY.each do |yyyy|
    census_year = yyyy.to_s
    next unless one_year == false || census_year == single_year

    num_search_recs_to_update = SearchRecord.where(record_type: census_year, birth_chapman_code: 'OVB').count
    message = num_search_recs_to_update.zero? ? "Census Year #{census_year} has 0 records to process" : "Working on Census Year #{census_year} - #{num_search_recs_to_update} to process"
    output_to_log(file_for_log, message)
    next if num_search_recs_to_update.zero?

    search_recs_to_update = SearchRecord.where(record_type: census_year, birth_chapman_code: 'OVB')
    if record_limit.positive?
      search_recs_to_update.each do |search_rec|

        update_search_record(census_year, search_rec, fixit, file_for_listing)

        if search_rec.freecen_csv_entry_id.present?
          csv_entry_rec = FreecenCsvEntry.find_by(_id: search_rec.freecen_csv_entry_id)
          if csv_entry_rec.present?
            update_csv_entry_record(census_year, csv_entry_rec, fixit, file_for_listing)
          else
            write_csv_line(file_for_listing, 'SearchRecord', rec._id, "ERROR: FreecenCsvEntry record (#{search_rec.freecen_csv_entry_id}) not found")
          end
        elsif search_rec.freecen_individual_id.present?
          individual_rec = FreecenIndividual.find_by(_id: search_rec.freecen_individual_id)
          if individual_rec.present?
            update_individual_record(census_year, individual_rec, fixit, file_for_listing)
            vld_entry_rec = Freecen1VldEntry.find_by(_id: individual_rec.freecen1_vld_entry_id)
            if vld_entry_rec.present?
              update_vld_entry_record(census_year, vld_entry_rec, fixit, file_for_listing)
            else
              write_csv_line(file_for_listing, 'SearchRecord', rec._id, "ERROR: Freecen1VldEntry record (#{individual_rec.freecen1_vld_entry_id}) not found")
            end
          else
            write_csv_line(file_for_listing, 'SearchRecord', rec_id, "ERROR: Individual record (#{search_rec.freecen_individual_id}) not found")
          end
        end

        search_recs_processed += 1
        break if search_recs_processed >= record_limit
      end
    end
    break if search_recs_processed >= record_limit
  end

  end_time = Time.current
  run_time = end_time - start_time

  message = "Finished Update of Search Records and associated VLD/CSV records - OVB to OVF - run time = #{run_time}"
  output_to_log(file_for_log, message)
  message = "Processed #{search_recs_processed} OVB Search Records records - see log/update_search_recs_ovb_to_ovf_YYYYMMDDHHMM.csv and .log for output"
  output_to_log(file_for_log, message)

  # end task
end

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
end

def self.update_search_record(year, rec, fix, listing)
  rec.set(birth_chapman_code: 'OVF') if fix
  write_csv_line(listing, year, 'SearchRecord', rec._id, rec.chapman_code, 'Birth_chapman_code update OVB -> OVF')
end

def self.update_csv_entry_record(year, rec, fix, listing)
  county_update = false
  if rec.verbatim_birth_county == 'OVB'
    rec.set(verbatim_birth_county: 'OVF') if fix
    county_update = true
    write_csv_line(listing, year, 'FreecenCSVEntry', rec._id, "#{rec.piece_number} #{rec.forenames} #{rec.surname}", 'Verbatim_birth_county update OVB -> OVF')
  end
  if rec.birth_county == 'OVB'
    rec.set(birth_county: 'OVF') if fix
    county_update = true
    write_csv_line(listing, year, 'FreecenCSVEntry', rec._id, "#{rec.piece_number} #{rec.forenames} #{rec.surname}", 'Birth_county update OVB -> OVF')
  end
  return unless county_update

  return if rec.nationality.present?

  rec.set(nationality: 'British') if fix
  write_csv_line(listing, year, 'FreecenCSVEntry', rec._id, "#{rec.piece_number} #{rec.forenames} #{rec.surname}", 'Nationality update -> British')
end

def self.check_notes_for_british(notes)
  note_update = 'none'
  unless notes.present? && notes.downcase.include?('british')
    note_update = notes.present? && notes.length.positive? ? "#{notes} British" : 'British'
  end
  note_update
end

def self.update_individual_record(year, rec, fix, listing)
  county_update = false
  if rec.verbatim_birth_county == 'OVB'
    rec.set(verbatim_birth_county: 'OVF') if fix
    county_update = true
    write_csv_line(listing, year, 'FreecenIndividual', rec._id, "#{rec.forenames} #{rec.surname}", 'Verbatim_birth_county update OVB -> OVF')
  end
  if rec.birth_county == 'OVB'
    rec.set(birth_county: 'OVF') if fix
    county_update = true
    write_csv_line(listing, year, 'FreecenIndividual', rec._id, "#{rec.forenames} #{rec.surname}", 'Birth_county update OVB -> OVF')
  end
  return unless county_update

  addition_to_note = check_notes_for_british(rec.notes)
  return if addition_to_note == 'none'

  rec.set(notes: addition_to_note) if fix
  write_csv_line(listing, year, 'FreecenIndividual', rec._id, "#{rec.forenames} #{rec.surname}", "Notes update -> #{addition_to_note}")
end

def self.update_vld_entry_record(year, rec, fix, listing)
  county_update = false
  if rec.verbatim_birth_county == 'OVB'
    rec.set(verbatim_birth_county: 'OVF') if fix
    county_update = true
    write_csv_line(listing, year, 'Freecen1VldEntry', rec._id, "#{rec.forenames} #{rec.surname}", 'Verbatim_birth_county update OVB -> OVF')
  end
  if rec.birth_county == 'OVB'
    rec.set(birth_county: 'OVF') if fix
    county_update = true
    write_csv_line(listing, year, 'Freecen1VldEntry', rec._id, "#{rec.forenames} #{rec.surname}", 'Birth_county update OVB -> OVF')
  end
  return unless county_update

  addition_to_note = check_notes_for_british(rec.notes)
  return if addition_to_note == 'none'

  rec.set(notes: addition_to_note) if fix
  write_csv_line(listing, year, 'Freecen1VldEntry', rec._id, "#{rec.forenames} #{rec.surname}", "Notes update -> #{addition_to_note}")
end
