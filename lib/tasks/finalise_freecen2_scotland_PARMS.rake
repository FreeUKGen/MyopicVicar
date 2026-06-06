task :finalise_freecen2_scotland_PARMS, [:mode, :file, :userid] => :environment do |t, args|

  require 'chapman_code'
  require 'extract_freecen2_piece_information'
  require 'csv'
  require 'user_mailer'


  def self.email_files(userid, year, run_mode, log_file, txt_file, csv_file)
    user_rec = UseridDetail.userid(userid).first
    email_to = user_rec.email_address

    email_subject = "FreeCEN: Finalise Scottish PARMS for year: #{year}, run mode: #{run_mode}"
    email_body = 'See attached files.'
    email_body += "\n"
    log_name = "#{year}_Scottish_PARMS_finalise.log"
    txt_name = "#{year}_Scottish_PARMS_missing_place_names.txt"
    csv_name = "#{year}_Scottish_PARMS_finalise_messages.csv"

    UserMailer.freecen_sct_parms_report(email_subject, email_body, log_file, log_name, txt_file, txt_name, csv_file, csv_name, email_to)
  end


  def self.output_to_log(message)
    p message
    dline = ''
    dline << "#{message}\n"
    dline
  end

  def self.output_to_txt(message)
    dline = ''
    dline << "#{message}\n"
    dline
  end

  def self.output_to_csv(message)
    dline = ''
    dline << "#{message}\n"
    dline
  end

  #
  # START
  #

  run_mode = args.mode
  input_file = args.file
  input_file_name = args.file.to_s     # file name excluding extension

  filename_info = input_file.split('_') # get year from filename
  file_year = filename_info[0]
  file_name = filename_info[1] + '_' + filename_info[2]

  unless file_name == 'Scottish_PARMS'
    run_info = "Invalid input file name #{input_file_name}"
    p run_info
    abort run_info
  end

  email_userid = args.userid
  user_email = UseridDetail.where(userid: email_userid).first
  abort 'Invalid user for userid argument. User not found' unless user_email

  log_file = ''
  message_file = ''
  txt_file = ''

  header = 'Row;Chapman;Piece;Message;Action Required'
  message_file += output_to_csv(header)
  @missing_place_names = []

  # Print the time etc before start the process

  start_time = Time.now
  run_info = "Started finialise Scottish PARMS at #{start_time} in run mode = #{run_mode}, year = #{file_year}, input file = #{input_file_name}.csv"
  log_file += output_to_log(run_info)


  unless file_name == 'Scottish_PARMS'
    run_info = "Invalid input file name #{input_file_name}"
    log_file += output_to_log(run_info)
    abort run_info
  end

  rec_count = 0

  input_file = Rails.root.join('tmp', "#{input_file_name}.csv")

  CSV.foreach((input_file), headers: true, col_sep: ';') do |row|

    # header = Chapman;Name;District;Parishes;Piece

    unless rec_count.positive?

      log_info = "First data row processed:  #{row['Chapman']};#{row['Name']};#{row['District']};#{row['Parishes']};#{row['Piece']}"
      log_file += output_to_log(log_info)

    end

    row_has_issue = false

    # Does the Freecen2 Piece already exist

    fc2_piece = Freecen2Piece.find_by(number: row['Piece'])

    if fc2_piece.present?

      vld_file_count = fc2_piece.vld_files.count

      fc2_csv_files = FreecenCsvFile.where(freecen2_piece_id: fc2_piece.id).count

      # check year

      unless fc2_piece.year == file_year

        row_has_issue = true
        message_file += output_to_csv("#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{year}] does not match existing fc2 Piece record year [#{fc2_ piece.year}];#{row_has_issue}")

      end

      # check chapman code

      unless fc2_piece.chapman_code == row['Chapman']

        row_has_issue = true
        message_file += output_to_csv("#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{row['Chapman']}] does not match existing fc2 Piece record chapman_code [#{fc2_piece.chapman_code}];#{row_has_issue}")
      end

      # check piece name

      unless fc2_piece.name.downcase == row['Name'].downcase

        row_has_issue = true
        message_file += output_to_csv("#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{row['Name']}] does not match existing fc2 Piece record name [#{fc2_piece.name}];#{row_has_issue}")
      end


      # check district

      fc2_districts = Freecen2District.where(chapman_code: row['Chapman'], year: file_year)

      found = false
      if fc2_districts.present?

        fc2_districts.each do |fc2_district|

          found = true if fc2_district.name.downcase == row['District'].downcase
          @district = fc2_district if found == true
          break if found == true

        end

        if found == true

          unless @district.id == fc2_piece.freecen2_district_id

            input_dst = "[#{row['District']}]"
            row_has_issue = true
            message_file += output_to_csv("#{rec_count + 2};#{row['Chapman']};#{row['Piece']};" + input_dst + " does not match district record linked to existing fc2 Piece [#{@district.name}];#{row_has_issue}")

          end

        else

          row_has_issue = true
          message_file += output_to_csv("#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{row['District']}] does not exist as fc2 District record;#{row_has_issue}")

        end

      else

        row_has_issue = true
        message_file += output_to_csv("#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{row['District']}] does not exist as fc2 District record;#{row_has_issue}")

      end

      # check civil parishes

      civil_parish_names_string = fc2_piece.add_update_civil_parish_list

      if civil_parish_names_string.present? && fc2_piece.civil_parish_names.blank?
        fc2_piece.update(civil_parish_names: civil_parish_names_string)
      end

      civil_parish_names_string_for_match = civil_parish_names_string.blank? ? ' ' : civil_parish_names_string
      input_parishes_for_match = row['Parishes'].blank? ? ' ' : row['Parishes']

      unless civil_parish_names_string_for_match.downcase == input_parishes_for_match.downcase

        row_has_issue = true
        message_file += output_to_csv("#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{row['Parishes']}] do not match existing fc2 Piece record civil parishes [#{civil_parish_names_string}];#{row_has_issue}")

      end

      # end

      # Report on has VLD files or has CSV files unless row has issues

      if row_has_issue
        message_file += output_to_csv("#{rec_count + 2};#{row['Chapman']};#{row['Piece']};Existing Piece has #{ vld_file_count} linked VLD files and #{fc2_csv_files} linked CSV files;#{row_has_issue}")
      else
        message_file += output_to_csv("#{rec_count + 2};#{row['Chapman']};#{row['Piece']};Matches existing fc2 piece - seems ok and has #{ vld_file_count} linked VLD files and #{fc2_csv_files} linked CSV files;#{row_has_issue}")
      end

    else

      # **** Piece does not already exist ****

      # is it a Piece ending with a non-numeric?

      unless row['Piece'][-1, 1].match?(/[[:digit:]]/)

        base_piece_number = row['Piece'][0..-2]
        fc2_piece_base = Freecen2Piece.find_by(number: base_piece_number)
        if fc2_piece_base.present?
          row_has_issue = true
          vld_file_count = fc2_piece_base.vld_files.count
          fc2_csv_files = FreecenCsvFile.where(freecen2_piece_id: fc2_piece_base.id).count
          message_file += output_to_csv("#{rec_count + 2};#{row['Chapman']};#{row['Piece']};fc2 Piece does not exist but piece #{base_piece_number} for #{fc2_piece_base.name} does (linked VLD files=#{vld_file_count}, CSV files=#{fc2_csv_files}), please review;#{row_has_issue}")
        end

      end

      # is it a Piece number with leading zero?

      piece_parts = row['Piece'].split('_')

      if piece_parts[1][0,1] == '0'

        piece_parts[1][0] = ''
        base_piece_number = piece_parts[0] + '_' + piece_parts[1]

        fc2_piece_base = Freecen2Piece.find_by(number: base_piece_number)
        if fc2_piece_base.present?
          row_has_issue = true
          vld_file_count = fc2_piece_base.vld_files.count
          fc2_csv_files = FreecenCsvFile.where(freecen2_piece_id: fc2_piece_base.id).count
          message_file += output_to_csv("#{rec_count + 2};#{row['Chapman']};#{row['Piece']};fc2 Piece does not exist but piece #{base_piece_number} for #{fc2_piece_base.name} does (linked VLD files=#{vld_file_count}, CSV files=#{fc2_csv_files}), please review;#{row_has_issue}")
        end

        # is it a Piece ending with a non-numeric?

        unless base_piece_number[-1, 1].match?(/[[:digit:]]/)

          new_base_piece_number = base_piece_number[0..-2]

          fc2_piece_base = Freecen2Piece.find_by(number: new_base_piece_number)
          if fc2_piece_base.present?
            row_has_issue = true
            vld_file_count = fc2_piece_base.vld_files.count
            fc2_csv_files = FreecenCsvFile.where(freecen2_piece_id: fc2_piece_base.id).count
            message_file += output_to_csv("#{rec_count + 2};#{row['Chapman']};#{row['Piece']};fc2 Piece does not exist but piece #{new_base_piece_number} for #{fc2_piece_base.name} does (linked VLD files=#{vld_file_count}, CSV files=#{fc2_csv_files}), please review;#{row_has_issue}")
          end

        end

      end

      # Create New Piece etc.

      action = run_mode == 'UPDATE' ? 'so creating' : 'can create'

      message_file += output_to_csv("#{rec_count + 2};#{row['Chapman']};#{row['Piece']};fc2 Piece does not exist #{action} new fc2 Piece;#{row_has_issue}") unless row_has_issue

      # does the District exist?

      fc2_district = Freecen2District.find_by(chapman_code: row['Chapman'], year: file_year, name: row['District'])

      unless fc2_district.present?

        # check district is recorded as fc2_place

        place_id = ExtractFreecen2PieceInformation.locate_district_place(row['Chapman'], row['District'], row['District'], 'District')

        if place_id.present?

          action = run_mode == 'UPDATE' ? 'so creating' : 'can create'

          message_file += output_to_csv("#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{row['District']}] does not exist as fc2 District record, #{action} new fc2 District record;#{row_has_issue}")

          county_id = County.find_by(chapman_code: row['Chapman']).id if County.find_by(chapman_code: row['Chapman']).present?

          @district_object = Freecen2District.new(name: row['District'], chapman_code: row['Chapman'], county_id: county_id,
                                                  year: file_year, tnaid: 'None', freecen2_place_id: place_id)
          result = true
          result = @district_object.save if run_mode == 'UPDATE'
          unless result
            row_has_issue = true
            message_file += output_to_csv("#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{row['District']}] does not exist as fc2 District record, error crerating fc2 District record;#{row_has_issue}")
            log_info = "District #{row['Chapman']} #{row['Piece']} #{@district_object} - create error"
            log_file += output_to_log(log_info)
            log_info = @district_object.errors.full_messages
            log_file += output_to_log(log_info)
            crash
          end

        else

          myname = Freecen2Place.standard_place(row['District'])
          @missing_place_names << "#{myname} a District in | #{row['Chapman']}"
          row_has_issue = true
          message_file += output_to_csv("#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{row['District']}] does not exist as fc2 District record and no fc2_place record (Gaz) for District name ;#{row_has_issue}")

        end
      end

      # Do Civil Parishes exist?

      civil_parishes = row['Parishes'].split(',')

      civil_parishes.each do |cp|
        fc2_cps = Freecen2CivilParish.where(chapman_code: row['Chapman'], year: file_year)

        cp_found = false
        if fc2_cps.present?

          fc2_cps.each do |cps|
            cp_found = true if cps.name.downcase == cp.downcase
            break if cp_found == true

          end

          next if cp_found == true

          # check civil parish is recorded as fc2_place

          myname = Freecen2Place.standard_place(cp)

          cp_place = Freecen2Place.find_by(chapman_code: row['Chapman'], standard_place_name: myname)

          cp_place = Freecen2Place.find_by(:chapman_code => row['Chapman'], "alternate_freecen2_place_names.standard_alternate_name" => myname) unless cp_place.present?

          if cp_place.present?

            message_file += output_to_csv("#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{cp}] does not exist as fc2 Civil Parish record;#{row_has_issue}")

          else

            myname = Freecen2Place.standard_place(cp)
            @missing_place_names << "#{myname} a Civil Parish in | #{row['Chapman']}"
            row_has_issue = true
            message_file += output_to_csv("#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{cp}] does not exist as fc2 Civil Parish record and no fc2_place record (Gaz) for Civil Parish Place name ;#{row_has_issue}")

          end
        end

      end

      # Create the Piece

      unless row_has_issue

        # Create the Piece

        fc2_district = Freecen2District.find_by(chapman_code: row['Chapman'], year: file_year, name: row['District'])

        proceed = fc2_district.present?

        @fc2piece_object = Freecen2Piece.new(name: row['District'],
                                             number: row['Piece'], year: file_year, freecen2_place_id: fc2_district.freecen2_place_id,
                                             freecen2_district_id: fc2_district.id, civil_parish_names: row['Parishes'],
                                             chapman_code: row['Chapman'], admin_county: row['Chapman']) if proceed
        result = true
        result = @fc2piece_object.save if run_mode == 'UPDATE' && proceed
        unless result
          message_file += output_to_csv("#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{cp}] does not exist as fc2 Civil Parish record, error creating fc2 Piece record;#{row_has_issue}")
          log_info = "Piece #{row['Chapman']} #{row['Piece']} #{fc2piece_object} - create error"
          log_file += output_to_log(log_info)
          log_info = @fc2piece_object.errors.full_messages
          log_file += output_to_log(log_info)
        end

        # update civil parish records for the piece to have the piece id

        if run_mode == 'UPDATE'

          piece_id = @fc2piece_object.id

          civil_parishes.each do |cp|
            fc2_cp = Freecen2CivilParish.find_by(chapman_code: row['Chapman'], year: file_year, name: cp)
            if fc2_cp.present?
              fc2_cp.update_attribute(:freecen2_piece_id, piece_id)
            else
              message_file += output_to_csv("#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{cp}] error finding Civil Parish record for updating of fc2 Piece id ;#{row_has_issue}")
            end
          end

        end

      end

    end

    rec_count += 1
    @this_row = "#{row['Chapman']};#{row['Name']};#{row['District']};#{row['Parishes']};#{row['Piece']}"

  end

  log_info = "Last data row processed:   #{@this_row}"
  log_file += output_to_log(log_info)

  run_info = rec_count.zero? ? "No records processed" : "Data rows processed: #{rec_count - 1} at #{Time.now}"
  log_file += output_to_log(run_info)
  run_info = "Process finished - #{@missing_place_names.count} missing place names"
  log_file += output_to_log(run_info)
  @missing_place_names.each do |place|
    txt_file += output_to_txt(place)
  end
  running_time = Time.now - start_time
  run_info = "Running time #{running_time}s for #{rec_count} input file records"
  log_file += output_to_log(run_info)

  p "Sending email to user #{email_userid}"
  email_files(email_userid, file_year, run_mode, log_file, txt_file, message_file).deliver_now

end
