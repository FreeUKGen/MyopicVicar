task :finalise_freecen2_scotland_PARMS, [:mode, :limit, :file] => :environment do |t, args|

  require 'chapman_code'
  require 'extract_freecen2_piece_information'
  require 'csv'


  run_mode = args.mode
  input_file = args.file
  lim = args.limit.to_i
  input_file_name = args.file.to_s     # file name excluding extension

  filename_info = input_file.split('_') # get year from filename
  file_year = filename_info[0]

  file_for_output = Rails.root.join('log', "#{input_file_name}_finslize.log")
  FileUtils.mkdir_p(File.dirname(file_for_output))
  output_file = File.new(file_for_output, 'w')
  file_for_messages = Rails.root.join('log', "#{input_file_name}_finalize_messages.csv")
  FileUtils.mkdir_p(File.dirname(file_for_messages))
  message_file = File.new(file_for_messages, 'w')
  file_for_missing_place_names = Rails.root.join('log', "#{input_file_name}_missing_place_names.txt")
  FileUtils.mkdir_p(File.dirname(file_for_missing_place_names))
  missing_places = File.new(file_for_missing_place_names, 'w')


  message_file.puts "Row;Chaoman;Piece;Message;Action Required"
  @missing_place_names = []

  # Print the time etc before start the process
  start_time = Time.now
  run_info = "Started finialise Scotland PARMS at #{start_time} in run mode = #{run_mode} limit = #{lim} input file = #{input_file_name}.csv year = #{file_year}"
  p run_info
  output_file.puts run_info

  rec_count = 0
  # codes = ChapmanCode.remove_codes(ChapmanCode::CODES)
  # codes = codes['Scotland'].values

  input_file = Rails.root.join('tmp', "#{input_file_name}.csv")

  CSV.foreach((input_file), headers: true, col_sep: ';') do |row|

    # header = Chapman;Name;District;Parishes;Piece

    unless rec_count.positive?

      log_info = "First data row processed:  #{row['Chapman']};#{row['Name']};#{row['District']};#{row['Parishes']};#{row['Piece']}"
      p log_info
      output_file.puts log_info

    end

    row_has_issue = false
    break if rec_count > lim

    # Does the Freecen2 Piece already exist

    fc2_piece = Freecen2Piece.find_by(number: row['Piece'])

    if fc2_piece.present?

      # check year

      unless fc2_piece.year == file_year

        row_has_issue = true
        message_file.puts "#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{year}] does not match existing fc2 Piece record year [#{fc2_ piece.year}];#{row_has_issue}"

      end

      # check chapman code

      unless fc2_piece.chapman_code == row['Chapman']

        row_has_issue = true
        message_file.puts "#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{row['Chapman']}] does not match existing fc2 Piece record chapman_code [#{fc2_piece.chapman_code}];#{row_has_issue}"
      end

      # check name

      unless fc2_piece.name == row['Name']

        row_has_issue = true
        message_file.puts "#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{row['Name']}] does not match existing fc2 Piece record name [#{fc2_piece.name}];#{row_has_issue}"

      end

      # check district

      fc2_district = Freecen2District.find_by(chapman_code: row['Chapman'], year: file_year, name: row['District'])

      if fc2_district.present?

        unless fc2_district.id == fc2_piece.freecen2_district_id

          input_dst = "[#{row['District']}]"
          row_has_issue = true
          message_file.puts "#{rec_count + 2};#{row['Chapman']};#{row['Piece']};" + input_dst + " does not match district record linked to existing fc2 pPece [#{fc2_district.name}];#{row_has_issue}"

        end

      else

        row_has_issue = true
        message_file.puts "#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{row['District']}] does not exist as fc2 District record;#{row_has_issue}"

      end

      # check civil parishes

      unless fc2_piece.civil_parish_names == row['Parishes']
        row_has_issue = true

        message_file.puts "#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{row['Parishes']}] do not match existing fc2 Piece record civil parishes [#{fc2_piece.civil_parish_names}];#{row_has_issue}"

      end

      # Report on Has VLD files or has CSV files ?????? unless row has issues
      vld_file_count = fc2_piece.vld_files.count

      fc2_csv_files = FreecenCsvFile.where(freecen2_piece_id: fc2_piece.id).count

      if row_has_issue
        message_file.puts "#{rec_count + 2};#{row['Chapman']};#{row['Piece']};Existing Piece has #{ vld_file_count} linked VLD files and #{fc2_csv_files} linked CSV files;#{row_has_issue}"
      else
        message_file.puts "#{rec_count + 2};#{row['Chapman']};#{row['Piece']};Matches existing fc2 piece - seems ok and has #{ vld_file_count} linked VLD files and #{fc2_csv_files} linked CSV files;#{row_has_issue}"
      end

    else

      # is it a Piece ending with a non-numeric?

      unless row['Piece'][-1, 1].match?(/[[:digit:]]/)

        base_piece_number = row['Piece'][0..-2]
        fc2_piece_base = Freecen2Piece.find_by(number: base_piece_number)
        if fc2_piece_base.present?
          row_has_issue = true
          vld_file_count = fc2_piece_base.vld_files.count
          fc2_csv_files = FreecenCsvFile.where(freecen2_piece_id: fc2_piece_base.id).count
          message_file.puts "#{rec_count + 2};#{row['Chapman']};#{row['Piece']};fc2 Piece does not exist but piece #{base_piece_number} for #{fc2_piece_base.name} does (linked VLD files=#{vld_file_count}, CSV files=#{fc2_csv_files}), please review;#{row_has_issue}"
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
          message_file.puts "#{rec_count + 2};#{row['Chapman']};#{row['Piece']};fc2 Piece does not exist but piece #{base_piece_number} for #{fc2_piece_base.name} does (linked VLD files=#{vld_file_count}, CSV files=#{fc2_csv_files}), please review;#{row_has_issue}"
        end

        # is it a Piece ending with a non-numeric?

        unless base_piece_number[-1, 1].match?(/[[:digit:]]/)

          new_base_piece_number = base_piece_number[0..-2]

          fc2_piece_base = Freecen2Piece.find_by(number: new_base_piece_number)
          if fc2_piece_base.present?
            row_has_issue = true
            vld_file_count = fc2_piece_base.vld_files.count
            fc2_csv_files = FreecenCsvFile.where(freecen2_piece_id: fc2_piece_base.id).count
            message_file.puts "#{rec_count + 2};#{row['Chapman']};#{row['Piece']};fc2 Piece does not exist but piece #{new_base_piece_number} for #{fc2_piece_base.name} does (linked VLD files=#{vld_file_count}, CSV files=#{fc2_csv_files}), please review;#{row_has_issue}"
          end

        end

      end

      # Create New Piece etc.

      action = run_mode == 'UPDATE' ? 'so creating' : 'so will create'

      message_file.puts "#{rec_count + 2};#{row['Chapman']};#{row['Piece']};fc2 Piece does not exist #{action} new fc2 Piece;#{row_has_issue}" unless row_has_issue

      # does the District exist?

      fc2_district = Freecen2District.find_by(chapman_code: row['Chapman'], year: file_year, name: row['District'])

      unless fc2_district.present?

        # check district is recorded as fc2_place

        place_id = ExtractFreecen2PieceInformation.locate_district_place(row['Chapman'], row['District'], row['District'], 'District')

        if place_id.present?

          action = run_mode == 'UPDATE' ? 'so creating' : 'so will create'

          message_file.puts "#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{row['District']}] does not exist as fc2 District record, #{action} new fc2 District record;#{row_has_issue}"

          county_id = County.find_by(chapman_code: row['Chapman']).id if County.find_by(chapman_code: row['Chapman']).present?

          @district_object = Freecen2District.new(name: row['District'], chapman_code: row['Chapman'], county_id: county_id,
                                                  year: file_year, tnaid: "None", freecen2_place_id: place_id)
          result = true
          result = @district_object.save if run_mode == 'UPDATE'
          unless result
            row_has_issue = true
            message_file.puts "#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{row['District']}] does not exist as fc2 District record, error crerating fc2 District record;#{row_has_issue}"
            @output_file.puts "District #{row['Chapman']} #{row['Piece']} #{@district_object} - create error"
            @output_file.puts @district_object.errors.full_messages
            crash
          end

        else

          myname = Freecen2Place.standard_place(row['District'])
          @missing_place_names << "#{myname} a District in | #{row['Chapman']}"
          row_has_issue = true
          message_file.puts "#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{row['District']}] does not exist as fc2 District record and no fc2_place record (Gaz) for District name ;#{row_has_issue}"

        end
      end

      # Do Civil Parishes exist?

      civil_parishes = row['Parishes'].split(',')

      civil_parishes.each do |cp|

        fc2_cp = Freecen2CivilParish.find_by(chapman_code: row['Chapman'], year: file_year, name: cp)

        next if fc2_cp.present?

        # check civil parish is recorded as fc2_place

        myname = Freecen2Place.standard_place(cp)

        cp_place = Freecen2Place.find_by(chapman_code: row['Chapman'], standard_place_name: myname)

        cp_place = Freecen2Place.find_by(:chapman_code => row['Chapman'], "alternate_freecen2_place_names.standard_alternate_name" => myname) unless cp_place.present?

        if cp_place.present?

          action = run_mode == 'UPDATE' ? 'so creating' : 'so will create'

          message_file.puts "#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{cp}] does not exist as fc2 Civil Parish record, #{action} new fc2 Civil Parish record;#{row_has_issue}"

          @civll_parish_object = Freecen2CivilParish.new(name: cp, chapman_code: row['Chapman'],
                                                         year: file_year, freecen2_place_id: cp_place.id)
          result = true
          result = @civll_parish_object.save if run_mode == 'UPDATE'
          unless result
            row_has_issue = true
            message_file.puts "#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{cp}] does not exist as fc2 Civil Parish record, error creating fc2 Civil Parish record;#{row_has_issue}"
            @output_file.puts "Civil Parish #{row['Chapman']} #{row['Piece']} #{@civll_parish_object} - create error"
            @output_file.puts @civil_parish_object.errors.full_messages
            crash
          end

        else

          myname = Freecen2Place.standard_place(cp)
          @missing_place_names << "#{myname} a Civil Parish in | #{row['Chapman']}"
          row_has_issue = true
          message_file.puts "#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{cp}] does not exist as fc2 Civil Parish record and no fc2_place record (Gaz) for Civil Parish Place name ;#{row_has_issue}"

        end

      end

      #  end

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
          message_file.puts "#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{cp}] does not exist as fc2 Civil Parish record, error creating fc2 Piece record;#{row_has_issue}"
          @output_file.puts "Piece #{row['Chapman']} #{row['Piece']} #{fc2piece_object} - create error"
          @output_file.puts @fc2piece_object.errors.full_messages
        end

        # update civil parish records for the piece to have the piece id

        if run_mode == 'UPDATE'

          piece_id = @fc2piece_object.id

          civil_parishes.each do |cp|

            fc2_cp = Freecen2CivilParish.find_by(chapman_code: row['Chapman'], year: file_year, name: cp)
            if fc2_cp.present?
              fc2_cp.update_attribute(:freecen2_piece_id, piece_id)
            else
              message_file.puts "#{rec_count + 2};#{row['Chapman']};#{row['Piece']};[#{cp}] error finding Civil Parish record for updating of fc2 Piece id ;#{row_has_issue}"
            end

          end

        end

      end

    end

    rec_count += 1
    @this_row = "#{row['Chapman']};#{row['Name']};#{row['District']};#{row['Parishes']};#{row['Piece']}"

    break if rec_count > lim

  end

  log_info = "Last data row processed:   #{@this_row}"
  p log_info
  output_file.puts log_info
  output_file.puts"Data rows processed: #{rec_count - 1} at #{Time.now}" unless rec_count.zero?
  run_info = "Process finished - #{@missing_place_names.count} missing place names"
  p run_info
  output_file.puts run_info
  missing_places.puts @missing_place_names
  running_time = Time.now - start_time
  run_info = "Running time #{running_time}s for #{rec_count} input file records"
  p run_info
  output_file.puts run_info
end
