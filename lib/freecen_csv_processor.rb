# -*- coding: utf-8 -*-
class FreecenCsvProcessor
  # This class processes a file or files of CSV records.
  #It converts them into entries and stores them in the freereg1_csv_entries     collection
  require 'csv'
  require 'email_veracity'
  require 'text'
  require 'unicode'
  require 'chapman_code'
  require "#{Rails.root}/app/models/freecen_csv_file"
  require "#{Rails.root}/app/models/freecen_csv_entry"
  require 'record_type'
  require 'register_type'
  require 'digest/md5'
  require 'get_files'
  require "#{Rails.root}/app/models/userid_detail"
  require 'freecen_validations'
  require 'freecen_constants'
  #:create_search_records has values create_search_records or no_search_records
  #:type_of_project has values waiting, range or individual
  #:force_rebuild causes all files to be processed
  #:file_range

  # normally run by the rake task build:freereg_new_update[create_search_records,individual,no,userid/filename] or
  # build:freereg_new_update[create_search_records,waiting,no,a-9] or
  # build:freereg_new_update[create_search_records,range,no,a]


  # It uses FreecenCsvProcessor as a class
  # The main entry point is activate_project to set up an instance of FreecenCsvProcessor to communication with the userid and the manager
  # and control the flow
  # CsvFiles gets the files to be processed
  # We then cycle through a single file in CsvFile
  # CsvFile has a_single_file_process method that controls the ingest and processing of the data from the file
  # through methods contained in CsvRecords and CsvRecord.
  # CsvRecords looks after the extraction of the header information including the new DEF header which is used
  # to permit different CsvFile field structures. It also extracts the data @data_lines.
  # CsvRecord is used to convert the csvrecord into a freereg1_csv_entry

  # note each class inherits from its superior

  #:message_file is the log file where system and processing messages are written
  attr_accessor :freecen_files_directory, :create_search_records, :type_of_project, :force_rebuild, :info_messages, :no_pob_warnings,
    :file_range, :message_file, :member_message_file, :project_start_time, :total_records, :total_files, :total_data_errors, :flexible, :line_num

  def initialize(arg1, arg2, arg3, arg4, arg5, arg6)
    @create_search_records = arg1
    @file_range = arg4
    @force_rebuild = arg3
    @freecen_files_directory = Rails.application.config.datafiles
    @message_file = define_message_file
    @project_start_time = Time.now
    @total_data_errors = 0
    @total_files = 0
    @total_records = 0
    @type_of_project = arg2
    @flexible = arg5 == 'Traditional' ? false : true
    @type_of_processing = arg6
    @info_messages = @type_of_processing == 'Information' ? true : false
    @no_pob_warnings = @type_of_processing == 'No POB Warnings' ? true : false
    @error_messages_only = @type_of_processing == 'Error' ? true : false
    EmailVeracity::Config[:skip_lookup] = true
    @line_num = 0
  end

  def self.activate_project(create_search_records, type, force, range, type_of_field, type_of_processing)
    force, create_search_records = FreecenCsvProcessor.convert_to_bolean(create_search_records, force)
    @project = FreecenCsvProcessor.new(create_search_records, type, force, range, type_of_field, type_of_processing)
    @project.write_log_file("Started freecen csv file processor project. #{@project.inspect} using website #{Rails.application.config.website}. <br>")

    @csvfiles = CsvFiles.new(@project)
    success, files_to_be_processed = @csvfiles.get_the_files_to_be_processed
    if !success || (files_to_be_processed.present? && files_to_be_processed.length.zero?)
      @project.write_log_file('processing terminated as we have no records to process. <br>')
      return
    end
    @project.write_log_file("#{files_to_be_processed.length}\t files selected for processing. <br>")
    files_to_be_processed.each do |file_name|
      begin
        @hold_name = file_name
        @csvfile = CsvFile.new(@hold_name, @project)
        success, @records_processed, @data_errors = @csvfile.a_single_csv_file_process
        if success
          #p "processed file"
          @project.total_records = @project.total_records + @records_processed unless @records_processed.nil?
          @project.total_data_errors = @project.total_data_errors + data_errors unless @data_errors
          @project.total_files = @project.total_files + 1
        else
          #p "failed to process file"
          @csvfile.clean_up_physical_files_after_failure(@records_processed)
          @csvfile.communicate_failure_to_member(@records_processed)
          # @project.communicate_to_managers(@csvfile) if @project.type_of_project == "individual"
        end
      rescue CSV::MalformedCSVError => e
        @project.write_messages_to_all("We were unable to process the file possibly due to an invalid structure or character.<p>", true)
        @project.write_messages_to_all("#{e.message}", true)
        @project.write_log_file("#{e.backtrace.inspect}")
        @records_processed = e.message
        @csvfile.clean_up_physical_files_after_failure(@records_processed)
        @csvfile.communicate_failure_to_member(@records_processed)
      rescue StandardError => e
        if e.message.to_s.include?('Username and Password not accepted')
          p 'Email error'
          @records_processed = e.message
          @csvfile.clean_up_physical_files_after_failure(@records_processed)
        else
          @project.write_messages_to_all("#{e.message}", true)
          @project.write_messages_to_all("#{e.backtrace.inspect}", true)
          message = 'The CSVProcessor crashed please provide the following information to your coordinator to send to the System Administrators'
          @project.write_messages_to_all(message, true)
          @records_processed = e.message
          @csvfile.clean_up_physical_files_after_failure(@records_processed)
          @csvfile.communicate_failure_to_member(@records_processed)
        end
      ensure
        sleep(100) if Rails.env.production?
      end
    end
    p 'Finished'
  end

  def self.delete_all
    FreecenCsvEntry.destroy_all
    FreecenCsvFile.destroy_all
    SearchRecord.delete_freecen_individual_entries
  end

  def self.qualify_path(path)
    unless path.match(/^\//) || path.match(/:/) # unix root or windows
      path = File.join(Rails.root, path)
    end
    path
  end

  def communicate_to_managers
    records = @total_records
    average_time = records == 0 ? 0 : average_time = (Time.new.to_i - @project_start_time.to_i) * 1000 / records
    write_messages_to_all("Created  #{records} entries at an average time of #{average_time}ms per record at #{Time.new}. <br>", false)
    file = @message_file
    #@message_file.close if @project.type_of_project == "individual"
    user = UseridDetail.where(userid: "Captkirk").first
    UserMailer.update_report_to_freereg_manager(file, user).deliver_now
  end

  def self.convert_to_bolean(create_search_records, force)
    create_search_records = create_search_records == 'create_search_records' ? true : false
    force = force == 'force_rebuild' ? true : false

    [force, create_search_records]
  end

  def define_message_file
    time = Time.new
    tnsec = time.nsec / 1000
    time = time.to_i.to_s + tnsec.to_s
    file_for_warning_messages = Rails.root.join('log', "freecen_csv_processing_#{time}.txt")
    message_file = File.new(file_for_warning_messages, 'w')
    message_file.chmod(0664)
    message_file
  end

  def write_member_message_file(message)
    message = pob_message(message) if message.present?
    member_message_file.puts message if write_member_message?(message)
  end

  def write_member_message?(message)
    return false if message.blank? || message == '' || (@error_messages_only && (message[0...5] == 'Info:' || message[0...8] == 'Warning:'))

    true
  end

  def pob_message(message)
    message_parts = message.split('<br>')
    if message_parts.length == 1
      new_message = "#{message_parts[0]}<br>" unless @no_pob_warnings && message_parts[0].include?('Warning:') && message_parts[0].include?('Birth')
    else
      message_parts.each do |part|
        next if @error_messages_only && part.include?('Warning:') && part.include?('Birth')

        next if @no_pob_warnings && part.include?('Warning:') && part.include?('Birth')

        if new_message.blank?
          new_message = "#{part}<br>"
        else
          new_message += "#{part}<br>"
        end
      end
    end
    new_message
  end

  def write_messages_to_all(message, no_member_message)
    # avoids sending the message to the member if no_member_message is false
    if message.present?
      if message.is_a?(Array)
        message.each do |mess|
          messa = mess.encode(mess.encoding, universal_newline: true)
          write_log_file(messa)
          write_member_message_file(messa) if no_member_message
        end
      else
        message = message.encode(message.encoding, universal_newline: true)
        write_log_file(message)
        write_member_message_file(message) if no_member_message
      end
    end
  end

  def write_log_file(message)
    message_file.puts message unless message == ''
  end
end

class CsvFiles < FreecenCsvProcessor
  def initialize(project)
    @project = project
  end

  def get_the_files_to_be_processed
    #  p "Getting files"
    case @project.type_of_project
    when 'waiting'
      files = get_the_waiting_files_to_be_processed
    when 'range'
      files = get_the_range_files_to_be_processed
    when 'individual'
      files = get_the_individual_file_to_be_processed
    end
    [true, files]
  end

  # GetFile is a lib task
  def get_the_individual_file_to_be_processed
    # p "individual file selection"
    files = GetFiles.get_all_of_the_filenames(@project.freecen_files_directory, @project.file_range)
    files
  end

  def get_the_range_files_to_be_processed
    # p "range file selection"
    files = GetFiles.get_all_of_the_filenames(@project.freecen_files_directory, @project.file_range)
    files
  end

  def get_the_waiting_files_to_be_processed
    # p "waiting file selection"
    physical_waiting_files = PhysicalFile.waiting.all.order_by(waiting_date: 1)
    files = []
    physical_waiting_files.each do |file|
      files << File.join(@project.freecen_files_directory, file.userid, file.file_name)
    end
    files
  end
end

class CsvFile < CsvFiles

  # initializes variables
  # gets information on the file to be processed

  attr_accessor :header, :list_of_registers, :header_error, :system_error, :data_hold, :dwelling_number, :sequence_in_household,
    :array_of_data_lines, :default_charset, :file, :file_name, :userid, :uploaded_date, :slurp_fail_message, :field_specification,
    :file_start, :file_locations, :data, :unique_locations, :unique_existing_locations, :full_dirname, :chapman_code, :traditional,
    :all_existing_records, :total_files, :total_records, :total_data_errors, :total_header_errors, :place_id, :civil_parish, :census_fields,
    :enumeration_district, :petty_sessional_division, :county_court_district, :ecclesiastical_parish, :where_census_taken, :ward, :parliamentary_constituency, :poor_law_union, :police_district,
    :sanitary_district, :special_water_district, :scavenging_district, :special_lighting_district, :school_board, :folio, :page, :year,
    :piece, :schedule, :folio_suffix, :schedule_suffix, :total_errors, :total_warnings, :total_info, :header_line, :validation

  def initialize(file_location, project)
    @project = project
    @file_location = file_location
    standalone_filename = File.basename(@file_location)
    @full_dirname = File.dirname(@file_location)
    parent_dirname = File.dirname(@full_dirname)
    user_dirname = @full_dirname.sub(parent_dirname, '').gsub(File::SEPARATOR, '')
    @all_existing_records = {}
    @array_of_data_lines = Array.new { Array.new }
    @data = {}
    @default_charset = 'UTF-8'
    @file_locations = {}
    @file_name = standalone_filename
    @file_start =  nil
    @uploaded_date = Time.new
    @uploaded_date = File.mtime(@file_location) if File.exist?(@file_location)
    @header_error = []
    @header = {}
    @header[:digest] = Digest::MD5.file(@file_location).hexdigest if File.exist?(@file_location)
    @header[:file_name] = standalone_filename # do not capitalize filenames
    @header[:userid] = user_dirname
    @header[:uploaded_date] = @uploaded_date
    server = SoftwareVersion.extract_server(Socket.gethostname)
    @software_version = SoftwareVersion.server(server).app('freecen').control.first
    @header[:software_version] = ''
    @header[:search_record_version] = ''
    @header[:software_version] = @software_version.version if @software_version.present?
    @header[:search_record_version] = @software_version.last_search_record_version if @software_version.present?
    @place_id = nil
    @slurp_fail_message = nil
    @userid = user_dirname
    @total_data_errors = 0
    @total_files = 0
    @total_header_errors = 0
    @total_records = 0
    @year = ''
    @piece = nil
    @chapman_code = ''
    @civil_parish = ''
    @enumeration_district = ''
    @petty_sessional_division = ''
    @county_court_district = ''
    @ecclesiastical_parish = ''
    @where_census_taken = ''
    @ward = ''
    @parliamentary_constituency = ''
    @poor_law_union = ''
    @police_district = ''
    @sanitary_district = ''
    @special_water_district = ''
    @scavenging_district = ''
    @special_lighting_district = ''
    @school_board = ''
    @folio = 0
    @folio_suffix = nil
    @page = 0
    @schedule = 0
    @schedule_suffix = nil
    @total_errors = 0
    @total_warnings = 0
    @total_info = 0
    @dwelling_number = 0
    @sequence_in_household = 0
    @field_specication = {}
    @census_fields = []
    @traditional = 2
    @header_line = ''
    @validation = false
  end

  def a_single_csv_file_process
    # p "single csv file"
    success = true
    @project.member_message_file = define_member_message_file
    @file_start = Time.new
    p "FREECEN:CSV_PROCESSING: Started on the file #{@header[:file_name]} for #{@header[:userid]} at #{@file_start}"
    @project.write_log_file("******************************************************************* <br>")
    @project.write_messages_to_all("Started on the file #{@header[:file_name]} for #{@header[:userid]} at #{@file_start}.<br>", true)
    success, message = ensure_processable? unless @project.force_rebuild
    # p "finished file checking #{message}. <br>"
    return [false, message] unless success

    success, message, @year, @piece, @census_fields = extract_piece_year_from_file_name(@file_name)
    @chapman_code = @piece.chapman_code if @piece.present?
    @project.write_messages_to_all(message, true) unless success
    @project.write_messages_to_all("Working on #{@piece.name} for #{@year}, in #{@piece.chapman_code}.<br>", true) if success
    return [false, message] unless success

    @file = FreecenCsvFile.find_by(file_name: @file_name, chapman_code: @chapman_code, userid: @userid)
    @validation = @file.validation if @file.present?

    success, message = slurp_the_csv_file
    # p "finished slurp #{success} #{message}"
    return [false, message] unless success

    @csv_records = CsvRecords.new(@array_of_data_lines, self, @project)

    success, reduction = @csv_records.process_header_fields
    return [false, "initial @data_lines made no sense extracted #{message}. <br>"] unless success || [1, 2].include?(reduction)

    success, records_processed, data_records = @csv_records.extract_the_data(reduction)
    return [success, "Data not extracted #{records_processed}. <br>"] unless success

    success, freecen_csv_file = write_freecen_csv_file if success
    return [success, "File not saved. <br>"] unless success

    success = write_freecen_csv_entries(data_records, freecen_csv_file) if success

    success, message = clean_up_supporting_information(records_processed) if success
    return [success, "clean up failed #{message}. <br>"] unless success

    # p "finished clean up
    time = ((Time.new.to_i - @file_start.to_i) * 1000) / records_processed unless records_processed.zero?
    @project.write_messages_to_all("Created  #{records_processed} entries at an average time of #{time}ms per record at #{Time.new}. <br>",true)

    success, message = communicate_file_processing_results
    p "finished com"
    return [success, "communication failed #{message}. <br>"] unless success

    [true, records_processed, @total_data_errors]
  end

  def extract_piece_year_from_file_name(file_name)
    if FreecenValidations.valid_piece?(file_name)
      success = true
      message = ''
      year, piece, fields = Freecen2Piece.extract_year_and_piece(file_name, @chapman_code)
      actual_piece = Freecen2Piece.where(year: year, number: piece.upcase).first
      chapman_code = actual_piece.chapman_code if actual_piece.present?
      if (%w[1911].include?(year) && %w[ALD GSY JSY SRK].include?(chapman_code))
        # adjust census for channel islands
        fields = (%w[1911].include?(year) && %w[ALD GSY JSY SRK].include?(chapman_code)) ? Freecen::CEN2_CHANNEL_ISLANDS_1911 : Freecen::CEN2_1911
      end
      if actual_piece.blank?
        message = "Error: there is no piece #{piece.upcase} in #{year} for #{file_name} in the database}. <br>"
        success = false
      end
    else
      message = "Error: File name does not have a valid piece number. It is #{file_name}. Most likely you have forgotten the _ after the series. <br>"
      success = false
    end
    [success, message, year, actual_piece, fields]
  end

  def check_and_set_characterset(code_set, csvtxt)
    # if it looks like valid UTF-8 and we know it isn't
    # Windows-1252 because of undefined characters, then
    # default to UTF-8 instead of Windows-1252
    if code_set.nil? || code_set.empty? || code_set == 'chset'
      # @project.write_messages_to_all("Checking for undefined with #{code_set}",false)
      if csvtxt.index(0x81.chr) || csvtxt.index(0x8D.chr) ||
          csvtxt.index(0x8F.chr) || csvtxt.index(0x90.chr) ||
          csvtxt.index(0x9D.chr)
        # p 'undefined Windows-1252 chars, try UTF-8 default'
        # @project.write_messages_to_all("Found undefined}",false)
        csvtxt.force_encoding('UTF-8')
        code_set = 'UTF-8' if csvtxt.valid_encoding?
        csvtxt.force_encoding('ASCII-8BIT') # convert later with replace
      end
    end
    code_set = self.default_charset if (code_set.blank? || code_set == 'chset')
    code_set = "UTF-8" if (code_set.upcase == "UTF8")
    #Deal with the cp437 code which is IBM437 in ruby
    code_set = "IBM437" if (code_set.upcase == "CP437")
    #Deal with the macintosh instruction in freereg1
    code_set = "macRoman" if (code_set.downcase == "macintosh")
    code_set = code_set.upcase if code_set.length == 5 || code_set.length == 6
    message = "Invalid Character Set detected #{code_set} have assumed Windows-1252. <br>" unless Encoding.name_list.include?(code_set)
    code_set = self.default_charset unless Encoding.name_list.include?(code_set)
    self.header[:characterset] = code_set
    # convert to UTF-8 if we didn't already. If our
    # preference is to fail when invalid characters or
    # undefined characters are found (so we can fix the
    # file or specified encoding) instead of silently
    # replacing bad characters with the undefined character
    # symbol, the two replacement options can be removed
    unless csvtxt.encoding == 'UTF-8'
      csvtxt.force_encoding(code_set)
      self.slurp_fail_message = "the processor failed to convert to UTF-8 from character set #{code_set}. <br>"
      csvtxt = csvtxt.encode('UTF-8', invalid: :replace, undef: :replace)
      self.slurp_fail_message = nil # no exception thrown
    end
    [code_set, message, csvtxt]
  end

  def check_file_exists?
    # make sure file actually exists
    message = "The file #{@file_name} for #{@userid} does not exist. <br>"
    return [true, 'OK'] if File.exist?(@file_location)

    @project.write_messages_to_all(message, true)
    [false, message]
  end

  def check_file_is_not_locked?(batch)
    return [true, 'OK'] if batch.blank?

    return [true, 'OK'] if batch.was_locked || !batch.locked_by_transcriber || !batch.locked_by_coordinator
    message = "The file #{batch.file_name} for #{batch.userid} is already on system and is locked against replacement. <br>"
    @project.write_messages_to_all(message, true)
    [false, message]
  end

  def check_userid_exists?
    message = "The #{@userid} userid does not exist. <br>"
    return [true, 'OK'] if UseridDetail.userid(@userid).first.present?

    @project.write_messages_to_all(message, true)
    [false, message]
  end

  def clean_up_physical_files_after_failure(message)
    batch = PhysicalFile.userid(@userid).file_name(@file_name).first
    return true if batch.blank?

    PhysicalFile.remove_waiting_flag(@userid, @file_name)
    @file.update_attributes(was_locked: false, locked_by_transcriber: true) if @file.present? && @file.was_locked
    batch.delete unless message.to_s.include?('is already on system and is locked against replacement')
  end

  def clean_up_supporting_information(records_processed)
    if records_processed.blank? || records_processed.zero?
      batch = PhysicalFile.userid(@userid).file_name(@file_name).first
      return true if batch.blank?

      batch.delete
    else
      @file.update_attributes(was_locked: false, locked_by_transcriber: true) if @file.was_locked
      physical_file_clean_up_on_success
    end
    true
  end

  def communicate_failure_to_member(message)
    file = @project.member_message_file
    file.close
    copy_file_name = "#{@header[:file_name]}.txt"
    to = File.join(@full_dirname, copy_file_name)
    FileUtils.cp_r(file, to, remove_destination: true)
    UserMailer.batch_processing_failure(file, @userid, @file_name).deliver_now unless @project.type_of_project == "special_selection_1" ||  @project.type_of_project == "special_selection_2"
    true
  end

  def communicate_file_processing_results
    p "communicating success"
    file = @project.member_message_file
    file.close
    copy_file_name = "#{@header[:file_name]}.txt"
    to = File.join(@full_dirname, copy_file_name)
    FileUtils.cp_r(file, to, remove_destination: true)
    UserMailer.batch_processing_success(file, @header[:userid], @header[:file_name]).deliver_now unless @project.type_of_project == "special_selection_1" ||  @project.type_of_project == "special_selection_2"
    true
  end

  def define_member_message_file
    time = Time.new
    tnsec = time.nsec / 1000
    time = time.to_i.to_s + tnsec.to_s
    file_for_member_messages = Rails.root.join('log', "#{userid}_processed_#{@file_name}_#{time}.txt").to_s
    member_message_file = File.new(file_for_member_messages, 'w')
    member_message_file
  end


  def determine_if_utf8(csvtxt)
    # check for BOM and if found, assume corresponding
    # unicode encoding (unless invalid sequences found),
    # regardless of what user specified in column 5 since it
    # may have been edited and saved as unicode by coord
    # without updating col 5 to reflect the new encoding.
    # p "testing for BOM"
    if !csvtxt.nil? && csvtxt.length > 2
      if csvtxt[0].ord == 0xEF && csvtxt[1].ord == 0xBB && csvtxt[2].ord == 0xBF
        # p "UTF-8 BOM found"
        # @project.write_messages_to_all("BOM found",false)
        csvtxt = csvtxt[3..-1] # remove BOM
        code_set = 'UTF-8'
        self.slurp_fail_message = 'BOM detected so using UTF8. <br>'
        csvtxt.force_encoding(code_set)
        if !csvtxt.valid_encoding?
          # @project.write_messages_to_all("Not really a UTF8",false)
          # not really a UTF-8 file. probably was edited in
          # software that added BOM to beginning without
          # properly transcoding existing characters to UTF-8
          code_set = 'ASCII-8BIT'
          csvtxt.encode('ASCII-8BIT')
          csvtxt.force_encoding('ASCII-8BIT')
          # @project.write_messages_to_all("Not really ASCII-8BIT",false) unless csvtxt.valid_encoding?
        else
          self.slurp_fail_message = 'Using UTF8. <br>'
          csvtxt = csvtxt.encode('utf-8', undef: :replace)
        end
      else
        code_set = nil
        # No BOM
        self.slurp_fail_message = nil
      end
    else
      # No BOM
      self.slurp_fail_message = nil
      code_set = nil
    end
    # @project.write_messages_to_all("Code set #{code_set}", false)

    [code_set, csvtxt]
  end

  def ensure_processable?
    success, message = check_file_exists?
    success, message = check_userid_exists? if success
    batch = FreecenCsvFile.userid(@userid).file_name(@file_name).first if success
    success, message = check_file_is_not_locked?(batch) if success
    return [true, 'OK'] if success

    return [false, message] unless success
  end

  def extract_the_array_of_lines(csvtxt)
    #now get all the data
    self.slurp_fail_message = "the CSV parser failed. The CSV file might not be formatted correctly. <br>"
    @array_of_data_lines = CSV.parse(csvtxt, { row_sep: "\r\n", skip_blanks: true })
    #remove zzz fields and white space
    @array_of_data_lines.each do |line|
      line.each_index    {|x| line[x] = line[x].gsub(/zzz/, ' ').gsub(/\s+/, ' ').strip unless line[x].nil? }
    end
    @slurp_fail_message = nil # no exception thrown
    true
  end

  def get_codeset_from_header(code_set, csvtxt)
    @slurp_fail_message = "CSV parse failure on first line. <br>"
    first_data_line = CSV.parse_line(csvtxt)
    @slurp_fail_message = nil # no exception thrown
    if !first_data_line.nil? && first_data_line[0] == "+INFO" && !first_data_line[5].nil?
      code_set_specified_in_csv = first_data_line[5].strip
      # @project.write_messages_to_all("Detecting character set found #{code_set_specified_in_csv}",false)
      if !code_set.nil? && code_set != code_set_specified_in_csv
        message = "ignoring #{code_set_specified_in_csv} specified in col 5 of .csv header because #{code_set} Byte Order Mark (BOM) was found in the file"
        # @project.write_messages_to_all(message,false)
      else
        # @project.write_messages_to_all("using #{code_set_specified_in_csv}",false)
        code_set = code_set_specified_in_csv
      end
    end
    return code_set
  end

  def physical_file_clean_up_on_success
    #p "physical file clean up on success"
    batch = PhysicalFile.userid(@userid).file_name(@file_name).first
    if batch.blank?
      batch = PhysicalFile.new(userid: @userid, file_name: @file_name, base: true, base_uploaded_date: Time.new)
      batch.save
    end
    if @project.create_search_records
      # we created search records so its in the search database database
      batch.update(file_processed: true, file_processed_date: Time.new, waiting_to_be_processed: false, waiting_date: nil)
    else
      #only checked for errors so file is not processed into search database
      batch.update(file_processed: false, file_processed_date: nil, waiting_to_be_processed: false, waiting_date: nil)
    end
  end

  def slurp_the_csv_file
    # p "starting the slurp"
    # read entire .csv as binary text (no encoding/conversion)
    success = true
    csvtxt = File.open(@file_location, 'rb', encoding: 'ASCII-8BIT:ASCII-8BIT') { |f| f.read }
    @project.write_messages_to_all('Empty file', true) if csvtxt.blank?
    return false if csvtxt.blank?

    code, csvtxt = determine_if_utf8(csvtxt)
    # code = get_codeset_from_header(code, csvtxt)
    code, message, csvtxt = self.check_and_set_characterset(code, csvtxt)
    csvtxt = self.standardize_line_endings(csvtxt)
    success = self.extract_the_array_of_lines(csvtxt)

    [success, message]
    #we ensure that processing keeps going by dropping out through the bottom
  end

  def standardize_line_endings(csvtxt)
    xxx = csvtxt.gsub(/\r?\n/, "\r\n").gsub(/\r\n?/, "\r\n")
    return xxx
  end

  def write_freecen_csv_file
    if @file.blank?
      @file = FreecenCsvFile.new(file_name: @file_name, userid: @userid, chapman_code: @chapman_code, year: @year, freecen2_piece_id: @piece.id )
    else
      FreecenCsvEntry.collection.delete_many(freecen_csv_file_id: @file._id)
    end
    @file.uploaded_date = @uploaded_date
    @file.software_version = @software_version
    @file.total_records = @total_records.to_i
    @file.total_errors = @total_errors
    @file.total_warnings = @total_warnings
    @file.flexible = @project.flexible
    @file.total_info = @total_info
    @file.traditional = @traditional
    @file.validation = @validation
    @file.processed = @project.create_search_records
    @file.header_line = @header_line
    @file.field_specification = @field_specification
    @file.freecen2_district_id = @piece.freecen2_district_id
    success = @piece.save

    p @file
    [success, @file]
  end

  def write_freecen_csv_entries(records, file)
    civil_parishes = list_civil_parishes(file)
    enumeration_districts = {}
    documents = []
    records.each do |record|
      record[:piece_number] = record[:piece].number
      record[:piece] = nil
      record = record.delete_if {|key, value| key == :piece }
      record = record.delete_if {|key, value| key == :field_specification }
      record = adjust_case(record)
      record[:freecen2_civil_parish_id] = locate_civil_parish(record, civil_parishes)
      enumeration_districts[record[:civil_parish]] = [] if enumeration_districts[record[:civil_parish]].blank?
      enumeration_districts[record[:civil_parish]] << record[:enumeration_district] unless enumeration_districts[record[:civil_parish]].include?(record[:enumeration_district])
      record[:freecen_csv_file_id] = file.id
      documents << record
    end
    FreecenCsvEntry.collection.insert_many(documents)
    file.update_attributes(total_records: records.length, enumeration_districts: enumeration_districts) if records.present?
    true
  end
end

def list_civil_parishes(file)
  civil_parishes = {}
  if file.freecen2_piece.present?
    file.freecen2_piece.freecen2_civil_parishes.each do |parish|
      civil_parishes[parish.name.downcase] = parish.id
    end
  end
  civil_parishes
end

def locate_civil_parish(record, civil_parishes)
  id = nil
  record_parish = record[:civil_parish].downcase if record[:civil_parish].present?
  id = civil_parishes[record_parish] if record_parish.present?
  id
end

def adjust_case(record)
  record[:surname] = FreecenCsvEntry.myupcase(record[:surname])
  record[:forenames] = FreecenCsvEntry.mytitlieze(record[:forenames])
  record[:birth_place] = FreecenCsvEntry.mytitlieze(record[:birth_place])
  record[:verbatim_birth_place] =  FreecenCsvEntry.mytitlieze(record[:verbatim_birth_place])
  record[:civil_parish] = FreecenCsvEntry.mytitlieze(record[:civil_parish])
  record[:disability] = FreecenCsvEntry.mytitlieze(record[:disability])
  record[:petty_sessional_division] = FreecenCsvEntry.mytitlieze(record[:petty_sessional_division])
  record[:county_court_district] = FreecenCsvEntry.mytitlieze(record[:county_court_district])
  record[:ecclesiastical_parish] = FreecenCsvEntry.mytitlieze(record[:ecclesiastical_parish])
  record[:father_place_of_birth] = FreecenCsvEntry.mytitlieze(record[:father_place_of_birth])
  record[:house_or_street_name] = FreecenCsvEntry.mytitlieze(record[:house_or_street_name])
  record[:nationality] = record[:nationality].capitalize if record[:nationality].present?
  record[:occupation] = FreecenCsvEntry.mytitlieze(record[:occupation])
  record[:occupation_category] = FreecenCsvEntry.myupcase(record[:occupation_category])
  record[:employment] = FreecenCsvEntry.mytitlieze(record[:employment])
  record[:place_of_work] = FreecenCsvEntry.mytitlieze(record[:place_of_work])
  record[:at_home] = FreecenCsvEntry.myupcase(record[:at_home])
  record[:marital_status] = FreecenCsvEntry.myupcase(record[:marital_status])
  record[:parliamentary_constituency] = FreecenCsvEntry.mytitlieze(record[:parliamentary_constituency])
  record[:police_district] = FreecenCsvEntry.mytitlieze(record[:police_district])
  record[:poor_law_union] = FreecenCsvEntry.mytitlieze(record[:poor_law_union])
  record[:read_write] = FreecenCsvEntry.mytitlieze(record[:read_write])
  record[:relationship] = FreecenCsvEntry.mytitlieze(record[:relationship])
  record[:religion] = FreecenCsvEntry.mytitlieze(record[:religion])
  record[:roof_type] = record[:roof_type].capitalize if record[:roof_type].present?
  record[:sanitary_district] = FreecenCsvEntry.mytitlieze(record[:sanitary_district])
  record[:scavenging_district] =FreecenCsvEntry.mytitlieze(record[:scavenging_district])
  record[:school_board] = FreecenCsvEntry.mytitlieze(record[:school_board])
  record[:sex] = FreecenCsvEntry.myupcase(record[:sex])
  record[:special_lighting_district] = FreecenCsvEntry.mytitlieze(record[:special_lighting_district])
  record[:special_water_district] = FreecenCsvEntry.mytitlieze(record[:special_water_district])
  record[:ward] = FreecenCsvEntry.mytitlieze(record[:ward])
  record[:where_census_taken] = FreecenCsvEntry.mytitlieze(record[:where_census_taken])
  record[:record_valid] = record[:record_valid].downcase if record[:record_valid].present?
  record
end

class CsvRecords < CsvFile
  require 'freecen_constants'

  attr_accessor :array_of_lines, :data_lines

  def initialize(data_array, csvfile, project)
    @project = project
    @csvfile = csvfile
    @array_of_lines = data_array
    @data_lines = Array.new { Array.new }
  end

  def process_header_fields
    # p 'Getting header'
    reduction = 0
    n = 0
    @project.write_messages_to_all("Error: line #{n} is empty", true) if @array_of_lines[n][0..24].all?(&:blank?)
    return [false, n] if @array_of_lines[n][0..24].all?(&:blank?)

    @project.write_messages_to_all("Error: line #{n} has too many fields", true) if @array_of_lines[n].length > 50
    return [false, n] if @array_of_lines[n].length > 50

    success, message, @csvfile.field_specification, @csvfile.traditional, @csvfile.header_line = line_one(@array_of_lines[n])

    unless success
      @project.write_messages_to_all(message, true)
      return [false, '']
    end

    file = FreecenCsvFile.find_by(userid: @csvfile.userid, file_name: @csvfile.file_name)
    if file.present? && @csvfile.traditional < file.traditional
      message = 'Modern headers are in use on the uploaded file and you are attempting to upload a file with traditional headers. This is not permitted'
      @project.write_messages_to_all(message, true)
      return [false, '']

    end
    if success
      reduction = reduction + 1
    else
      @project.write_messages_to_all(message, true)
      return [success, reduction]
    end
    return [false, 'No lines other that fields'] if @array_of_lines[n + 1].blank?

    success, message = line_two(@array_of_lines[n + 1])
    if success
      reduction = reduction + 1
      @project.write_messages_to_all(message, true)
    end
    [success, reduction]
  end

  def line_one(line)
    if line[0..24].all?(&:present?)
      traditional = extract_traditonal_headers(line)
      success, message, field_specification = extract_field_headers(line, traditional)
    else
      message = 'ERROR: There is a problem with the Header line - a column field name is missing.<br>'
      success = false
    end
    [success, message, field_specification, traditional, line]
  end

  def line_two(line)
    success = false
    if line[0..15].all?(&:blank?)
      @project.write_messages_to_all('Warning: line 2 is empty', true)
      success = true
    elsif line[0].present? && line[0].casecmp?('abcdefghijklmnopqrst')
      message = 'Warning: line 2 old field width specification detected and ignored'
      success = true
    end
    [success, message]
  end

  def extract_traditonal_headers(line)
    if line.length == 25 && line[1].downcase == 'ed'
      traditional = 0
    elsif line.length > 25 && line[1].downcase == 'ed'
      traditional = 1
    else
      traditional = 2
    end
    traditional
  end

  def extract_field_headers(line, traditional)
    line = line
    n = 0
    field_specification = {}
    success = true
    message = ''
    if these_are_these_old_headers?(line)
      line = convert_old_to_modern(line)
    end

    while line[n].present?
      unless %w[pob_valid non_pob_valid].include?(line[n].downcase) && @csvfile.validation
        if Freecen::FIELD_NAMES_CONVERSION.key?(line[n].downcase)
          field_specification[n] = Freecen::FIELD_NAMES_CONVERSION[line[n].downcase]
        else
          success = false
          if %w[pob_valid non_pob_valid].include?(line[n].downcase)
            message += "ERROR: header field #{line[n].downcase} should not be included as the file is not being validated.<br>"
          else
            message += "ERROR: column header at position #{n} is invalid  #{line[n]}.<br>"
          end
        end
      end
      n = n + 1
    end

    if traditional == 2
      @csvfile.census_fields.each do |field|
        next if field == 'language' && (ChapmanCode::CODES['England'].values.member?(@csvfile.chapman_code) || (@csvfile.chapman_code == 'IOM' && %w[1911 1921].exclude?(@csvfile.year)))
        next if field_specification.value?(field)
        success = false
        message += "ERROR: the field #{field} is missing from the #{@csvfile.year} spreadsheet.<br>"
      end
      field_specification.values.each do |value|
        next if %w[deleted_flag record_valid pob_valid non_pob_valid].include?(value) && @csvfile.validation
        next if @csvfile.census_fields.include?(value)
        success = false
        if  %w[deleted_flag record_valid].include?(value)
          message += "ERROR: header field #{value} should not be included as the file is not being validated.<br>"
        else
          message += "ERROR: header field #{value} should not be included it is not part in the spreadsheet for #{@csvfile.year}.<br>"
        end
      end
    end
    [success, message, field_specification, line]
  end

  def these_are_these_old_headers?(line)
    result = false
    result = true if line[0].casecmp?('civil parish') && line[1].casecmp?('ed') && line[4].casecmp?('Schd')
    result
  end

  def convert_old_to_modern(line)
    line[7] = 'xu'
    line[10] = 'xn'
    line[15] = 'xd'
    line[18] = 'xo'
    line[21] = 'xb'
    line
  end

  # This extracts the header and entry information from the file and adds it to the database

  def extract_the_data(skip)
    skip = skip
    success = true
    data_lines = 0
    data_records = []
    @array_of_lines.each_with_index do |line, n|
      next if n < skip

      @project.write_messages_to_all("Warning: line #{n} is empty.<br>", true) if line[0..24].all?(&:blank?)
      next if line[0..24].all?(&:blank?)

      @record = CsvRecord.new(line, @csvfile, @project)
      success, message, result = @record.extract_data_line(n)
      if result[:birth_place_flag].present? || result[:deleted_flag].present? || result[:individual_flag].present? || result[:location_flag].present? ||
          result[:name_flag].present? || result[:occupation_flag].present? || result[:address_flag].present? || result[:deleted_flag].present?
        result[:flag] = true
      else
        result[:flag] = false
      end
      result[:record_valid] = 'true' unless result[:error_messages].present? || result[:warning_messages].present? || result[:flag]
      data_records << result
      @csvfile.total_errors = @csvfile.total_errors + 1 if result[:error_messages].present?
      @csvfile.total_warnings = @csvfile.total_warnings + 1 if result[:warning_messages].present?
      @csvfile.total_info = @csvfile.total_info + 1 if result[:info_messages].present?
      @project.write_messages_to_all(message, true) unless success
      success = true
      data_lines = data_lines + 1
    end
    [success, data_lines, data_records]
  end

  def inform_the_user
    @csvfile.header_error.each do |error|
      @project.write_messages_to_all(error, true)
    end
  end
end

class CsvRecord < CsvRecords
  attr_accessor :data_line, :data_record, :civil_parish, :folio, :page, :dwelling, :individual

  def initialize(data_line, csvfile, project)
    @project = project
    @csvfile = csvfile
    @data_line = data_line
    @data_record = {}
    @data_record[:year] = @csvfile.year
    @data_record[:piece] = @csvfile.piece
    @data_record[:flexible] = @project.flexible
    @data_record[:error_messages] = ''
    @data_record[:warning_messages] = ''
    @data_record[:info_messages] = ''
    @data_record[:pob] = ''
    @data_record[:field_specification] = @csvfile.field_specification
    @data_record[:record_valid] = 'false' unless @csvfile.validation
  end

  def extract_data_line(num)
    @data_record[:record_number] = num + 1
    @data_record[:messages] = @project.info_messages
    @data_record[:pob] = @project.no_pob_warnings
    @data_record[:data_transition] = @csvfile.field_specification[first_field_present]
    @data_record[:record_valid] = 'false'
    @data_record = load_data_record
    process_data_record(@data_record[:data_transition])
    #p  "after processing #{num}"
    #p @data_record
    #crash if num == 100
    [true, ' ', @data_record]
  end

  def first_field_present
    @data_line.each_with_index do |field, n|
      @x = n
      break if field.present?
    end
    @x
  end

  def load_data_record
    @data_record[:field_specification].each_with_index do |(_key, field), n|
      break if field.blank?
      @data_record[field.to_sym] = @data_line[n]
    end
    @data_record
  end

  def process_data_record(record_type)
    case record_type
    when 'enumeration_district', 'civil_parish', 'petty_sessional_division', 'county_court_district', 'ecclesiastical_parish', 'where_census_taken', 'ward', 'parliamentary_constituency',
        'poor_law_union', 'police_district', 'sanitary_district', 'special_water_district', 'scavenging_district', 'special_lighting_district',
        'school_board', 'location_flag'
      extract_location_fields
    when 'folio_number'
      extract_folio_fields
    when 'page_number'
      extract_page_fields
    when 'schedule_number', 'uninhabited_flag', 'house_number', 'house_or_street_name', 'address_flag',
        'walls', 'roof_type', 'rooms', 'rooms_with_windows', 'class_of_house', 'rooms_with_windows'
      extract_dwelling_fields
    else
      extract_individual_fields
    end
  end

  def extract_location_fields
    extract_enumeration_district
    extract_civil_parish
    if  @csvfile.year == '1921'
      extract_petty_sessional_division
      extract_county_court_district
    end
    extract_ecclesiastical_parish unless @csvfile.traditional == 0
    if @csvfile.traditional == 2
      extract_where_census_taken
      extract_ward
      extract_parliamentary_constituency
      extract_poor_law_union
      extract_police_district
      extract_sanitary_district
      extract_special_water_district
      extract_scavenging_district
      extract_special_lighting_district
      extract_school_board
    end
    extract_location_flag
  end

  def extract_enumeration_district
    unless ChapmanCode::CODES['Ireland'].values.member?(@csvfile.chapman_code)
      message, @csvfile.enumeration_district = FreecenCsvEntry.validate_enumeration_district(@data_record, @csvfile.enumeration_district)
      @project.write_messages_to_all(message, true) unless message == ''
    end
  end

  def extract_civil_parish
    message, @csvfile.civil_parish = FreecenCsvEntry.validate_civil_parish(@data_record, @csvfile.civil_parish)
    @project.write_messages_to_all(message, true) unless message == ''
  end

  def extract_petty_sessional_division
    if @csvfile.year == '1921' && (ChapmanCode::CODES['England'].values.member?(@csvfile.chapman_code) || ChapmanCode::CODES['Islands'].values.member?(@csvfile.chapman_code))
      message, @csvfile.county_court_district = FreecenCsvEntry.validate_county_court_district(@data_record, @csvfile.county_court_district)
      @project.write_messages_to_all(message, true) unless message == ''
    end
  end

  def extract_county_court_district
    if @csvfile.year == '1921' && (ChapmanCode::CODES['England'].values.member?(@csvfile.chapman_code) || ChapmanCode::CODES['Islands'].values.member?(@csvfile.chapman_code))
      message, @csvfile.county_court_district = FreecenCsvEntry.validate_county_court_district(@data_record, @csvfile.county_court_district)
      @project.write_messages_to_all(message, true) unless message == ''
    end
  end

  def extract_ecclesiastical_parish
    unless ChapmanCode::CODES['Ireland'].values.member?(@csvfile.chapman_code) || (ChapmanCode::CODES['England'].values.member?(@csvfile.chapman_code) && @csvfile.year == '1841') || (ChapmanCode::CODES['Wales'].values.member?(@csvfile.chapman_code) && @csvfile.year == '1841')
      message, @csvfile.ecclesiastical_parish = FreecenCsvEntry.validate_ecclesiastical_parish(@data_record, @csvfile.ecclesiastical_parish)
      @project.write_messages_to_all(message, true) unless message == ''
    end
  end

  def extract_where_census_taken
    message, @csvfile.where_census_taken = FreecenCsvEntry.validate_where_census_taken(@data_record, @csvfile.where_census_taken)
    @project.write_messages_to_all(message, true) unless message == ''
  end

  def extract_ward
    unless %w[1851].include?(@csvfile.year) || (%w[1841].include?(@csvfile.year) && (ChapmanCode::CODES['Scotland'].values.member?(@csvfile.chapman_code) || ChapmanCode::CODES['England'].values.member?(@csvfile.chapman_code) || ChapmanCode::CODES['Wales'].values.member?(@csvfile.chapman_code)))
      message, @csvfile.ward = FreecenCsvEntry.validate_ward(@data_record, @csvfile.ward)
      @project.write_messages_to_all(message, true) unless message == ''
    end
  end

  def extract_parliamentary_constituency
    message, @csvfile.parliamentary_constituency = FreecenCsvEntry.validate_parliamentary_constituency(@data_record, @csvfile.parliamentary_constituency)
    @project.write_messages_to_all(message, true) unless message == ''
  end

  def extract_poor_law_union
    if ChapmanCode::CODES['Ireland'].values.member?(@csvfile.chapman_code)
      message, @csvfile.poor_law_union = FreecenCsvEntry.validate_poor_law_union(@data_record, @csvfile.poor_law_union)
      @project.write_messages_to_all(message, true) unless message == ''
    end
  end

  def extract_police_district
    if ChapmanCode::CODES['Ireland'].values.member?(@csvfile.chapman_code) || (ChapmanCode::CODES['Scotland'].values.member?(@csvfile.chapman_code) && %w[1871 1881 1891 1901].include?(@csvfile.year))
      message, @csvfile.police_district = FreecenCsvEntry.validate_police_district(@data_record, @csvfile.police_district)
      @project.write_messages_to_all(message, true) unless message == ''
    end
  end

  def extract_sanitary_district
    if (ChapmanCode::CODES['England'].values.member?(@csvfile.chapman_code) && %w[1871 1881 1891].include?(@csvfile.year)) ||
        (ChapmanCode::CODES['Scotland'].values.member?(@csvfile.chapman_code) && @csvfile.year == '1911')
      message, @csvfile.sanitary_district = FreecenCsvEntry.validate_sanitary_district(@data_record, @csvfile.sanitary_district)
      @project.write_messages_to_all(message, true) unless message == ''
    end
  end

  def extract_special_water_district
    if ChapmanCode::CODES['Scotland'].values.member?(@csvfile.chapman_code) && @csvfile.year == '1911'
      message, @csvfile.special_water_district = FreecenCsvEntry.validate_special_water_district(@data_record, @csvfile.special_water_district)
      @project.write_messages_to_all(message, true) unless message == ''
    end
  end

  def extract_scavenging_district
    if ChapmanCode::CODES['Scotland'].values.member?(@csvfile.chapman_code) && @csvfile.year == '1911'
      message, @csvfile.scavenging_district = FreecenCsvEntry.validate_scavenging_district(@data_record, @csvfile.scavenging_district)
      @project.write_messages_to_all(message, true) unless message == ''
    end
  end

  def extract_special_lighting_district
    if ChapmanCode::CODES['Scotland'].values.member?(@csvfile.chapman_code) && @csvfile.year == '1911'
      message, @csvfile.special_lighting_district = FreecenCsvEntry.validate_special_lighting_district(@data_record, @csvfile.special_lighting_district)
      @project.write_messages_to_all(message, true) unless message == ''
    end
  end

  def extract_school_board
    if ChapmanCode::CODES['Scotland'].values.member?(@csvfile.chapman_code) && %w[1881 1891 1901 1911].include?(@csvfile.year)
      message, @csvfile.school_board = FreecenCsvEntry.validate_school_board(@data_record, @csvfile.school_board)
      @project.write_messages_to_all(message, true) unless message == ''
    end
  end

  def extract_location_flag
    message = FreecenCsvEntry.validate_location_flag(@data_record)
    @project.write_messages_to_all(message, true) unless message == ''
    @csvfile.year == '1911' ? extract_dwelling_fields : extract_folio_fields
  end

  def extract_folio_fields
    message, @csvfile.folio, @csvfile.folio_suffix = FreecenCsvEntry.validate_folio(@data_record, @csvfile.folio, @csvfile.folio_suffix)
    @project.write_messages_to_all(message, true) unless message == ''
    extract_page_fields
  end

  def extract_page_fields
    message, @csvfile.page = FreecenCsvEntry.validate_page(@data_record, @csvfile.page)
    @project.write_messages_to_all(message, true) unless message == ''
    extract_dwelling_fields
  end

  def extract_dwelling_fields
    if @data_record[:uninhabited_flag].present? && ['b', 'n', 'u', 'v'].include?(@data_record[:uninhabited_flag].downcase)
      @data_record[:dwelling_number] = @csvfile.dwelling_number + 1
      @csvfile.dwelling_number = @data_record[:dwelling_number]
    elsif @data_record[:house_number].blank? && @data_record[:house_or_street_name].blank? && @data_record[:schedule_number].blank?
      @data_record[:dwelling_number] = @csvfile.dwelling_number
    elsif @data_record[:house_number].blank? && @data_record[:house_or_street_name] == '-' && @data_record[:schedule_number].blank?
      @data_record[:dwelling_number] = @csvfile.dwelling_number
    else
      @data_record[:dwelling_number] = @csvfile.dwelling_number + 1
      @csvfile.dwelling_number = @data_record[:dwelling_number]
      @csvfile.sequence_in_household = 0
    end
    message, @csvfile.schedule, @csvfile.schedule_suffix = FreecenCsvEntry.validate_dwelling(@data_record, @csvfile.schedule, @csvfile.schedule_suffix)
    @project.write_messages_to_all(message, true) unless message == ''
    extract_individual_fields
  end

  def extract_individual_fields
    @data_record[:notes] = '' if @data_record[:notes] =~ /\[see mynotes.txt\]/
    propagate_records

    message = individual_present_when_unoccupied if @data_record[:uninhabited_flag].present? && ['b', 'n', 'u', 'v'].include?(@data_record[:uninhabited_flag].downcase)
    @project.write_messages_to_all(message, true) unless message == ''
    unless @data_record[:uninhabited_flag].present? && ['b', 'n', 'u', 'v'].include?(@data_record[:uninhabited_flag].downcase)

      @data_record[:dwelling_number] = @csvfile.dwelling_number
      @csvfile.sequence_in_household = @csvfile.sequence_in_household + 1
      @data_record[:sequence_in_household] = @csvfile.sequence_in_household
      message = FreecenCsvEntry.validate_individual(@data_record)
      @project.write_messages_to_all(message, true) unless message == ''
    end
    extract_notes_field
  end

  def extract_notes_field
    message = FreecenCsvEntry.validate_notes(@data_record)
    @project.write_messages_to_all(message, true) unless message == ''
  end

  def propagate_records
    data_record[:enumeration_district] = @csvfile.enumeration_district if data_record[:enumeration_district].blank? && data_record[:field_specification].value?('enumeration_district')
    data_record[:civil_parish] = @csvfile.civil_parish if data_record[:civil_parish].blank? && data_record[:field_specification].value?('civil_parish')
    data_record[:petty_sessional_division] = @csvfile.petty_sessional_division if data_record[:petty_sessional_division].blank? && data_record[:field_specification].value?('petty_sessional_division')
    data_record[:county_court_district] = @csvfile.county_court_district if data_record[:county_court_district].blank? && data_record[:field_specification].value?('county_court_district')
    data_record[:ecclesiastical_parish] = @csvfile.ecclesiastical_parish if data_record[:ecclesiastical_parish].blank? && data_record[:field_specification].value?('ecclesiastical_parish')
    data_record[:where_census_taken] = @csvfile.where_census_taken if data_record[:where_census_taken].blank? && data_record[:field_specification].value?('where_census_taken')
    data_record[:ward] = @csvfile.ward if data_record[:ward].blank? && data_record[:field_specification].value?('ward')
    data_record[:parliamentary_constituency] = @csvfile.parliamentary_constituency if data_record[:parliamentary_constituency].blank? && data_record[:field_specification].value?('parliamentary_constituency')
    data_record[:poor_law_union] = @csvfile.poor_law_union if data_record[:poor_law_union].blank? && data_record[:field_specification].value?('poor_law_union')
    data_record[:police_district] = @csvfile.police_district if data_record[:police_district].blank? && data_record[:field_specification].value?('police_district')
    data_record[:sanitary_district] = @csvfile.sanitary_district if data_record[:sanitary_district].blank? && data_record[:field_specification].value?('sanitary_district')
    data_record[:special_water_district] = @csvfile.special_water_district if data_record[:special_water_district].blank? && data_record[:field_specification].value?('special_water_district')
    data_record[:scavenging_district] = @csvfile.scavenging_district if data_record[:scavenging_district].blank? && data_record[:field_specification].value?('scavenging_district')
    data_record[:special_lighting_district] = @csvfile.special_lighting_district if data_record[:special_lighting_district].blank? && data_record[:field_specification].value?('special_lighting_district')
    data_record[:school_board] = @csvfile.school_board if data_record[:school_board].blank? && data_record[:field_specification].value?('school_board')
    data_record[:folio_number] = @csvfile.folio.to_s + @csvfile.folio_suffix.to_s if data_record[:folio_number].blank? && data_record[:field_specification].value?('folio_number')
    data_record[:page_number] = @csvfile.page if data_record[:page_number].blank? && data_record[:field_specification].value?('page_number')
  end

  def individual_present_when_unoccupied
    individual_present = false
    individual_present = true if @data_record[:surnane].present? || @data_record[:forename].present? || @data_record[:sex].present? || @data_record[:sex].present?
    if individual_present
      message = "ERROR: line #{@data_record[:record_number]} has information for an individual in a vacant dwelling.<br>" if ['b', 'n', 'u'].include?(@data_record[:uninhabited_flag].downcase)
      message = "Warning: line #{@data_record[:record_number]} has information for an individual who is away visiting.<br>" if @data_record[:uninhabited_flag].downcase == 'v'
      @data_record[:error_messages] += message if ['b', 'n', 'u'].include?(@data_record[:uninhabited_flag].downcase)
      @data_record[:warning_messages] += message if @data_record[:uninhabited_flag].downcase == 'v'
    else
      message = ''
    end
    message
  end
end
