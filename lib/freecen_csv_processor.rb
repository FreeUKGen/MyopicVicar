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
  require 'freereg_validations'
  require 'freereg_options_constants'
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
  # to permit different CsvFile field structures. It also extracts the data lines.
  # CsvRecord is used to convert the csvrecord into a freereg1_csv_entry

  # note each class inherits from its superior

  #:message_file is the log file where system and processing messages are written
  attr_accessor :freecen_files_directory, :create_search_records, :type_of_project, :force_rebuild,
    :file_range, :message_file, :member_message_file, :project_start_time, :total_records, :total_files, :total_data_errors

  def initialize(arg1, arg2, arg3, arg4, arg5, arg6)
    @create_search_records = arg2
    @file_range = arg5
    @force_rebuild = arg4
    @freecen_files_directory = arg1
    @message_file = define_message_file
    @project_start_time = arg6
    @total_data_errors = 0
    @total_files = 0
    @total_records = 0
    @type_of_project = arg3
    EmailVeracity::Config[:skip_lookup] = true
  end

  def self.activate_project(create_search_records, type, force, range)
    force, create_search_records = FreecenCsvProcessor.convert_to_bolean(create_search_records, force)
    @project = FreecenCsvProcessor.new(Rails.application.config.datafiles, create_search_records, type, force, range, Time.new)
    @project.write_log_file("Started freecen csv file processor project. #{@project.inspect} using website #{Rails.application.config.website}. <br>")
    @csvfiles = CsvFiles.new
    success, files_to_be_processed = @csvfiles.get_the_files_to_be_processed(@project)
    if !success || (files_to_be_processed.present? && files_to_be_processed.length.zero?)
      @project.write_log_file('processing terminated as we have no records to process. <br>')
      return
    end
    @project.write_log_file("#{files_to_be_processed.length}\t files selected for processing. <br>")
    files_to_be_processed.each do |file|
      @csvfile = CsvFile.new(file)
      success, @records_processed, @data_errors = @csvfile.a_single_csv_file_process(@project)
      if success
        #p "processed file"
        @project.total_records = @project.total_records + @records_processed unless @records_processed.nil?
        @project.total_data_errors = @project.total_data_errors + data_errors unless @data_errors
        @project.total_files = @project.total_files + 1
      else
        #p "failed to process file"
        @csvfile.communicate_failure_to_member(@project, @records_processed)
        @csvfile.clean_up_physical_files_after_failure(@records_processed)
        #@project.communicate_to_managers(@csvfile) if @project.type_of_project == "individual"
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

  def communicate_to_managers(csvfile)
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
    write_log_file(message)
    write_member_message_file(message) if no_member_message
  end

  def write_log_file(message)
    message_file.puts message
  end
end

class CsvFiles < FreecenCsvProcessor
  def initialize
  end

  def get_the_files_to_be_processed(project)
    #  p "Getting files"
    case project.type_of_project
    when 'waiting'
      files = get_the_waiting_files_to_be_processed(project)
    when 'range'
      files = get_the_range_files_to_be_processed(project)
    when 'individual'
      files = get_the_individual_file_to_be_processed(project)
    end
    [true, files]
  end

  # GetFile is a lib task
  def get_the_individual_file_to_be_processed(project)
    # p "individual file selection"
    files = GetFiles.get_all_of_the_filenames(project.freecen_files_directory, project.file_range)
    files
  end

  def get_the_range_files_to_be_processed(project)
    # p "range file selection"
    files = GetFiles.get_all_of_the_filenames(project.freecen_files_directory, project.file_range)
    files
  end

  def get_the_waiting_files_to_be_processed(project)
    # p "waiting file selection"
    physical_waiting_files = PhysicalFile.waiting.all.order_by(waiting_date: 1)
    files = []
    physical_waiting_files.each do |file|
      files << File.join(project.freecen_files_directory, file.userid, file.file_name)
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
    :all_existing_records, :total_files, :total_records, :total_data_errors, :total_header_errors, :place_id, :uploaded_file_is_flexible_format
  def initialize(file)
    standalone_filename = File.basename(file)
    full_dirname = File.dirname(file)
    parent_dirname = File.dirname(full_dirname)
    user_dirname = full_dirname.sub(parent_dirname, '').gsub(File::SEPARATOR, '')
    @all_existing_records = {}
    @array_of_data_lines = Array.new {Array.new}
    @data = {}
    @default_charset = "UTF-8"
    @file = file
    @file_locations = {}
    @file_name = standalone_filename
    @file_start =  nil
    @uploaded_date = Time.new
    @uploaded_date = File.mtime(file) if File.exists?(file)
    @header_error = []
    @header = {}
    @header[:digest] = Digest::MD5.file(file).hexdigest if File.exists?(file)
    @header[:file_name] = standalone_filename #do not capitalize filenames
    @header[:userid] = user_dirname
    @header[:uploaded_date] = @uploaded_date
    @header[:def] = false
    @header[:lds] = 'no'
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
    @unique_existing_locations = {}
    @unique_locations = {}
    @uploaded_file_is_flexible_format = false
  end

  def a_single_csv_file_process(project)
    # p "single csv file"
    success = true
    project.member_message_file = define_member_message_file
    @file_start = Time.new
    p "FREECEN:CSV_PROCESSING: Started on the file #{@header[:file_name]} for #{@header[:userid]} at #{@file_start}"
    project.write_log_file("******************************************************************* <br>")
    project.write_messages_to_all("Started on the file #{@header[:file_name]} for #{@header[:userid]} at #{@file_start}. <p>", true)
    success, message = ensure_processable?(project) unless project.force_rebuild
    # p "finished file checking #{message}. <br>"
    return [false, message] unless success

    success, message = slurp_the_csv_file(project)
    # p "finished slurp #{success} #{message}"
    return [false, message] unless success

    @csv_records = CsvRecords.new(@array_of_data_lines)
    success, reduction = @csv_records.process_header_fields(self, project)

    return [false, "initial lines made no sense extracted #{message}. <br>"] unless success || [1, 2].include?(reduction)

    success, message = @csv_records.extract_the_data(self, project, reduction)


    # p "finished data"
    return [success, "Data not extracted #{@records_processed}. <br>"] unless success

    success, @records_processed, @data_errors = process_the_data(project) if success

    return [success, "Data not processed #{@records_processed}. <br>"] unless success

    success, message = clean_up_supporting_information(project)
    # p "finished clean up"
    records = @total_records
    time = ((Time.new.to_i - @file_start.to_i) * 1000) / records unless records == 0
    project.write_messages_to_all("Created  #{@total_records} entries at an average time of #{time}ms per record at #{Time.new}. <br>",true)
    return [success,"clean up failed #{message}. <br>"] unless success

    success, message = communicate_file_processing_results(project)
    # p "finished com"
    return [success, "communication failed #{message}. <br>"] unless success

    [true, @total_records, @total_data_errors]
  end


  def check_and_create_db_record_for_entry(project,data_record,freereg1_csv_file)
    #p " check and create"
    if !project.force_rebuild
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
          success = self.existing_entry_may_be_same_location(existing_record,data_record,project,freereg1_csv_file)
          #we need to eliminate this record from hash
          #p "dropping hash entry"
          @all_existing_records.delete(@all_existing_records.key(existing_record.record_digest))
        else
          #p "No record existed"
          success = self.create_db_record_for_entry(project,data_record,freereg1_csv_file)
        end
      else
        #p "no digest"
        success = self.create_db_record_for_entry(project,data_record,freereg1_csv_file)
      end
    else
      #p "rebuild"
      success = self.create_db_record_for_entry(project,data_record,freereg1_csv_file)
    end
    return success
  end

  def check_and_set_characterset(code_set, csvtxt, project)
    # if it looks like valid UTF-8 and we know it isn't
    # Windows-1252 because of undefined characters, then
    # default to UTF-8 instead of Windows-1252
    if code_set.nil? || code_set.empty? || code_set == 'chset'
      # project.write_messages_to_all("Checking for undefined with #{code_set}",false)
      if csvtxt.index(0x81.chr) || csvtxt.index(0x8D.chr) ||
          csvtxt.index(0x8F.chr) || csvtxt.index(0x90.chr) ||
          csvtxt.index(0x9D.chr)
        # p 'undefined Windows-1252 chars, try UTF-8 default'
        # project.write_messages_to_all("Found undefined}",false)
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

  def check_file_exists?(project)
    # make sure file actually exists
    message = "The file #{@file_name} for #{@userid} does not exist. <br>"
    return [true, 'OK'] if File.exist?(@file)

    project.write_messages_to_all(message, true)
    [false, message]
  end

  def check_file_is_not_locked?(batch, project)
    return [true, 'OK'] if batch.blank?

    message = "The file #{batch.file_name} for #{batch.userid} is already on system and is locked against replacement. <br>"
    return [true, 'OK'] unless batch.locked_by_transcriber || batch.locked_by_coordinator

    project.write_messages_to_all(message, true)
    [false, message]
  end

  def check_userid_exists?(project)
    message = "The #{@userid} userid does not exist. <br>"
    return [true, 'OK'] if UseridDetail.userid(@userid).first.present?

    project.write_messages_to_all(message, true)
    [false, message]
  end

  def clean_up_message(project)

    File.delete(project.message_file) if project.type_of_project == 'individual' && File.exists?(project.message_file) && !Rails.env.test?

  end

  def clean_up_physical_files_after_failure(message)
    #p "clean up after failure"
    batch = PhysicalFile.userid(@userid).file_name(@file_name).first
    return true if batch.blank? || message.blank?
    PhysicalFile.remove_waiting_flag(@userid,@file_name)
    batch.delete if message.include?("header errors") || message.include?("does not exist. ") || message.include?("userid does not exist. ")
  end

  def clean_up_supporting_information(project)
    if @records_processed.blank? ||  @records_processed == 0
      batch = PhysicalFile.userid(@userid).file_name(@file_name).first
      return true if batch.blank?
      batch.delete
    else
      self.physical_file_clean_up_on_success(project)
    end
    return true
  end

  def clean_up_unused_batches(project)
    #p "cleaning up batches and records"
    counter = 0
    files = Array.new
    @all_existing_records.each do |record, value|
      counter = counter + 1
      actual_record = FreecenCsvEntry.id(record).first
      file_for_entry = actual_record.freereg1_csv_file_id unless actual_record.nil?
      files << file_for_entry unless files.include?(file_for_entry)
      actual_record.destroy unless actual_record.nil?
      sleep_time =  sleep_time = (Rails.application.config.sleep.to_f).to_f
      sleep(sleep_time) unless actual_record.nil?
    end
    #recalculate distribution after clean up
    files.each do |file|
      actual_batch = FreecenCsvFile.id(file).first
      actual_batch.calculate_distribution if actual_batch.present?
    end
    @unique_existing_locations.each do |key,value|
      file = FreecenCsvFile.id(value[:id]).first
      if file.present?
        message = "Removing batch #{file.county}, #{file.place}, #{file.church_name}, #{file.register_type}, #{file.record_type} for #{file.userid} #{file.file_name}. <br>"
        project.write_messages_to_all(message,false)
        file.delete
      end
    end
    return counter
  end

  def communicate_failure_to_member(project,message)
    #p "communicating failure"
    file = project.member_message_file
    file.close
    UserMailer.batch_processing_failure(file,@userid,@file_name).deliver_now unless project.type_of_project == "special_selection_1" ||  project.type_of_project == "special_selection_2"
    self.clean_up_message(project)
    return true
  end

  def communicate_file_processing_results(project)
    #p "communicating success"
    file = project.member_message_file
    file.close
    UserMailer.batch_processing_success(file,@header[:userid],@header[:file_name]).deliver_now unless project.type_of_project == "special_selection_1" ||  project.type_of_project == "special_selection_2"
    self.clean_up_message(project)
    return true
  end

  def create_db_record_for_entry(project,data_record,freereg1_csv_file)
    # TODO: bring data_record hash keys in line with those in FreecenCsvEntry
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
      SearchRecord.update_create_search_record(entry,self.header[:search_record_version],place) if  project.create_search_records && entry.enough_name_fields?
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


  def determine_if_utf8(csvtxt, project)
    # check for BOM and if found, assume corresponding
    # unicode encoding (unless invalid sequences found),
    # regardless of what user specified in column 5 since it
    # may have been edited and saved as unicode by coord
    # without updating col 5 to reflect the new encoding.
    # p "testing for BOM"
    if !csvtxt.nil? && csvtxt.length > 2
      if csvtxt[0].ord == 0xEF && csvtxt[1].ord == 0xBB && csvtxt[2].ord == 0xBF
        # p "UTF-8 BOM found"
        # project.write_messages_to_all("BOM found",false)
        csvtxt = csvtxt[3..-1] # remove BOM
        code_set = 'UTF-8'
        self.slurp_fail_message = 'BOM detected so using UTF8. <br>'
        csvtxt.force_encoding(code_set)
        if !csvtxt.valid_encoding?
          # project.write_messages_to_all("Not really a UTF8",false)
          # not really a UTF-8 file. probably was edited in
          # software that added BOM to beginning without
          # properly transcoding existing characters to UTF-8
          code_set = 'ASCII-8BIT'
          csvtxt.encode('ASCII-8BIT')
          csvtxt.force_encoding('ASCII-8BIT')
          # project.write_messages_to_all("Not really ASCII-8BIT",false) unless csvtxt.valid_encoding?
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
    #project.write_messages_to_all("Code set #{code_set}", false)

    [code_set, csvtxt]
  end

  def ensure_processable?(project)
    success, message = check_file_exists?(project)
    success, message = check_userid_exists?(project) if success
    batch = FreecenCsvFile.userid(@userid).file_name(@file_name).first if success
    success, message = check_file_is_not_locked?(batch, project) if success
    return [true, 'OK'] if success

    return [false, message] unless success
  end

  def existing_entry_may_be_same_location(existing_record,data_record,project,freereg1_csv_file)
    if existing_record.same_location(existing_record,freereg1_csv_file)
      # this method is located in entry model
      #p "same location"
      #record location is OK
      if existing_record.search_record.present?
        # search record and entry are OK
        success = "nochange"
      else
        success = "change"
        #need to create search record as one does not exist
        #p "creating search record as not there"
        place_id = self.place_id
        place = Place.id(place_id).first
        SearchRecord.update_create_search_record(existing_record,self.header[:search_record_version],place) if project.create_search_records && existing_record.enough_name_fields?
        sleep_time = (Rails.application.config.sleep.to_f).to_f
        sleep(sleep_time)
      end
    else
      success = self.change_location_for_existing_entry_and_record(existing_record,data_record,project,freereg1_csv_file)
    end
    success
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

  def get_batch_locations_and_records_for_existing_file
    #p "getting existing locations"
    locations = Hash.new
    all_records_hash = Hash.new
    freereg1_csv_files = FreecenCsvFile.where(:file_name => @header[:file_name], :userid => @header[:userid]).all
    freereg1_csv_files.each do |batch|
      args = {:chapman_code => batch.county,:place_name => batch.place,:church_name =>
              batch.church_name,:register_type => batch.register_type, :record_type => batch.record_type, :id => batch.id}
      key = sum_the_header(args)
      locations[key] = args
      batch.batch_errors.delete_all
      batch.freereg1_csv_entries.each do |entry|
        all_records_hash[entry.id] = entry.record_digest
      end
    end
    return locations,all_records_hash
  end

  def get_codeset_from_header(code_set,csvtxt,project)
    @slurp_fail_message = "CSV parse failure on first line. <br>"
    first_data_line = CSV.parse_line(csvtxt)
    @slurp_fail_message = nil # no exception thrown
    if !first_data_line.nil? && first_data_line[0] == "+INFO" && !first_data_line[5].nil?
      code_set_specified_in_csv = first_data_line[5].strip
      # project.write_messages_to_all("Detecting character set found #{code_set_specified_in_csv}",false)
      if !code_set.nil? && code_set != code_set_specified_in_csv
        message = "ignoring #{code_set_specified_in_csv} specified in col 5 of .csv header because #{code_set} Byte Order Mark (BOM) was found in the file"
        # project.write_messages_to_all(message,false)
      else
        #project.write_messages_to_all("using #{code_set_specified_in_csv}",false)
        code_set = code_set_specified_in_csv
      end
    end
    return code_set
  end
  def get_place_id_from_file(freereg1_csv_file)
    register = freereg1_csv_file.register
    church = register.church
    place = church.place
    return place.id
  end

  def physical_file_clean_up_on_success(project)
    #p "physical file clean up on success"
    batch = PhysicalFile.userid(@header[:userid]).file_name( @header[:file_name] ).first
    if batch.nil?
      batch = PhysicalFile.new(:userid => @header[:userid], :file_name => @header[:file_name],:base => true, :base_uploaded_date => Time.new)
      batch.save
    end
    if project.create_search_records
      # we created search records so its in the search database database
      batch.update_attributes( :file_processed => true, :file_processed_date => Time.new,:waiting_to_be_processed => false, :waiting_date => nil)
    else
      #only checked for errors so file is not processed into search database
      batch.update_attributes(:file_processed => false, :file_processed_date => nil,:waiting_to_be_processed => false, :waiting_date => nil)
    end
  end

  def update_place_after_processing(freereg1_csv_file, chapman_code, place_name)
    place = Place.where(:chapman_code => chapman_code, :place_name => place_name).first
    place.ucf_list[freereg1_csv_file.id.to_s] = []
    place.save
    place.update_ucf_list(freereg1_csv_file)
    place.save
    freereg1_csv_file.save
  end

  def process_the_data(project)
    #p "Processing the data records"
    @unique_existing_locations, @all_existing_records = self.get_batch_locations_and_records_for_existing_file
    message = "There are #{@unique_locations.length} locations and #{@all_existing_records.length} existing records corresponding to the new file. <p>"
    project.write_messages_to_all(message,false) if @unique_locations.length >= 2 || @all_existing_records.length >= 1
    @unique_locations.each do |key,value|
      place_cache_refresh = self.refresh_place_cache?(key,value)
      freereg1_csv_file = self.setup_batch_for_processing(project,key,value)
      records, batch_errors, not_changed = self.process_the_records_for_this_batch_into_the_database(project,key,freereg1_csv_file)
      self.update_the_file_information(project,freereg1_csv_file,records,batch_errors)
      changed = 0
      changed =   records -   not_changed unless records.blank?
      message = "#{records} records were processed of which #{changed} were updated/added and #{batch_errors} had data errors. <p>"
      project.write_messages_to_all(message,true)
      PlaceCache.refresh(freereg1_csv_file.chapman_code) if place_cache_refresh
      project.write_messages_to_all("Place cache refreshed",false) if place_cache_refresh
      update_place_after_processing(freereg1_csv_file, value[:chapman_code],value[:place_name])
      freereg1_csv_file.update_freereg_contents_after_processing
    end
    #p "after process"
    counter = self.clean_up_unused_batches(project)
    message = "There were #{counter} entries in the original file that did not exist in the new one and hence were deleted. <br>"
    project.write_messages_to_all(message,false) unless counter == 0
    return true, @total_records, @total_data_errors
  end

  def refresh_place_cache?(key,value)
    refresh = true
    place = Place.chapman_code(value[:chapman_code]).place(value[:place_name]).first
    refresh = false if place.search_records.exists?
    return refresh
  end

  def process_the_records_for_this_batch_into_the_database(project,key,freereg1_csv_file)
    #p "processing batch records"
    not_changed = 0
    batch_errors = 0
    records = 0
    #write the data records for each place/church
    @data.each do |datakey,datarecord|
      if datarecord[:location] == key
        datarecord[:place] = datarecord[:place_name] #entry uses place
        datarecord.delete(:place_name)
        records = records + 1
        success = self.check_and_create_db_record_for_entry(project,datarecord,freereg1_csv_file)
        #p "#{success} after check and create"
        if success.nil? || success == "change" || success == "new"
          #p "ok to proceed"
        elsif success == "nochange"
          #p "nochange"
          not_changed = not_changed + 1
        else
          #p "deal with batch error"
          batch_error = BatchError.new(error_type: 'Data_Error', record_number: datarecord[:file_line_number], error_message: success, record_type: freereg1_csv_file.record_type, data_line: datarecord)
          batch_error.freereg1_csv_file = freereg1_csv_file
          batch_error.save
          batch_errors = batch_errors + 1
          message = "Data Error in line #{datarecord[:file_line_number]} problem was #{success}.<br>"
          project.write_messages_to_all(message,true)
        end #end success  no change
      end #end record
    end
    #p "this batch processed"
    return records, batch_errors, not_changed
  end

  def setup_batch_for_processing(project,thiskey,thisvalue)
    #p "setting up the batch"
    batch_header = @header
    batch_header[:county] = thisvalue[:chapman_code]
    batch_header[:chapman_code] = thisvalue[:chapman_code]
    batch_header[:place] = thisvalue[:place_name]
    batch_header[:place_name] = thisvalue[:place_name]
    batch_header[:church_name] = thisvalue[:church_name]
    batch_header[:register_type] = thisvalue[:register_type]
    batch_header[:alternate_register_name] = thisvalue[:church_name].to_s + ' ' + thisvalue[:register_type].to_s
    freereg1_csv_file = FreecenCsvFile.where(:userid => @header[:userid],:file_name => @header[:file_name],:county => thisvalue[:chapman_code], :place => thisvalue[:place_name], :church_name => thisvalue[:church_name], :register_type => thisvalue[:register_type], :record_type =>@header[:record_type]).first
    #:place => value[:place_name], :church_name => value[:church_name], :register_type => value[:register_type], :record_type =>@header[:record_type]
    if freereg1_csv_file.nil?
      freereg1_csv_file = FreecenCsvFile.new(batch_header)
      freereg1_csv_file.update_register
      message = "Creating a new batch for #{batch_header[:chapman_code]}, #{batch_header[:place_name]}, #{batch_header[:church_name]}, #{RegisterType::display_name(batch_header[:register_type])}. <br>"
    else
      freereg1_csv_file.update_attributes(:uploaded_date => self.uploaded_date, :lds => self.header[:lds], :def => self.header[:def], :order => self.header[:order])
      message = "Updating the current batch for #{batch_header[:chapman_code]}, #{batch_header[:place_name]}, #{batch_header[:church_name]}, #{RegisterType::display_name(batch_header[:register_type])}. <br>"
      #remove batch errors for this location
      freereg1_csv_file.error = 0
      #remove this location from the total locations
      @unique_existing_locations.delete_if {|key,value| key == thiskey}
    end
    self.place_id = get_place_id_from_file(freereg1_csv_file)
    project.write_messages_to_all(message,true)
    return freereg1_csv_file
  end

  def slurp_the_csv_file(project)
    # p "starting the slurp"
    # read entire .csv as binary text (no encoding/conversion)
    success = true
    csvtxt = File.open(@file, 'rb', encoding: 'ASCII-8BIT:ASCII-8BIT') { |f| f.read }
    project.write_messages_to_all('Empty file', true) if csvtxt.blank?
    return false if csvtxt.blank?

    code, csvtxt = determine_if_utf8(csvtxt, project)
    # code = get_codeset_from_header(code, csvtxt, project)
    code, message, csvtxt = self.check_and_set_characterset(code, csvtxt, project)
    csvtxt = self.standardize_line_endings(csvtxt)
    success = self.extract_the_array_of_lines(csvtxt)

    [success, message]
    #we ensure that processing keeps going by dropping out through the bottom
  end

  def standardize_line_endings(csvtxt)
    xxx = csvtxt.gsub(/\r?\n/, "\r\n").gsub(/\r\n?/, "\r\n")
    return xxx
  end

  #creates a unique key based of the location fields
  def sum_the_header(args)
    key = args[:chapman_code].to_s + args[:place_name].gsub(/\s+/, '').to_s + args[:church_name].gsub(/\s+/, '').to_s +
      args[:register_type].to_s + args[:record_type].to_s
    return key
  end

  def update_the_file_information(project,freereg1_csv_file,records,batch_errors)
    #p "update_the_file_information"
    @total_records = @total_records + records
    @total_data_errors = @total_data_errors + batch_errors
    freereg1_csv_file.calculate_distribution
    freereg1_csv_file.update_attribute(:processed, false) if !project.create_search_records
    freereg1_csv_file.update_attributes(:processed => true, :processed_date => Time.new) if project.create_search_records
    freereg1_csv_file.update_attributes(:error => batch_errors)
  end
end


class CsvRecords < CsvFile

  attr_accessor :array_of_lines, :header_lines, :data_lines, :data_entry_order, :piece

  def initialize(data_array)
    @array_of_lines = data_array
    @data_lines = Array.new {Array.new}
  end

  def process_header_fields(csvfile, project)
    # p "Getting header
    reduction = 0
    n = 0
    while n <= 2
      line = @array_of_lines[n]
      project.write_messages_to_all("Error: line #{n} is empty", true) if line[0..24].all?(&:blank?)
      case n
      when 0
        @piece, success, message = line_one(line)
        project.write_messages_to_all(message, true) unless success
        reduction = 1 unless success
      when 1
        success, message = line_two(line)
        unless success
          reduction = reduction + 1
          project.write_messages_to_all(message, true)
        end
      when 2
        success, message = line_three(line)
        unless success
          reduction = reduction + 1
          project.write_messages_to_all(message, true)
        end
      end
      n = n + 1
    end
    [success, reduction]
  end

  def line_one(line)
    if FreecenValidations.valid_piece?(line[0])
      success = true
      piece = line[0]
      piece = FreecenPiece.where(freecen1_filename: "#{line[0].downcase}.vld").first
      if piece.blank?
        message = "Error: there is no piece with #{line[0]} in the database}. <br>"
        success = false
      end
    else
      message = "Error: line 1 of batch does not have a valid piece number. It has #{line[0]}. <br>"
      success = false
    end
    [piece, success, message]
  end

  def line_two(line)
    if line[0..24].all?(&:present?)
      success = true
    else
      message = 'INFO: line 2 containing field names is not present <br>'
      success = false
    end
    [success, message]
  end

  def line_three(line)
    if line[0..24].all?(&:present?)
      success = true
    else
      message = 'INFO: line 3 containing field names is not present <br>'
      success = false
    end
    [success, message]
  end

  # This extracts the header and entry information from the file and adds it to the database
  def extract_the_data(csvfile, project, reduction)
    reduction = 3 - reduction
    success = true
    @array_of_lines.each_with_index do |line, n|
      next if n < reduction
      @record = CsvRecord.new(line)
      success, message = @record.extract_data_line(project, n)
      project.write_messages_to_all(message, true) unless success
      success = true
      data_lines = data_lines + 1
    end
    [success, data_lines]
  end

  def inform_the_user(csvfile,project)
    csvfile.header_error.each do |error|
      project.write_messages_to_all(error,true)
    end
  end


end

class CsvRecord < CsvRecords

  attr_accessor :data_line, :data_record

  def initialize(data_line)
    @data_line = data_line
    @data_record = {}
    @data_records = []
  end

  def extract_data_line(project, num)
    @data_line << Freecen::FIELD_NAMES[first_field_present]
    load_data_record(project, num)
  end

  def first_field_present
    @data_line.each_with_index do |field, n|
      @x = n
      break if field.present?
    end
    @x
  end

  def load_data_record(project, num)
    p @piece
    @data_record[:civil_parish] = line[0]
    @data_record[:ecclesiastical_parish] = line[1]
    @data_record[:folio_number] = line[2]
    @data_record[:page_number] = line[3]
    @data_record[:schedule_number] = line[4]
    @data_record[:house_number] = line[5]
    @data_record[:house_or_street_name] = line[6]
    @data_record[:uncertainy_location] = line[7]
    @data_record[:surname] = line[8]
    @data_record[:forenames] = line[9]
    @data_record[:uncertainty_name] = line[10]
    @data_record[:relationship] = line[11]
    @data_record[:marital_status] = line[12]
    @data_record[:sex] = line[13]
    @data_record[:age] = line[14]
    @data_record[:uncertainty_status] = line[15]
    @data_record[:occupation] = line[16]
    @data_record[:occupation_category] = line[17]
    @data_record[:uncertainty_occupation] = line[18]
    @data_record[:verbatim_birth_county] = line[19]
    @data_record[:verbatim_birth_place] = line[20]
    @data_record[:uncertainy_birth] = line[21]
    @data_record[:disability] = line[22]
    @data_record[:language] = line[23]
    @data_record[:notes] = line[24]
    @data_record[:record_number] = num
    @data_records << @data_record
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


  def extract_dwelling(csvrecords, csvfile, project, line)
    #p "extracting baptism"
    FreeregOptionsConstants::ORIGINAL_BAPTISM_FIELDS.each do |field|
      field_symbol = field.to_sym
      @data_record[field_symbol] = avoid_look_up_of_nil_field(@data_line,field,csvrecords)
    end
    if csvfile.header[:def]
      FreeregOptionsConstants::ADDITIONAL_BAPTISM_FIELDS.each do |field|
        field_symbol = field.to_sym
        @data_record[field_symbol] = avoid_look_up_of_nil_field(@data_line,field,csvrecords)
      end
    end
    FreeregOptionsConstants::ORIGINAL_COMMON_FIELDS.each do |field|
      field_symbol = field.to_sym
      @data_record[field_symbol] = avoid_look_up_of_nil_field(@data_line,field,csvrecords)
    end
    if csvfile.header[:def]
      FreeregOptionsConstants::ADDITIONAL_COMMON_FIELDS.each do |field|
        field_symbol = field.to_sym
        @data_record[field_symbol] = avoid_look_up_of_nil_field(@data_line,field,csvrecords)
      end
    end
    @data_record[:line_id] = csvfile.header[:userid] + "." + csvfile.header[:file_name] + "." + line.to_s
    @data_record[:file_line_number] = line
    @data_record[:year] = FreeregValidations.year_extract(@data_record[:baptism_date])
    @data_record[:year] = FreeregValidations.year_extract(@data_record[:birth_date]) if @data_record[:year].blank?
    @data_record[:year] = FreeregValidations.year_extract(@data_record[:confirmation_date]) if @data_record[:year].blank?
    @data_record[:year] = FreeregValidations.year_extract(@data_record[:received_into_church_date]) if @data_record[:year].blank?
    (@data_record[:private_baptism].present? && FreeregOptionsConstants::PRIVATE_BAPTISM_OPTIONS.include?(@data_record[:private_baptism].downcase)) ? @data_record[:private_baptism] = true : @data_record[:private_baptism] = false
    @data_record[:person_sex] = process_baptism_sex_field(@data_record[:person_sex])
    @data_record[:father_surname] = Unicode::upcase(@data_record[:father_surname] ) unless @data_record[:father_surname] .nil?
    @data_record[:mother_surname] = Unicode::upcase(@data_record[:mother_surname]) unless  @data_record[:mother_surname].nil?
    @data_record[:processed_date] = Time.now
    csvfile.data[line] = @data_record
  end

  def process_burial_data_fields(csvrecords,csvfile,project,line)
    #p "Extracting burial"
    FreeregOptionsConstants::ORIGINAL_BURIAL_FIELDS.each do |field|
      field_symbol = field.to_sym
      @data_record[field_symbol] = avoid_look_up_of_nil_field(@data_line,field,csvrecords)
    end
    if csvfile.header[:def]
      FreeregOptionsConstants::ADDITIONAL_BURIAL_FIELDS.each do |field|
        field_symbol = field.to_sym
        @data_record[field_symbol] = avoid_look_up_of_nil_field(@data_line,field,csvrecords)
      end
    end
    FreeregOptionsConstants::ORIGINAL_COMMON_FIELDS.each do |field|
      field_symbol = field.to_sym
      @data_record[field_symbol] = avoid_look_up_of_nil_field(@data_line,field,csvrecords)
    end
    if csvfile.header[:def]
      FreeregOptionsConstants::ADDITIONAL_COMMON_FIELDS.each do |field|
        field_symbol = field.to_sym
        @data_record[field_symbol] = avoid_look_up_of_nil_field(@data_line,field,csvrecords)
      end
    end
    @data_record[:line_id] = csvfile.header[:userid] + "." + csvfile.header[:file_name] + "." + line.to_s
    @data_record[:file_line_number] = line
    @data_record[:year] = FreeregValidations.year_extract(@data_record[:burial_date])
    @data_record[:year] = FreeregValidations.year_extract(@data_record[:death_date]) if @data_record[:year].blank?
    @data_record[:relative_surname] = Unicode::upcase(@data_record[:relative_surname]) unless @data_record[:relative_surname].nil?
    @data_record[:burial_person_surname] = Unicode::upcase( @data_record[:burial_person_surname])  unless @data_record[:burial_person_surname].nil?
    @data_record[:female_relative_surname] = Unicode::upcase( @data_record[:female_relative_surname])  unless @data_record[:female_relative_surname].nil?
    @data_record[:processed_date] = Time.now
    csvfile.data[line] = @data_record

  end

  def process_marriage_data_fields(csvrecords,csvfile,project,line)
    #p "extracting marriage"
    FreeregOptionsConstants::ORIGINAL_MARRIAGE_FIELDS.each do |field|
      field_symbol = field.to_sym
      @data_record[field_symbol] = avoid_look_up_of_nil_field(@data_line,field,csvrecords)
    end
    if csvfile.header[:def]
      FreeregOptionsConstants::ADDITIONAL_MARRIAGE_FIELDS.each do |field|
        field_symbol = field.to_sym
        @data_record[field_symbol] = avoid_look_up_of_nil_field(@data_line,field,csvrecords)
      end
    end
    FreeregOptionsConstants::ORIGINAL_COMMON_FIELDS.each do |field|
      field_symbol = field.to_sym
      @data_record[field_symbol] = avoid_look_up_of_nil_field(@data_line,field,csvrecords)
    end
    if csvfile.header[:def]
      FreeregOptionsConstants::ADDITIONAL_COMMON_FIELDS.each do |field|
        field_symbol = field.to_sym
        @data_record[field_symbol] = avoid_look_up_of_nil_field(@data_line,field,csvrecords)
      end
    end
    @data_record[:line_id] = csvfile.header[:userid] + "." + csvfile.header[:file_name] + "." + line.to_s
    @data_record[:file_line_number] = line
    @data_record[:year] = FreeregValidations.year_extract(@data_record[:marriage_date])
    @data_record[:year] = FreeregValidations.year_extract(@data_record[:contract_date]) if @data_record[:year].blank?
    (@data_record[:marriage_by_licence].present? && FreeregOptionsConstants::MARRIAGE_BY_LICENCE_OPTIONS.include?(@data_record[:marriage_by_licence].downcase)) ? @data_record[:marriage_by_licence] = true : @data_record[:marriage_by_licence] = false
    (@data_record[:groom_marked].present? && FreeregOptionsConstants::MARKED_OPTIONS.include?(@data_record[:groom_marked].downcase)) ? @data_record[:groom_marked] = true : @data_record[:groom_marked] = false
    (@data_record[:bride_marked].present? && FreeregOptionsConstants::MARKED_OPTIONS.include?(@data_record[:bride_marked].downcase)) ? @data_record[:bride_marked] = true : @data_record[:bride_marked] = false
    @data_record[:processed_date] = Time.now
    csvfile.data[line] = @data_record
  end

  def  process_baptism_sex_field(field)
    case
    when field.nil?
      return_field = "?"
    when FreeregValidations::UNCERTAIN_SEX.include?(field.upcase)
      return_field = field
    when FreeregValidations::VALID_MALE_SEX.include?(field.upcase)
      return_field = "M"
    when FreeregValidations::UNCERTAIN_MALE_SEX.include?(field.upcase)
      return_field = "M?"
    when FreeregValidations::VALID_FEMALE_SEX.include?(field.upcase)
      return_field = "F"
    when FreeregValidations::UNCERTAIN_FEMALE_SEX.include?(field.upcase)
      return_field = "F?"
    when field =~ FreeregValidations::VALID_UCF
      return_field = "?"
    else
      return_field = field
    end
    return return_field
  end


  def validate_church_and_set(church_name,chapman_code,place_name)
    place = Place.chapman_code(chapman_code).place(place_name).not_disabled.first
    return false, "No match" if place.blank? || place.churches.blank?
    place.churches.each do |church|
      if church.church_name.downcase == church_name.downcase
        return true, church.church_name
      end
    end
    return false, "No match"
  end
  def validate_place_and_set(field,chapman)
    field = field.gsub(/-/, " ").gsub(/\./, "").gsub(/\'/, "").downcase unless field.blank?
    place = Place.chapman_code(chapman).modified_place_name(field).not_disabled.first
    return false unless place.present?
    return true, place.place_name
  end

  def field_actually_exists_in_def(field,csvrecords)
    csvrecords.data_entry_order.has_key?(field) ? result = true : result = false
    result
  end

  def avoid_look_up_of_nil_field(line,record,csvrecords)
    record = record.to_sym
    field_actually_exists_in_def(record,csvrecords) ? result = line[csvrecords.data_entry_order[record]] : result = nil
    result
  end


end
