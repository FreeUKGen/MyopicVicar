class FreecenParms
  require 'freecen_constants'
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  field :userid, type: String # person who uploaded it
  field :year, type: String
  field :chapman, type: String
  field :parms_type, type: String # dat, csv, or csv_fc2 (includes lat/long)
  field :file_name,type: String
  field :process,type: String, default: "Process tonight"
  field :warnings, type: Array, default: []
# BWB mongoid error  field :errors, type: Array, default: []
  field :locked, type: Boolean, default: false
  # files are stored in Rails.application.config.datafiles_changeset
  #validate :csvfile_already_exists, on: :create
#  mount_uploader :freecen_parms_upl, FreecenParmsUploader

  #load a freecen1 ctyPARMS.CSV file and check the format, returning a list
  #of errors or warnings about non-conformance to the defined file format.
  #Errors mean a file is invalid and should be rejected and fixed.
  #Warnings may not be cause for rejection.  They should be reviewed by the
  #user to determine whether to accept or reject the file.
  def self.load_parms_csv(pathname)
    #make sure a csv file, year and county are valid and match filename
    raw_file = File.read(pathname)
    parm_lines = CSV.parse(raw_file)
    parse_result = parse_parms_csv_lines(parm_lines)
    return parse_result
    # {'chapman'=>chapman, 'year'=>year, 'errors'=>parm_errors, 'warnings'=>parm_warnings, 'info'=>parm_info, 'add'=>parm_additions, 'change'=>parm_changes, 'delete'=>parm_deletions, 'data'=>parm_lines}
  end

  def self.get_parms_lines_changes(parms_lines_old, parms_lines_new)
    
  end

  def self.parse_parms_csv_lines(parm_lines, fc1_errors=true)
    parm_info = []
    parm_warnings = []
    parm_errors = []
    parm_additions = []
    parm_changes = []
    parm_deletions = []
    blank_lines = []
    long_lines = []

    if parm_lines.present? && parm_lines.length > 1 && parm_lines[0].length >= 3
      #header row has 3 columns:
      # [0] initials of uploader (up to 4 characters)
      # [1] total number of lines in the csv file
      # [2] CTY1841 (county chapman code and the 4-digit census year)
      initials = parm_lines[0].to_s
      numlines = parm_lines[0][1].to_i
      chapman = parm_lines[0][2].to_s[0,3]
      year = parm_lines[0][2].to_s[3,4]
      if initials.length > 4
        parm_warnings << "The initials of the uploader in the first column of the csv header are #{initials.length} characters long, but the limit is 4."
      end
      if (parm_lines.length) != numlines
        parm_warnings << "The csv header line specifies #{numlines} as the number of lines in the file, but #{parm_lines.length} were read from the csv (including the header). This system counts the number of lines in the file, and ignores the number in the header.  The old system depends on the header number being correct, so if you are going to use this csv with PARMSBLD for the old system, make sure to correct it."
      end
      unless Freecen::CENSUS_YEARS_ARRAY.include? year
        parm_errors << "Invalid year specified in header. Third column of .csv header should have the county chapman code and year, for example 'CON1841' for Cornwall 1841."
      end
      unless ChapmanCode.values.include? chapman
        parm_errors << "Invalid chapman code specified in header. Third column of .csv header should have the county chapman code and year, for example 'CON1841' for Cornwall 1841."
      end
    else
      parm_errors << "Invalid ctyPARMS.CSV file. Please make sure it is a .CSV (not a .DAT file), and that it is properly formatted as a .CSV, has the correct 3-column header, and uses a UTF-8 compatible character set."
    end

    unless parm_errors.length > 0
      parm_lines.each_with_index do |line, idx|
        next if 0==idx
        if 0==line.length
          blank_lines << idx
          next
        end
        if line.length > 8
          long_lines << idx
          next
        end
        if line.length < 8
          short_lines << idx
          next
        end
        #need to warn for FC1 if any non-ascii input characters found
        #need to warn for FC1 all length restrictions
        length_lims = [4,4,20,20,8,24,3,1]
        line.each_with_index do |col, colidx|
          if col.present? && col.to_s.length > length_lims[colidx].to_i
            parm_errors << "line #{idx}, column #{colidx+1}: length greater than (#{length_lims[colidx].to_i})"
          end
        end
        if line[7] != 'a' && line[7] != 'b'
          parm_errors << "line #{idx}, column 7: should be a single character, either 'a' or 'b'"
        end
        if line[2].blank? && line[3].blank?
          parm_errors << "line #{idx}: columns 3 and 4 are both blank."
        end
        if line[2].to_s.length>0 && line[7]=='b'
          parm_errors << "line #{idx} column 3 is specified for a 'b' record"
        end
        if line[3].to_s.length>0 && line[7]=='a'
          parm_errors << "line #{idx} column 4 is specified for an 'a' record"
        end
        #verify that the number field isn't 0 or empty (or nil) or too big
        if 0 == line[0].to_i || line[0].to_i > 9999
          parm_errors << "line #{idx} column 1 should be a non-zero number (1-9999)"
        end
      end
    end
    if blank_lines.length > 0
      parm_warnings << "#{blank_lines.length} blank lines were detected (the first is line #{blank_lines[0]}). This system ignores blanks lines, but the PARMSBLD conversion program from the old system may not ignore blank lines and may create erroneous piece/place entries from empty lines if this csv is used as input to PARMSBLD."
    end
    if long_lines.length > 0
      parm_warnings << "#{long_lines.length} lines were detected with more than 8 columns (the first is line #{long_lines[0]}). This system expects exactly 8 columns (additional columns are ignored). The PARMSBLD conversion program from the old system does not ignore extra columns, so they will cause problems if you use this csv as input to that program."
    end
    if short_lines.length > 0
      parm_errors << "#{short_lines.length} lines were detected with less than 8 columns (the first is line #{short_lines[0]}). This system expects 8 columns of data for each line."
    end


    return {'chapman'=>chapman, 'year'=>year, 'errors'=>parm_errors, 'warnings'=>parm_warnings, 'info'=>parm_info, 'add'=>parm_additions, 'change'=>parm_changes, 'delete'=>parm_deletions, 'data'=>parm_lines}
  end

  #this function converts a FreeCen1 parms.dat string into ctyPARMS.CSV format
  # (the inverse operation of PARMSBLD.BAS). This is for convenience and debug
  # purposes only.  No error checking is done. The result is a hash including
  # the resulting csv string, csv array of line arrays, list of errors, and
  # list of warnings
  def self.parms_csv_and_errors_from_parms_dat(parms_dat_string)
    csv_lines = []
    csv_string = ''
    errors = []
    numlines = (parms_dat_string / 64).to_i
    if numlines != parms_dat_string / 64.0
      errors[errors.length] = "Invalid parms.dat input- length must be a multiple of 64 characters."
    else
      [0..numlines-1].each do |i|
        line = parms_dat_string[i*64, 64]
        a_or_b = line[63]
        csv_lines[i] = []
        csv_lines[i][0] = line[0,4].strip
        csv_lines[i][0].lstrip!('0') if 0==i
        csv_lines[i][1] = line[4,4].strip
        csv_lines[i][1].lstrip!('0') if 0==i
        if 'a'==a_or_b || 0==i
          csv_lines[i][2] = line[8,20].strip
        elsif 'b'==a_or_b
          csv_lines[i][3] = line[8,20].strip
        else
          errors << "Line #{i} does not specify a or b record. Assuming b."
          csv_lines[i][3] = line[8,20].strip
          a_or_b = 'b'
        end
        errors << "Line #{i} columns 3 and 4 both empty" if csv_lines[i][2].blank? && csv_lines[i][3].blank? && 0!=i
        csv_lines[i][4] = [28,8].strip
        csv_lines[i][5] = [36,24].strip
        csv_lines[i][6] = [60,3].strip
        csv_lines[i][7] = a_or_b.strip
        line.each_with_index do |col,colidx| #replace '' with nil
          csv_lines[i][colidx] = nil if csv_lines[i][colidx].blank?
        end
      end
      csv_string = CSV.generate do |csv|
        #csv << header_line
        csv_lines.each do |line|
          csv << line
        end
      end
    end
    return {'csv_lines'=>csv_lines, 'csv_string'=>csv_string,'errors'=>errors}
  end

  def self.parms_dat_from_parms_csv_lines(parms_lines)
    out = ''
    parms_lines.each_with_index do |line, idx|
      line.each_with_index do |data, col|
        line[col] = '' if data.nil? #use empty strings (instead of nils) below
      end
      #csv col 1 (but index in line[index] is 0-based)
      aa = line[0].to_s.rjust(4,'0')[0, 4]
      #col 2
      bb = line[1].to_s.rjust(4,'0')[0, 4]
      bb = '    ' if "0000"==bb
      #col 3 (output only if a record, otherwise use col 4)
      cc = line[2].to_s.ljust(20,' ')[0, 20] if 0==idx || 'a'==line[7]
      #col 4 (output col 4 only if b record, output col 3 if a record)
      cc = line[3].to_s.ljust(20,' ')[0, 20] if 'b'==line[7]
      #col 5
      ee = line[4].to_s.ljust(8,' ')[0,8]
      #col 6
      ff = line[5].to_s.ljust(24,' ')[0,24]
      #col 7
      gg = line[6].to_s.ljust(3,' ')[0,3]
      #col 8
      hh = line[7].to_s.ljust(1,' ')[0,1]
      out += "#{aa}#{bb}#{cc}#{ee}#{ff}#{gg}#{hh}"
    end
    out
  end


  def self.generate_parms_dat(year, chapman_code)
    csv_lines = generate_parms_csv(year, chapman_code, false)
    return nil if csv_lines.nil?
    return parms_dat_from_parms_csv_lines(csv_lines)
  end

  def self.generate_parms_csv(year, chapman_code, convert_to_string=true)
    return nil unless Freecen::CENSUS_YEARS_ARRAY.include? year
    return nil unless ChapmanCode.values.include? chapman_code
    data_lines = []
    num_entries = 0
    is_scotland = ('SCS'==chapman_code||ChapmanCode::CODES['Scotland'].values.include?(chapman_code)) ? true : false
    prev_piece_num = -1
    prev_suffix = nil
    prev_film_num = nil
    prev_fc1_filename = nil
    FreecenPiece.where(year: year, chapman_code: chapman_code).asc(:year, :piece_number, :suffix, :district_name, :film_number, :subplaces_sort).each do |piece|
      if is_scotland
        part_num = 0
        part_num = piece.parish_number % 10 if piece.parish_number > 0
        part_num_with_piece = part_num*1000 + piece.piece_number
        # "a" record
        unless prev_piece_num==piece.piece_number && prev_suffix==piece.suffix && prev_film_num==piece.film_number
          pn = "%04d" % piece.piece_number
          data_lines << [pn, pn, piece.district_name, nil,
                         piece.film_number, nil, piece.suffix,'a']
        end
        # "b" records
        piece.subplaces.each do |subplace|
          pn = "%04d" % part_num_with_piece
          data_lines << [pn, pn, nil, subplace['name'],
                         piece.freecen1_filename, nil, piece.suffix,'b']
        end
      else # England / Wales
        # "a" record
        unless prev_piece_num==piece.piece_number && prev_suffix==piece.suffix && prev_film_num==piece.film_number
          data_lines << [piece.piece_number, nil, piece.district_name, nil,
                         piece.film_number, nil, nil, 'a']
        end
        # "b" records
        piece.subplaces.each do |subplace|
          data_lines << [piece.piece_number, nil, nil, subplace['name'],
                         nil, nil, nil, 'b']
        end
      end
      prev_piece_num = piece.piece_number
      prev_suffix = piece.suffix
      prev_film_num = piece.film_number
      prev_fc1_filename = piece.freecen1_filename
    end
    header_line = ['FC2a',data_lines.length + 1,"#{chapman_code}#{year}"]
    data_lines.unshift(header_line)

    if convert_to_string
      csv_string = CSV.generate do |csv|
        #csv << header_line
        data_lines.each do |line|
          csv << line
        end
      end
      return csv_string
    end
    return data_lines
  end


end
