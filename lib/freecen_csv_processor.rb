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
  attr_accessor :freecen_files_directory, :create_search_records, :type_of_project, :force_rebuild, :info_messages,
    :file_range, :message_file, :member_message_file, :project_start_time, :total_records, :total_files, :total_data_errors, :flexible

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
    @flexible = arg5
    @type_of_processing = arg6
    @info_messages = @type_of_processing == 'Check(Info)' ? true : false
    EmailVeracity::Config[:skip_lookup] = true
  end

  def self.activate_project(create_search_records, type, force, range, type_of_field, type_of_processing)
    force, create_search_records = FreecenCsvProcessor.convert_to_bolean(create_search_records, force)
    @flexible = type_of_field == 'Traditional' ? false : true
    @project = FreecenCsvProcessor.new(create_search_records, type, force, range, @flexible, type_of_processing)
    @project.write_log_file("Started freecen csv file processor project. #{@project.inspect} using website #{Rails.application.config.website}. <br>")

    @csvfiles = CsvFiles.new(@project)
    success, files_to_be_processed = @csvfiles.get_the_files_to_be_processed
    if !success || (files_to_be_processed.present? && files_to_be_processed.length.zero?)
      @project.write_log_file('processing terminated as we have no records to process. <br>')
      return
    end
    @project.write_log_file("#{files_to_be_processed.length}\t files selected for processing. <br>")
    files_to_be_processed.each do |file_name|
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
        @csvfile.communicate_failure_to_member(@records_processed)
        @csvfile.clean_up_physical_files_after_failure(@records_processed)
        # @project.communicate_to_managers(@csvfile) if @project.type_of_project == "individual"
      end
      sleep(300) if Rails.env.production?
    end
    # p "manager communication"
    #@project.communicate_to_managers(@csvfile) if files_to_be_processed.length >= 2
    at_exit do
      # p "goodbye"
    end
  end

  def self.delete_all
    FreecenCsvEntry.delete_all
    FreecenCsvFile.delete_all
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
    write_messages_to_all("Created  #{records} entries at an average time of #{average_time}ms per record at #{Time.new}. <br>",false)
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
    file_for_warning_messages = Rails.root.join('log', "freecen_csv_processing_messages_#{time}.log")
    message_file = File.new(file_for_warning_messages, 'w')
    message_file.chmod(0664)
    message_file
  end

  def write_member_message_file(message)
    member_message_file.puts message
  end

  def write_messages_to_all(message, no_member_message)
    # avoids sending the message to the member if no_member_message is false
    write_log_file(message) if message.present?
    write_member_message_file(message) if no_member_message && message.present?
  end

  def write_log_file(message)
    message_file.puts message
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

  attr_accessor :header, :list_of_registers, :header_error, :system_error, :data_hold,
    :array_of_data_lines, :default_charset, :file, :file_name, :userid, :uploaded_date, :slurp_fail_message,
    :file_start, :file_locations, :data, :unique_locations, :unique_existing_locations,
    :all_existing_records, :total_files, :total_records, :total_data_errors, :total_header_errors, :place_id, :civil_parish,
    :enumeration_district, :folio, :page, :year, :piece, :schedule, :folio_suffix, :schedule_suffix

  def initialize(file_location, project)
    @project = project
    @file_location = file_location
    standalone_filename = File.basename(@file_location)
    full_dirname = File.dirname(@file_location)
    parent_dirname = File.dirname(full_dirname)
    user_dirname = full_dirname.sub(parent_dirname, '').gsub(File::SEPARATOR, '')
    @all_existing_records = {}
    @array_of_data_lines = Array.new {Array.new}
    @data = {}
    @default_charset = "UTF-8"
    @file_locations = {}
    @file_name = standalone_filename
    @file_start =  nil
    @uploaded_date = Time.new
    @uploaded_date = File.mtime(@file_location) if File.exists?(@file_location)
    @header_error = []
    @header = {}
    @header[:digest] = Digest::MD5.file(@file_location).hexdigest if File.exists?(@file_location)
    @header[:file_name] = standalone_filename #do not capitalize filenames
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
    @civil_parish = ''
    @enumeration_district = ''
    @folio = 0
    @folio_suffix = nil
    @page = 0
    @schedule = 0
    @schedule_suffix = nil

  end

  def a_single_csv_file_process
    # p "single csv file"
    success = true
    @project.member_message_file = define_member_message_file
    @file_start = Time.new
    p "FREECEN:CSV_PROCESSING: Started on the file #{@header[:file_name]} for #{@header[:userid]} at #{@file_start}"
    @project.write_log_file("******************************************************************* <br>")
    @project.write_messages_to_all("Started on the file #{@header[:file_name]} for #{@header[:userid]} at #{@file_start}. <p>", true)
    success, message = ensure_processable? unless @project.force_rebuild
    # p "finished file checking #{message}. <br>"
    return [false, message] unless success

    success, message = slurp_the_csv_file
    # p "finished slurp #{success} #{message}"
    return [false, message] unless success
    @csv_records = CsvRecords.new(@array_of_data_lines, self, @project)
    success, reduction = @csv_records.process_header_fields

    return [false, "initial @data_lines made no sense extracted #{message}. <br>"] unless success || [1, 2].include?(reduction)

    success, message = @csv_records.extract_the_data(reduction)


    # p "finished data"
    return [success, "Data not extracted #{@records_processed}. <br>"] unless success
    # success, @records_processed, @data_errors = process_the_data if success

    # return [success, "Data not processed #{@records_processed}. <br>"] unless success

    success, message = clean_up_supporting_information
    # p "finished clean up"
    records = @total_records
    time = ((Time.new.to_i - @file_start.to_i) * 1000) / records unless records == 0
    @project.write_messages_to_all("Created  #{@total_records} entries at an average time of #{time}ms per record at #{Time.new}. <br>",true)
    return [success,"clean up failed #{message}. <br>"] unless success

    success, message = communicate_file_processing_results
    # p "finished com"
    return [success, "communication failed #{message}. <br>"] unless success

    [true, @total_records, @total_data_errors]
  end


  def check_and_create_db_record_for_entry(data_record, freereg1_csv_file)
    #p " check and create"
    if !@project.force_rebuild
      # p "processing create_db_record_for_entry"
      data_record.delete(:chapman_code)
      entry = FreecenCsvEntry.new(data_record)
      # p "new entry"
      # p entry
      new_digest = entry.cal_digest
      if @all_existing_records.has_value?(new_digest)
        #p "we have an existing record but may be for different location"
        existing_record = FreecenCsvEntry.id(@all_existing_records.key(new_digest)).first
        if existing_record.present?
          #p "yes we have a record"
          #we need to eliminate this record from hash
          #p "dropping hash entry"
          @all_existing_records.delete(@all_existing_records.key(existing_record.record_digest))
        else
          #p "No record existed"
          success = self.create_db_record_for_entry(data_record,freereg1_csv_file)
        end
      else
        #p "no digest"
        success = self.create_db_record_for_entry(data_record,freereg1_csv_file)
      end
    else
      #p "rebuild"
      success = self.create_db_record_for_entry(data_record,freereg1_csv_file)
    end
    return success
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

    message = "The file #{batch.file_name} for #{batch.userid} is already on system and is locked against replacement. <br>"
    return [true, 'OK'] unless batch.locked_by_transcriber || batch.locked_by_coordinator

    @project.write_messages_to_all(message, true)
    [false, message]
  end

  def check_userid_exists?
    message = "The #{@userid} userid does not exist. <br>"
    return [true, 'OK'] if UseridDetail.userid(@userid).first.present?

    @project.write_messages_to_all(message, true)
    [false, message]
  end

  def clean_up_message

    #File.delete(@project.message_file) if @project.type_of_project == 'individual' && File.exists?(@project.message_file) && !Rails.env.test?

  end

  def clean_up_physical_files_after_failure(message)
    #p "clean up after failure"
    batch = PhysicalFile.userid(@userid).file_name(@file_name).first
    return true if batch.blank? || message.blank?
    PhysicalFile.remove_waiting_flag(@userid,@file_name)
    batch.delete if message.include?("header errors") || message.include?("does not exist. ") || message.include?("userid does not exist. ")
  end

  def clean_up_supporting_information
    if @records_processed.blank? ||  @records_processed == 0
      batch = PhysicalFile.userid(@userid).file_name(@file_name).first
      return true if batch.blank?
      batch.delete
    else
      self.physical_file_clean_up_on_success
    end
    return true
  end

  def communicate_failure_to_member(message)
    #p "communicating failure"
    file = @project.member_message_file
    file.close
    UserMailer.batch_processing_failure(file, @userid, @file_name).deliver_now unless @project.type_of_project == "special_selection_1" ||  @project.type_of_project == "special_selection_2"
    self.clean_up_message
    return true
  end

  def communicate_file_processing_results
    #p "communicating success"
    file = @project.member_message_file
    file.close
    UserMailer.batch_processing_success(file,@header[:userid],@header[:file_name]).deliver_now unless @project.type_of_project == "special_selection_1" ||  @project.type_of_project == "special_selection_2"
    self.clean_up_message
    return true
  end

  def create_db_record_for_entry(data_record, freereg1_csv_file)
    # TODO: bring data_record hash keys in @data_line with those in FreecenCsvEntry
    #p "creating new entry"
    data_record.delete(:chapman_code)
    entry = FreecenCsvEntry.new(data_record)
    if data_record[:record_type] == "ma" || data_record[:record_type] == "ba"
      entry.multiple_witnesses << MultipleWitness.new(:witness_forename => data_record[:witness1_forename],:witness_surname => data_record[:witness1_surname]) unless data_record[:witness1_forename].blank? && data_record[:witness1_surname].blank?
      entry.multiple_witnesses << MultipleWitness.new(:witness_forename => data_record[:witness2_forename],:witness_surname => data_record[:witness2_surname]) unless data_record[:witness2_forename].blank? && data_record[:witness2_surname].blank?
      entry.multiple_witnesses << MultipleWitness.new(:witness_forename => data_record[:witness3_forename], :witness_surname => data_record[:witness3_surname]) unless data_record[:witness3_forename].blank? &&  data_record[:witness3_surname].blank?
      entry.multiple_witnesses << MultipleWitness.new(:witness_forename => data_record[:witness4_forename], :witness_surname => data_record[:witness4_surname]) unless data_record[:witness4_forename].blank? &&  data_record[:witness4_surname].blank?
      entry.multiple_witnesses << MultipleWitness.new(:witness_forename => data_record[:witness5_forename], :witness_surname => data_record[:witness5_surname]) unless data_record[:witness5_forename].blank? &&  data_record[:witness5_surname].blank?
      entry.multiple_witnesses << MultipleWitness.new(:witness_forename => data_record[:witness6_forename], :witness_surname => data_record[:witness6_surname]) unless data_record[:witness6_forename].blank? &&  data_record[:witness6_surname].blank?
      entry.multiple_witnesses << MultipleWitness.new(:witness_forename => data_record[:witness7_forename], :witness_surname => data_record[:witness7_surname]) unless data_record[:witness7_forename].blank? &&  data_record[:witness7_surname].blank?
      entry.multiple_witnesses << MultipleWitness.new(:witness_forename => data_record[:witness8_forename], :witness_surname => data_record[:witness8_surname]) unless data_record[:witness8_forename].blank? &&  data_record[:witness8_surname].blank?
    end
    entry.multiple_witnesses.each do |witness|
      witness.witness_surname = witness.witness_surname.upcase if witness.witness_surname.present?
    end

    entry.freereg1_csv_file = freereg1_csv_file
    #p "creating entry"
    entry.save
    #p entry
    if entry.errors.any?
      success = entry.errors.messages
    else
      place_id = self.place_id
      place = Place.id(place_id).first
      SearchRecord.update_create_search_record(entry,self.header[:search_record_version],place) if  @project.create_search_records && entry.enough_name_fields?
      success = "new"
    end
    sleep_time = (Rails.application.config.sleep.to_f).to_f
    sleep(sleep_time)
    # p entry.search_record
    return success
  end

  def define_member_message_file
    time = Time.new
    tnsec = time.nsec / 1000
    time = time.to_i.to_s + tnsec.to_s
    file_for_member_messages = Rails.root.join('log', "#{userid}_member_update_messages_#{time}.log").to_s
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
    batch = PhysicalFile.userid(@header[:userid]).file_name( @header[:file_name] ).first
    if batch.nil?
      batch = PhysicalFile.new(:userid => @header[:userid], :file_name => @header[:file_name],:base => true, :base_uploaded_date => Time.new)
      batch.save
    end
    if @project.create_search_records
      # we created search records so its in the search database database
      batch.update_attributes( :file_processed => true, :file_processed_date => Time.new,:waiting_to_be_processed => false, :waiting_date => nil)
    else
      #only checked for errors so file is not processed into search database
      batch.update_attributes(:file_processed => false, :file_processed_date => nil,:waiting_to_be_processed => false, :waiting_date => nil)
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

end

class CsvRecords < CsvFile

  attr_accessor :array_of_lines, :data_lines

  def initialize(data_array, csvfile, project)
    @project = project
    @csvfile = csvfile
    @array_of_lines = data_array
    @data_lines = Array.new { Array.new }
  end

  def process_header_fields
    # p "Getting header
    reduction = 3
    n = 0
    while n <= 2
      @project.write_messages_to_all("Error: line #{n} is empty", true) if @array_of_lines[n][0..24].all?(&:blank?)
      case n
      when 0
        @csvfile.year, @csvfile.piece, success, message = line_one(@array_of_lines[n])
        @project.write_messages_to_all(message, true) unless success
        @project.write_messages_to_all("Working on #{@csvfile.piece.district_name} for #{@csvfile.year}, in #{@csvfile.piece.chapman_code}", true) if success
        reduction = reduction - 1 unless success || message =~ /Error: line 1 of batch does not have a valid piece number/
      when 1
        success, message = line_two(@array_of_lines[n])
        unless success
          reduction = reduction - 1
          @project.write_messages_to_all(message, true)
        end
      when 2
        success, message = line_three(@array_of_lines[n])
        unless success

          reduction = reduction - 1
          @project.write_messages_to_all(message, true)
        end
      end
      n = n + 1
    end
    [success, reduction]
  end

  def line_one(line)
    if FreecenValidations.fixed_valid_piece?(line[0])
      success = true
      piece = line[0]
      year, piece = FreecenPiece.extract_year_and_piece(line[0])
      piece = FreecenPiece.where(year: year, piece_number: piece).first
      if piece.blank?
        message = "Error: there is no piece with #{line[0]} in the database}. <br>"
        success = false
      end
    else
      message = "Error: line 1 of batch does not have a valid piece number. It has #{line[0]}. <br>"
      success = false
    end
    [year, piece, success, message]
  end

  def line_two(line)
    if line[0..20].all?(&:present?) && line[22..24].all?(&:present?)
      success = true
    else
      message = 'INFO: line 2 or 3 containing SSCENS Field information is missing<br>'
      success = false
    end
    [success, message]
  end

  def line_three(line)
    if line[0..20].all?(&:present?) && line[22..24].all?(&:present?)
      success = true
    else
      message = 'INFO: both lines with SSCENS Field information are missing<br>'
      success = false
    end
    [success, message]
  end

  # This extracts the header and entry information from the file and adds it to the database

  def extract_the_data(skip)
    skip = skip - 1
    success = true
    data_lines = 0
    @data_records = []
    @array_of_lines.each_with_index do |line, n|
      next if n <= skip

      @project.write_messages_to_all("Error: line #{n} is empty", true) if line[0..24].all?(&:blank?)
      next if line[0..24].all?(&:blank?)

      @record = CsvRecord.new(line, @csvfile, @project)
      success, message, result = @record.extract_data_line(n + 1)
      @data_records << result

      @project.write_messages_to_all(message, true) unless success
      success = true
      data_lines = data_lines + 1
    end
    [success, data_lines]
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
  end

  def extract_data_line(num)
    @data_record[:info_messages] = @project.info_messages
    @data_record[:data_transition] = Freecen::FIELD_NAMES[first_field_present]
    load_data_record(Freecen::FIELD_NAMES[first_field_present], num)

    # p @data_record
    # crash if num == 300
    [true, " ", @data_record]
  end

  def first_field_present
    @data_line.each_with_index do |field, n|
      @x = n.to_s
      break if field.present?
    end
    @x
  end

  def load_data_record(record_type, num)
    @data_record[:record_number] = num
    case record_type
    when 'Civil Parish'
      extract_civil_parish_fields
    when 'Enumeration District'
      extract_enumeration_district_fields
    when 'Folio'
      extract_folio_fields
    when 'Page'
      extract_page_fields
    when 'Dwelling'
      extract_dwelling_fields
    when 'Individual'
      extract_individual_fields
    when 'Error'
      error_in_fields
    end
    # following are computed or added
    # field :deleted_flag, type: Boolean
    # field :dwelling_number, type: Integer
    # field :sequence_in_household, type: Integer
    # field :uninhabited_flag, type: String
    # field :unoccupied_notes, type: String
    # field :individual_flag, type: String
    # field :name_flag, type: String
    # field :age_unit, type: String
    # field :detail_flag, type: String
    # field :occupation_flag, type: String
    # field :birth_county, type: String
    # field :birth_place, type: String
    # field :birth_place_flag, type: String

  end

  def extract_civil_parish_fields
    @data_record[:civil_parish] = @data_line[0]
    success, message, @csvfile.civil_parish = FreecenCsvEntry.validate_civil_parish(@data_record, @csvfile.civil_parish)
    @project.write_messages_to_all(message, true) unless message == ''
    extract_enumeration_district_fields
  end

  def extract_enumeration_district_fields
    @data_record[:enumeration_district] = @data_line[1]
    success, message, enumeration_district, folio_number, folio_suffix, page_namber, schedule_number, schedule_suffix = FreecenCsvEntry.validate_enumeration_district(@data_record, @csvfile.enumeration_district)
    unless enumeration_district == @csvfile.enumeration_district
      @csvfile.enumeration_district = enumeration_district
      @csvfile.folio = folio_number if folio_number.present?
      @csvfile.folio_suffix = folio_suffix if folio_suffix.present?
      @csvfile.page = page_namber if page_namber.present?
      @csvfile.schedule = schedule_number if schedule_number.present?
      @csvfile.schedule_suffix = schedule_suffix if schedule_suffix.present?
    end

    @project.write_messages_to_all(message, true) unless message == ''
    extract_folio_fields
  end

  def extract_folio_fields
    @data_record[:folio_number] = @data_line[2]
    success, message, @csvfile.folio, @csvfile.folio_suffix = FreecenCsvEntry.validate_folio(@data_record, @csvfile.folio, @csvfile.folio_suffix)
    @project.write_messages_to_all(message, true) unless message == ''
    extract_page_fields
  end

  def extract_page_fields
    @data_record[:page_number] = @data_line[3]
    success, message, @csvfile.page = FreecenCsvEntry.validate_page(@data_record, @csvfile.page)
    @project.write_messages_to_all(message, true) unless message == ''
    extract_dwelling_fields
  end

  def extract_dwelling_fields
    @data_record[:schedule_number] = @data_line[4]
    @data_record[:house_number] = @data_line[5]
    @data_record[:house_or_street_name] = @data_line[6]
    @data_record[:uncertainy_location] = @data_line[7]
    success, message, @csvfile.schedule, @csvfile.schedule_suffix = FreecenCsvEntry.validate_dwelling(@data_record, @csvfile.schedule, @csvfile.schedule_suffix)
    @project.write_messages_to_all(message, true) unless message == ''
    extract_individual_fields
  end

  def extract_individual_fields
    return if ['b', 'n', 'u', 'v'].include?(@data_record[:uncertainy_location])

    @data_record[:surname] = @data_line[8]
    @data_record[:forenames] = @data_line[9]
    @data_record[:uncertainty_name] = @data_line[10]
    @data_record[:relationship] = @data_line[11]
    @data_record[:marital_status] = @data_line[12]
    @data_record[:sex] = @data_line[13]
    @data_record[:age] = @data_line[14]
    @data_record[:uncertainty_status] = @data_line[15]
    @data_record[:occupation] = @data_line[16]
    @data_record[:occupation_category] = @data_line[17]
    @data_record[:uncertainty_occupation] = @data_line[18]
    @data_record[:verbatim_birth_county] = @data_line[19]
    @data_record[:verbatim_birth_place] = @data_line[20]
    @data_record[:uncertainy_birth] = @data_line[21]
    @data_record[:disability] = @data_line[22]
    @data_record[:language] = @data_line[23]
    @data_record[:notes] = @data_line[24]
    if ['1901', '1911'].include?(@data_record[:year])
      @data_record[:at_home] = @data_line[25]
      @data_record[:rooms] = @data_line[26]
    end
    success, message = FreecenCsvEntry.validate_individual(@data_record)
    @project.write_messages_to_all(message, true) unless message == ''
  end
end
