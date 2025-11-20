# -*- coding: utf-8 -*-

class NewFreeregCsvUpdateProcessor
  # This class processes a file or files of CSV records.
  # It converts them into entries and stores them in the freereg1_csv_entries collection
  require "csv"
  require 'email_veracity'
  require 'text'
  require "unicode"
  require 'chapman_code'
  require "#{Rails.root}/app/models/freereg1_csv_file"
  require "#{Rails.root}/app/models/freereg1_csv_entry"
  require "record_type"
  require "register_type"
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


  # It uses NewFreeregCsvUpdateProcessor as a class
  # The main entry point is activate_project to set up an instance of NewFreeregCsvUpdateProcessor to communication with the userid and the manager
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
  attr_accessor :freereg_files_directory,:create_search_records,:type_of_project,:force_rebuild,
    :file_range,:message_file,:member_message_file,:project_start_time,:total_records, :total_files,:total_data_errors, :records_processed, :success

  def initialize(arg1,arg2,arg3,arg4,arg5,arg6)
    @create_search_records = arg2
    @file_range = arg5
    @force_rebuild = arg4
    @freereg_files_directory = arg1
    @message_file = define_message_file
    @project_start_time = arg6
    @total_data_errors = 0
    @total_files = 0
    @total_records = 0
    @type_of_project = arg3
    EmailVeracity::Config[:skip_lookup]=true
  end

  def self.create_rake_lock_file
    @rake_lock_file = Rails.root.join('tmp', 'processing_rake_lock_file.txt')
    @locking_file = File.new(@rake_lock_file, 'w')
    p "FREEREG:CSV_PROCESSING: Created rake lock file #{@rake_lock_file} and processing files"
  end

  def self.check_file_lock_status
    @rake_lock_file = Rails.root.join('tmp', 'processing_rake_lock_file.txt')
    @locking_file = File.open(@rake_lock_file)
    locked = @locking_file.flock(File::LOCK_EX | File::LOCK_NB)
    p "processor lock file status: #{locked}"
    locked
  end

  def self.process_activate_project(create_search_records,type,force,range)
    while PhysicalFile.waiting.exists?
      p "Locking file: #{@rake_lock_file}"
      @locking_file.flock(File::LOCK_EX)
      self.activate_project(create_search_records, type, force, range)
      sleep(300)
    end
    p "Removing lock on #{@rake_lock_file}" 
    @locking_file.flock(File::LOCK_UN)
    p 'FREEREG:CSV_PROCESSING: removing rake lock file'
    if File.exist?(@rake_lock_file)
      x = File.open(@rake_lock_file)
      x.close
      FileUtils.rm_f(@rake_lock_file)
    end
    if File.exist?(Rails.root.join('tmp/processor_initiation_lock_file.txt'))
      p 'FREEREG:CSV_PROCESSING: Removing Initiation lock'
      x = File.open(Rails.root.join('tmp/processor_initiation_lock_file.txt'))
      x.close
      FileUtils.rm_f(x)
    end
  end

  def self.activate_project(create_search_records,type,force,range)
    force, create_search_records = NewFreeregCsvUpdateProcessor.convert_to_bolean(create_search_records,force)
    @project = NewFreeregCsvUpdateProcessor.new(Rails.application.config.datafiles,create_search_records,type,force,range,Time.new)
    @project.write_log_file("Started csv file processor project. #{@project.inspect} using website #{Rails.application.config.website}. <br>")
    @csvfiles = CsvFiles.new
    success, files_to_be_processed = @csvfiles.get_the_files_to_be_processed(@project)
    if !success || (files_to_be_processed.present? && files_to_be_processed.length == 0)
      @project.write_log_file("processing terminated as we have no records to process. <br>")
      return
    end
    @project.write_log_file("#{files_to_be_processed.length}\t files selected for processing. <br>")
    files_to_be_processed.each do |file|
      @csvfile = CsvFile.new(file)
      @success, @records_processed, @data_errors = @csvfile.a_single_csv_file_process(@project)
      if @success
        @project.total_records = @project.total_records + @records_processed unless @records_processed.nil?
        @project.total_data_errors = @project.total_data_errors + @data_errors if @data_errors.present?
        @project.total_files += 1
      else
        @csvfile.clean_up_physical_files_after_failure(@records_processed)
        @csvfile.communicate_failure_to_member(@project,@records_processed)
        #@project.communicate_to_managers(@csvfile.total_records)
        @project.total_files += 1
        #@project.communicate_to_managers(@csvfile) if @project.type_of_project == "individual"
      end
      sleep(100) #if Rails.env.production?
    end
  end

  def self.delete_all
    Freereg1CsvEntry.destroy_all
    Freereg1CsvFile.destroy_all
    SearchRecord.delete_freereg1_csv_entries
  end

  def self.qualify_path(path)
    unless path.match(/^\//) || path.match(/:/) # unix root or windows
      path = File.join(Rails.root, path)
    end
    path
  end

  def communicate_to_managers(csvfile)
    records = @total_records
    average_time = records == 0 ? 0 : (Time.new.to_i - @project_start_time.to_i) * 1000 / records
    write_messages_to_all("Created  #{records} entries at an average time of #{average_time}ms per record at #{Time.new}. <br>", false)
    file = @message_file
    # @message_file.close if @project.type_of_project == "individual"
    user = UseridDetail.where(userid: 'REGManager').first
    UserMailer.update_report_to_freereg_manager(file, user).deliver_now
  end

  def self.convert_to_bolean(create_search_records, force)
    create_search_records =  create_search_records == 'create_search_records' ? true : false
    force = force == 'force_rebuild' ? true : false
    [force, create_search_records]
  end

  def define_message_file
    file_for_warning_messages = File.join(Rails.root,"log/update_freereg_messages")
    time = Time.new
    tnsec = time.nsec / 1000
    time = time.to_i.to_s + tnsec.to_s
    file_for_warning_messages = (file_for_warning_messages + "_" + time + ".log").to_s
    message_file = File.new(file_for_warning_messages, "w")
    message_file.chmod( 0664 )
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

class CsvFiles < NewFreeregCsvUpdateProcessor

  def initialize
  end

  def get_the_files_to_be_processed(project)
    #  p "Getting files"
    case project.type_of_project
    when "waiting"
      files = self.get_the_waiting_files_to_be_processed(project)
    when "range"
      files = self.get_the_range_files_to_be_processed(project)
    when "individual"
      files = self.get_the_individual_file_to_be_processed(project)
    when "special_selection_1"
      # this is designed to correct the location and search record creation bug that existed for 2 days
      files = self.get_the_special_selection_1_files_to_be_processed(project)
      # this is designed to correct the failure to record the uploaded date and the LDS type
    when "special_selection_2"
      files = self.get_the_special_selection_2_files_to_be_processed(project)
    end
    return true,files
  end

  # GetFile is a lib task
  def get_the_individual_file_to_be_processed(project)
    #p "individual file selection"
    files = GetFiles.get_all_of_the_filenames(project.freereg_files_directory,project.file_range)
    files
  end

  def get_the_range_files_to_be_processed(project)
    #p "range file selection"
    files = GetFiles.get_all_of_the_filenames(project.freereg_files_directory,project.file_range)
    files
  end

  def get_the_special_selection_1_files_to_be_processed(project)
    # p "special selection 1 files"
    time_start = Time.utc(2016,"apr",29,01,23,0)
    time_end = Time.utc(2016,"may",02,0,30,0)
    # p time_start
    # p time_end
    time_start = time_start.to_f
    time_end = time_end.to_f
    files = Array.new
    total_entries = 0
    PhysicalFile.all.no_timeout.each do |file|
      processed = file.file_processed_date
      if processed.present?
        processed = processed.to_time.to_f
        if processed.between?(time_start, time_end)
          affected_file = File.join(project.freereg_files_directory, file.userid, file.file_name)
          files << affected_file
          actual_file = Freereg1CsvFile.userid(file.userid).file_name(file.file_name).first
          total_entries += actual_file.freereg1_csv_entries.count if actual_file.present?
        end
      end
    end
    #p "#{files.length} met the selection criteria with #{total_entries} entries"
    files
  end
  def get_the_special_selection_2_files_to_be_processed(project)
    # p "special selection 2 files"
    time_start = Time.utc(2016,"may",02,0,19,1)
    time_end = Time.utc(2016,"may",04,0,30,0,)
    # p time_start
    # p time_end
    time_start = time_start.to_f
    time_end = time_end.to_f
    files = Array.new
    total_entries = 0
    PhysicalFile.all.no_timeout.each do |file|
      processed = file.file_processed_date
      if processed.present?
        processed = processed.to_time.to_f
        if processed.between?(time_start, time_end)
          affected_file = File.join(project.freereg_files_directory, file.userid, file.file_name)
          files << affected_file
          actual_file = Freereg1CsvFile.userid(file.userid).file_name(file.file_name).first
          total_entries = total_entries + actual_file.freereg1_csv_entries.count unless actual_file.blank?
        end
      end
    end
    #p "#{files.length} met the selection criteria with #{total_entries} entries"
    return files
  end


  def get_the_waiting_files_to_be_processed(project)
    #p "waiting file selection"
    physical_waiting_files = PhysicalFile.waiting.all.order_by(waiting_date: 1)
    files = Array.new
    physical_waiting_files.each do |file|
      files << File.join(project.freereg_files_directory, file.userid, file.file_name)
    end
    return files
  end
end

class CsvFile < CsvFiles

  #initializes variables
  #gets information on the file to be processed

  attr_accessor :header, :list_of_registers, :header_error, :system_error, :data_hold,
    :array_of_data_lines, :default_charset, :file, :file_name, :userid, :uploaded_date, :slurp_fail_message,
    :file_start, :file_locations, :data, :unique_locations, :unique_existing_locations, :success,
    :all_existing_records, :total_files, :total_records, :total_data_errors, :total_header_errors, :place_id, :uploaded_file_is_flexible_format
  def initialize(file)
    standalone_filename = File.basename(file)
    full_dirname = File.dirname(file)
    parent_dirname = File.dirname(full_dirname)
    user_dirname = full_dirname.sub(parent_dirname, '').gsub(File::SEPARATOR, '')
    @all_existing_records = Hash.new
    @array_of_data_lines = Array.new {Array.new}
    @data = Hash.new
    @default_charset = "Windows-1252"
    @file = file
    @file_locations = Hash.new
    @file_name = standalone_filename
    @file_start =  nil
    @uploaded_date = Time.new
    @uploaded_date = File.mtime(file) if File.exists?(file)
    @header_error = Array.new()
    @header = Hash.new
    @header[:digest] = Digest::MD5.file(file).hexdigest if File.exists?(file)
    @header[:file_name] = standalone_filename #do not capitalize filenames
    @header[:userid] = user_dirname
    @header[:uploaded_date] = @uploaded_date
    @header[:def] = false
    @header[:lds] = "no"
    server = SoftwareVersion.extract_server(Socket.gethostname)
    @software_version = SoftwareVersion.server(server).app('freereg').control.first
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
    @unique_existing_locations = Hash.new
    @unique_locations = Hash.new
    @uploaded_file_is_flexible_format = false
  end

  def a_single_csv_file_process(project)
    #p "single csv file"
    begin
      @success = true
      project.member_message_file = self.define_member_message_file
      @file_start = Time.new
      p "FREEREG:CSV_PROCESSING: Started on the file #{@header[:file_name]} for #{@header[:userid]} at #{@file_start}"
      project.write_log_file("******************************************************************* <br>")
      project.write_messages_to_all("Started on the file #{@header[:file_name]} for #{@header[:userid]} at #{@file_start}. <p>", true)
      @success, message = self.ensure_processable?(project) unless project.force_rebuild
      #p "finished file checking #{message}. <br>"
      return false, message unless @success

      @success, message = self.slurp_the_csv_file(project)
      return [false, message] unless @success

      @csv_records = CsvRecords.new(@array_of_data_lines)
      @success, message = @csv_records.separate_into_header_and_data_lines(self,project)
      #p "got header and data lines"
      return [false, "lines not extracted #{message}. <br>"] unless @success

      @success, message = @csv_records.get_the_file_information_from_the_headers(self,project)
      #p "finished header"
      return [@success,"header errors"] unless @success

      @success,@records_processed = @csv_records.extract_the_data(self,project)
      #p "finished data"
      return [@success,"Data not extracted #{@records_processed}. <br>"] unless @success

      @success, @records_processed, @data_errors = self.process_the_data(project) if @success
      return [@success,"Data not processed #{@records_processed}. <br>"] unless @success

      @success, message = self.clean_up_supporting_information(project)
      # p "finished clean up"
      records = @total_records
      time = ((Time.new.to_i - @file_start.to_i) * 1000) / records unless records.zero?
      project.write_messages_to_all("Created  #{@total_records} entries at an average time of #{time}ms per record at #{Time.new}. <br>", true)
      return [@success, "clean up failed #{message}. <br>"] unless @success

      @success, message = self.communicate_file_processing_results(project)
      # p "finished com"
      # p @success
      return [@success, "communication failed #{message}. <br>"] unless @success

    rescue => e
      p "FREEREG:CSV_PROCESSOR_FAILURE: #{e.message}"
      p "FREEREG:CSV_PROCESSOR_FAILURE: #{e.backtrace.inspect}"
      error_message = " We were unable to complete the file #{@userid}\t#{@file_name}. because #{e.message} Please contact your coordinator or the System Administrator with this message.<br>"
      project.write_messages_to_all(error_message, true)
      project.write_messages_to_all("Rescued from crash #{e.message}", true)
      project.write_log_file("#{e.message}")
      project.write_log_file("#{e.backtrace.inspect}")
      @success = false
      @records_processed = e.message
      @data_errors = nil
    end
    [@success, @records_processed, @data_errors]
  end

  def change_location_for_existing_entry_and_record(existing_record, data_record, project, freereg1_csv_file)
    existing_record.update_location(data_record, freereg1_csv_file)
    #update location of record
    record = existing_record.search_record
    success = 'change'
    if record.blank?
      success = 'change'
      #transform_search_record is a method in freereg1_csv_entry.rb.rb
      # enough_name_fields is a method in freereg1_csv_entry.rb that ensures we have names to create a search record on
      place_id = self.place_id
      place = Place.id(place_id).first
      SearchRecord.update_create_search_record(existing_record,self.header[:search_record_version],place) if  project.create_search_records && existing_record.enough_name_fields?
      sleep_time = (Rails.application.config.sleep.to_f).to_f
      sleep(sleep_time)
    end
    success
  end

  def check_and_create_db_record_for_entry(project,data_record,freereg1_csv_file)
    #p " check and create"
    if !project.force_rebuild
      #p "processing create_db_record_for_entry"
      data_record.delete(:chapman_code)
      entry = Freereg1CsvEntry.new(data_record)
      #p "new entry"
      #p entry
      new_digest = entry.cal_digest
      if @all_existing_records.has_value?(new_digest)
        # p "we have an existing record but may be for different location"
        existing_record = Freereg1CsvEntry.id(@all_existing_records.key(new_digest)).first
        if existing_record.present?
          # p "yes we have a record"
          success = self.existing_entry_may_be_same_location(existing_record,data_record,project,freereg1_csv_file)
          #we need to eliminate this record from hash
          # p "dropping hash entry"
          @all_existing_records.delete(@all_existing_records.key(existing_record.record_digest))
        else
          # p "No record existed"
          success = self.create_db_record_for_entry(project,data_record,freereg1_csv_file)
        end
      else
        # p "no digest"
        success = self.create_db_record_for_entry(project,data_record,freereg1_csv_file)
      end
    else
      # p "rebuild"
      success = self.create_db_record_for_entry(project,data_record,freereg1_csv_file)
    end
    return success
  end

  def check_and_set_characterset(code_set,csvtxt,project)
    #if it looks like valid UTF-8 and we know it isn't
    #Windows-1252 because of undefined characters, then
    #default to UTF-8 instead of Windows-1252
    if code_set.nil? || code_set.empty? || code_set=="chset"
      #project.write_messages_to_all("Checking for undefined with #{code_set}",false)
      if csvtxt.index(0x81.chr) || csvtxt.index(0x8D.chr) ||
          csvtxt.index(0x8F.chr) || csvtxt.index(0x90.chr) ||
          csvtxt.index(0x9D.chr)
        #p 'undefined Windows-1252 chars, try UTF-8 default'
        #project.write_messages_to_all("Found undefined}",false)
        csvtxt.force_encoding('UTF-8')
        code_set = 'UTF-8' if csvtxt.valid_encoding?
        csvtxt.force_encoding('ASCII-8BIT')#convert later with replace
      end
    end
    code_set = self.default_charset if (code_set.blank? || code_set == "chset")
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
    return code_set, message, csvtxt
  end

  def check_file_exists?(project)
    #make sure file actually exists
    message = "The file #{@file_name} for #{@userid} does not exist. <br>"
    if File.exists?(@file)
      return true, "OK"
    else
      project.write_messages_to_all(message,true)
      return false,  message
    end
  end



  def check_file_is_not_locked?(batch,project)
    return true, "OK" if batch.blank?
    message = "The file #{batch.file_name} for #{batch.userid} is already on system and is locked against replacement. <br>"
    if batch.locked_by_transcriber || batch.locked_by_coordinator
      project.write_messages_to_all(message,true)
      return false,  message
    else
      return true, "OK"
    end
  end

  def check_userid_exists?(project)
    message = "The #{@userid} userid does not exist. <br>"
    if UseridDetail.userid(@userid).first.present?
      return true, "OK"
    else
      project.write_messages_to_all(message,true)
      return false,  message
    end
  end

  def clean_up_message(project)
    File.delete(project.message_file) if project.type_of_project == "individual" && File.exists?(project.message_file) && !Rails.env.test?
  end

  def clean_up_physical_files_after_failure(message)
    batch = PhysicalFile.userid(@userid).file_name(@file_name).first
    return true if batch.blank?

    PhysicalFile.remove_waiting_flag(@userid, @file_name)
    batch.update_attributes(file_processed_date: nil)
    batch.delete #if message.include?("header errors") || message.include?("does not exist. ") || message.include?("userid does not exist. ")
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
    # p "cleaning up batches and records"
    counter = 0
    files = Array.new
    @all_existing_records.each do |record,value|
      counter = counter + 1
      actual_record = Freereg1CsvEntry.id(record).first
      file_for_entry = actual_record.freereg1_csv_file_id unless actual_record.nil?
      files << file_for_entry unless files.include?(file_for_entry)
      actual_record.destroy unless actual_record.nil?
      sleep_time =  sleep_time = (Rails.application.config.sleep.to_f).to_f
      sleep(sleep_time) unless actual_record.nil?
    end
    #p 'recalculate distribution after clean up'
    files.each do |file|
      actual_batch = Freereg1CsvFile.id(file).first
      actual_batch.calculate_distribution if actual_batch.present?
    end
    @unique_existing_locations.each do |key, value|
      file = Freereg1CsvFile.id(value[:id]).first
      if file.present?
        message = "Removing batch #{file.county}, #{file.place}, #{file.church_name}, #{file.register_type}, #{file.record_type} for #{file.userid} #{file.file_name}. <br>"
        project.write_messages_to_all(message,false)
        file.delete
      end
    end
    counter
  end

  def communicate_failure_to_member(project, message)
    file = project.member_message_file
    file.close
    UserMailer.batch_processing_failure(file,@userid,@file_name).deliver_now unless project.type_of_project == "special_selection_1" ||  project.type_of_project == "special_selection_2"
    self.clean_up_message(project)
    return true
  end

  def communicate_file_processing_results(project)
    #  p "communicating success"
    file = project.member_message_file
    file.close
    UserMailer.batch_processing_success(file,@header[:userid],@header[:file_name]).deliver_now unless project.type_of_project == "special_selection_1" ||  project.type_of_project == "special_selection_2"
    self.clean_up_message(project)
    return true
  end

  def create_db_record_for_entry(project,data_record,freereg1_csv_file)
    # TODO: bring data_record hash keys in line with those in Freereg1CsvEntry
    #p "creating new entry"
    data_record.delete(:chapman_code)
    entry = Freereg1CsvEntry.new(data_record)
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
    file_for_member_messages = File.join(Rails.root,"log/#{self.userid}_member_update_messages")
    time = Time.new
    tnsec = time.nsec / 1000
    time = time.to_i.to_s + tnsec.to_s
    file_for_member_messages = (file_for_member_messages + "_" + time + ".log").to_s
    member_message_file = File.new(file_for_member_messages, "w")
    return member_message_file

  end


  def determine_if_utf8(csvtxt,project)
    #check for BOM and if found, assume corresponding
    # unicode encoding (unless invalid sequences found),
    # regardless of what user specified in column 5 since it
    # may have been edited and saved as unicode by coord
    # without updating col 5 to reflect the new encoding.
    #p "testing for BOM"
    if !csvtxt.nil? && csvtxt.length > 2
      if csvtxt[0].ord==0xEF && csvtxt[1].ord==0xBB && csvtxt[2].ord==0xBF
        #p "UTF-8 BOM found"
        #project.write_messages_to_all("BOM found",false)
        csvtxt = csvtxt[3..-1]#remove BOM
        code_set = 'UTF-8'
        self.slurp_fail_message = "BOM detected so using UTF8. <br>"
        csvtxt.force_encoding(code_set)
        if !csvtxt.valid_encoding?
          #project.write_messages_to_all("Not really a UTF8",false)
          #not really a UTF-8 file. probably was edited in
          #software that added BOM to beginning without
          #properly transcoding existing characters to UTF-8
          code_set = 'ASCII-8BIT'
          csvtxt.encode('ASCII-8BIT')
          csvtxt.force_encoding('ASCII-8BIT')
          #project.write_messages_to_all("Not really ASCII-8BIT",false) unless csvtxt.valid_encoding?
        else
          self.slurp_fail_message = "Using UTF8. <br>"
          csvtxt = csvtxt.encode('utf-8', :undef => :replace)
        end
      else
        code_set = nil
        #No BOM
        self.slurp_fail_message = nil
      end
    else
      #No BOM
      self.slurp_fail_message = nil
      code_set = nil
    end
    #project.write_messages_to_all("Code set #{code_set}",false)

    return code_set,csvtxt
  end

  def ensure_processable?(project)
    success, message = self.check_file_exists?(project)
    success, message = self.check_userid_exists?(project) if success
    batch = Freereg1CsvFile.userid(@userid).file_name(@file_name).first if success
    success, message = self.check_file_is_not_locked?(batch,project) if success
    return true, "OK" if success
    return false, message unless success
  end

  def existing_entry_may_be_same_location(existing_record, data_record, project, freereg1_csv_file)
    if existing_record.same_location(existing_record,freereg1_csv_file)
      # this method is located in entry model
      # p "same location"
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
      success = self.change_location_for_existing_entry_and_record(existing_record, data_record, project, freereg1_csv_file)
    end
    success
  end

  def extract_the_array_of_lines(csvtxt)
    #now get all the data
    self.slurp_fail_message = "the CSV parser failed. The CSV file might not be formatted correctly. <br>"
    @array_of_data_lines = CSV.parse(csvtxt, {:row_sep => "\r\n",:skip_blanks => true})
    #remove zzz fields and white space
    @array_of_data_lines.each do |line|
      line.each_index    {|x| line[x] = line[x].gsub(/zzz/, ' ').gsub(/\s+/, ' ').strip unless line[x].nil? }
    end
    @slurp_fail_message = nil # no exception thrown
    return true
  end

  def get_batch_locations_and_records_for_existing_file
    #p "getting existing locations"
    locations = Hash.new
    all_records_hash = Hash.new
    freereg1_csv_files = Freereg1CsvFile.where(:file_name => @header[:file_name], :userid => @header[:userid]).all
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
      batch.destroy
      #batch.update_attributes(:file_processed => false, :file_processed_date => nil,:waiting_to_be_processed => false, :waiting_date => nil)
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
    freereg1_csv_file = Freereg1CsvFile.where(:userid => @header[:userid],:file_name => @header[:file_name],:county => thisvalue[:chapman_code], :place => thisvalue[:place_name], :church_name => thisvalue[:church_name], :register_type => thisvalue[:register_type], :record_type =>@header[:record_type]).first
    #:place => value[:place_name], :church_name => value[:church_name], :register_type => value[:register_type], :record_type =>@header[:record_type]
    if freereg1_csv_file.nil?
      freereg1_csv_file = Freereg1CsvFile.new(batch_header)
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
    #p "starting the slurp"
    #read entire .csv as binary text (no encoding/conversion)
    success = true
    csvtxt = File.open(@file, "rb", :encoding => "ASCII-8BIT:ASCII-8BIT"){|f| f.read}
    project.write_messages_to_all("Empty file", true) if csvtxt.blank?
    return false if csvtxt.blank?

    code, csvtxt = self.determine_if_utf8(csvtxt,project)
    code = self.get_codeset_from_header(code,csvtxt,project)
    code, message, csvtxt = self.check_and_set_characterset(code, csvtxt, project)
    csvtxt = self.standardize_line_endings(csvtxt)
    success = self.extract_the_array_of_lines(csvtxt)
    [success, message]
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
    @total_records = @total_records + records
    @total_data_errors = @total_data_errors + batch_errors
    freereg1_csv_file.reload
    freereg1_csv_file.calculate_distribution
    freereg1_csv_file.update_attribute(:processed, false) if !project.create_search_records
    freereg1_csv_file.update_attributes(:processed => true, :processed_date => Time.new) if project.create_search_records
    freereg1_csv_file.update_attributes(:error => batch_errors)
  end
end


class CsvRecords <  CsvFile

  attr_accessor :array_of_lines, :header_lines, :data_lines, :data_entry_order

  def initialize(data_array)
    @array_of_lines = data_array
    @data_entry_order = Hash.new
    @data_lines = Array.new {Array.new}
    @header_lines = Array.new {Array.new}
  end

  def separate_into_header_and_data_lines(csvfile,project)
    #p "Getting header and data lines"
    n = 0
    @array_of_lines.each do |line|
      n = n + 1
      first_character = "?"
      first_character = line[0].slice(0) unless  line[0].nil?
      if (first_character == "+" || first_character ==  "#") || line[0] =~ FreeregOptionsConstants::HEADER_DETECTION
        @header_lines << line
      else
        @data_lines << line
      end
    end
    return true
  end

  def extract_from_header_one(header_field,csvfile)
    #process the header line 1
    # eg +INFO,David@davejo.eclipse.co.uk,password,SEQUENCED,BURIALS,cp850,,,,,,,
    csvfile.header_error << "First line of file does not start with +INFO it has #{header_field[0]}. <br>" unless (header_field[0] =~ FreeregOptionsConstants::HEADER_DETECTION)
    #We only use the file email address where there is not one in the userid #csvfile.header[:transcriber_email] = header_line[1]
    userid  = UseridDetail.userid(csvfile.header[:userid]).first
    new_email = userid.email_address if userid.present?
    csvfile.header[:transcriber_email] = new_email unless new_email.nil?
    csvfile.header_error << "Invalid file type #{header_field[4]} in first line of header. <br>" if header_field[4].blank? || !FreeregOptionsConstants::VALID_RECORD_TYPE.include?(header_field[4].gsub(/\s+/, ' ').strip.upcase)
    # canonicalize record type
    scrubbed_record_type = Unicode::upcase(header_field[4]).gsub(/\s/, '') unless header_field[4].blank?
    csvfile.header[:record_type] =  FreeregOptionsConstants::RECORD_TYPE_TRANSLATION[scrubbed_record_type] unless header_field[4].blank? || !FreeregOptionsConstants::VALID_RECORD_TYPE.include?(header_field[4].gsub(/\s+/, ' ').strip.upcase)
    #assumes Baptism to allow processing of rest of headers to proceed
    csvfile.header[:record_type] = "ba" if  header_field[4].blank? || !FreeregOptionsConstants::VALID_RECORD_TYPE.include?(header_field[4].gsub(/\s+/, ' ').strip.upcase)
    if csvfile.header_error.present?
      return false
    else
      return true
    end
  end

  def extract_from_header_two(header_field,csvfile)
    #process the header line 2
    # eg #,CCCC,David Newbury,Derbyshire,dbysmalbur.CSV,02-Mar-05,,,,,,,
    header_field = header_field.compact
    number_of_fields = header_field.length
    csvfile.header_error << "The second header line is completely empty; please check the file for blank lines. <br>" if number_of_fields == 0
    header_field[1] = header_field[1].upcase unless header_field[1].nil?
    case
    when header_field[0] =~ FreeregOptionsConstants::HEADER_FLAG && header_field[1] =~ FreeregOptionsConstants::VALID_CCC_CODE
      #deal with correctly formatted header
      process_header_line_two_block(header_field,csvfile)
    when number_of_fields == 1 && header_field[0] =~ FreeregOptionsConstants::HEADER_FLAG
      #empty line
      csvfile.header_error << "The second header line has no usable fields.<br>"
      return true
    when number_of_fields == 4 && header_field[0].length > 1
      #deal with #transcriber
      process_header_line_two_transcriber(header_field,csvfile)
    when number_of_fields == 4 && header_field[0] =~ FreeregOptionsConstants::HEADER_FLAG
      # missing a field somewhere; assume date and file name are there and put other field in the transcriber
      process_header_line_two_missing_field(header_field,csvfile)
    when number_of_fields == 5 && header_field[1].length > 1 && header_field[0] =~ FreeregOptionsConstants::HEADER_FLAG
      #,transcriber,syndicate,file,date
      process_header_line_two_missing_two_fields(header_field,csvfile)
    when number_of_fields == 5 && header_field[0].length > 1
      #deal with missing , between #and ccc
      process_header_line_two_missing_comma(header_field,csvfile)
    when number_of_fields == 6 && header_field[1].length > 1 && header_field[0].slice(0) =~ FreeregOptionsConstants::HEADER_FLAG
      #,transcriber,syndicate,file,date,
      process_header_line_two_block(header_field,csvfile)
    when number_of_fields == 6 && header_field[1].length > 1 && header_field[0] =~ FreeregOptionsConstants::HEADER_FLAG
      ##,XXXX,David Newbury,Derbyshire,dbysmalbur.CSV,02-Mar-05,
      process_header_line_two_block(header_field,csvfile)
    when number_of_fields == 7
      #the basic EricD format #,Eric Dickens,Gloucestershire Bisley MA,GLSBISMA.csv,GLSBISMA.csv,28-Oct-2008,CSV
      process_header_line_two_block_eric_special(header_field,csvfile)
    else
      csvfile.header_error << "I did not know enough about your data format to extract transcriber information at header line 2. <br>"
      return true
    end
    if csvfile.header_error.present?
      return false
    else
      return true
    end
  end

  def process_header_line_two_block_eric_special(header_field,csvfile)
    eric = Array.new
    eric[2] = header_field[1]
    eric[3] = header_field[2]
    eric[4] = header_field[4]
    eric[5] = header_field[5]
    i = 2
    while i < 6
      header_field[i] = eric[i]
      i +=1
    end
    process_header_line_two_block(header_field,csvfile)
  end

  def process_header_line_two_missing_comma(header_field,csvfile)
    header_field[5] = header_field[4]
    header_field[4] = header_field[3]
    header_field[3] = header_field[2]
    header_field[2] = header_field[1]
    process_header_line_two_block(header_field,csvfile)
  end

  def process_header_line_two_missing_two_fields(header_field,csvfile)
    header_field[5] = header_field[4]
    header_field[4] = header_field[3]
    header_field[3] = header_field[2]
    header_field[2] = header_field[1]
    process_header_line_two_block(header_field,csvfile)
  end

  def process_header_line_two_missing_field(header_field,csvfile)
    header_field[5] = header_field[3]
    header_field[4] = header_field[2]
    header_field[2] = header_field[1]
    process_header_line_two_block(header_field,csvfile)
  end

  def process_header_line_two_transcriber(header_field,csvfile)
    i = 0
    while i < 4
      header_field[5-i] = header_field[3-i]
      i +=1
    end
    header_field[2] = header_field[2].gsub(/#/, '')
    process_header_line_two_block(header_field,csvfile)
  end

  def process_header_line_two_block(header_field,csvfile)
    csvfile.header_error << "The transcriber's name #{header_field[2]} can only contain alphabetic and space characters in the second header line. <br>" unless FreeregValidations.cleantext(header_field[2])
    csvfile.header[:transcriber_name] = header_field[2]
    csvfile.header_error << "The syndicate can only contain alphabetic and space characters in the second header line. <br>" unless FreeregValidations.cleantext(header_field[3])
    csvfile.header[:transcriber_syndicate] = header_field[3]
    header_field[5] = '01 Jan 1998' unless FreeregValidations.modern_date_valid?(header_field[5])
    csvfile.header[:transcription_date] = header_field[5]
    userid = UseridDetail.where(:userid => csvfile.header[:userid] ).first
    csvfile.header[:transcriber_syndicate] = userid.syndicate unless userid.nil?
  end

  def extract_from_header_three(header_field,csvfile)
    # => process the csvfile.headerer line 3
    # eg #,Credit,Libby,email address,,,,,,
    header_field = header_field.compact
    number_of_fields = header_field.length
    case
    when number_of_fields == 0
      csvfile.header_error << "The third header line is completely empty; please check the file for blank lines. <br>"
      return true
    when (header_field[0] =~ FreeregOptionsConstants::HEADER_FLAG &&  FreeregOptionsConstants::VALID_CREDIT_CODE.include?(header_field[1]))
      #the normal case
      process_header_line_three_block(header_field,csvfile)
    when number_of_fields == 1 && header_field[0] =~FreeregOptionsConstants::HEADER_FLAG
      #no information just keep going
      csvfile.header_error << "The third header line has no usable fields. <br>"
      return true
    when number_of_fields == 2 && !FreeregOptionsConstants::VALID_CREDIT_CODE.include?(header_field[1])
      #eric special #,Credit name
      process_header_line_three_eric_special(header_field,csvfile)
    when number_of_fields == 3 && !FreeregOptionsConstants::VALID_CREDIT_CODE.include?(header_field[1])
      #,Credit name,
      csvfile.header[:credit_name] = header_field[1] if !header_field[1].length == 1
    when number_of_fields == 4 && !FreeregOptionsConstants::VALID_CREDIT_CODE.include?(header_field[1])
      #,Credit name,,
      csvfile.header[:credit_name] = header_field[1] if !header_field[1].length == 1
    when number_of_fields == 5 && header_field[1].nil?
      #and extra comma
      process_header_line_three_five_fields(header_field,csvfile)
    else
      csvfile.header_error << "I did not know enough about your data format to extract Credit Information at header line 3. <br>"
      return true
    end
    if csvfile.header_error.present?
      return false
    else
      return true
    end
  end

  def process_header_line_three_five_fields(header_field,csvfile)
    header_field[2] = header_field[3]
    header_field[3] = header_field[4]
    process_header_line_three_block(header_field,csvfile)
  end

  def process_header_line_three_eric_special(header_field,csvfile)
    a = header_field[1].split(" ")
    csvfile.header[:credit_name] = a[1] if a.length == 1
    a = a.drop(1)
    csvfile.header[:credit_name] = a.join(" ")
  end

  def process_header_line_three_block(header_field,csvfile)
    csvfile.header_error << "The credit name #{header_field[2]} cannot contain what might be an email address in the third field of the third header line. <br>" unless FreeregValidations.cleancredit(header_field[2])
    csvfile.header[:credit_name] = header_field[2]
    #csvfile.header[:credit_email] = header_field[3]
    # # suppressing for the moment
    # address = EmailVeracity::Address.new(header_field[3])
    # raise FreeREGError, "Invalid email address '#{header_field[3]}' for the credit person or organization in the forth field of the third line of header" unless address.valid? || header_field[3].nil?
  end

  def extract_from_header_four(header_field,csvfile)
    header_field = header_field.compact
    number_of_fields = header_field.length
    @modern_date_field_0 = FreeregValidations.modern_date_valid?(header_field[0])
    @modern_date_field_1 = FreeregValidations.modern_date_valid?(header_field[1])
    @modern_date_field_2 = FreeregValidations.modern_date_valid?(header_field[2])
    case
    when number_of_fields == 0
      csvfile.header_error << "The forth header line is completely empty; please check the file for blank lines. <br>"
      retrn true
    when number_of_fields == 4 && header_field[0] =~FreeregOptionsConstants::HEADER_FLAG && @modern_date_field_1
      #the normal case
      process_header_line_four_block(header_field,csvfile)
    when (number_of_fields == 1 && header_field[0] =~FreeregOptionsConstants::HEADER_FLAG)
      # an empty line follows the #
      csvfile.header[:modification_date] = Date.today.strftime("%d %b %Y")
    when (number_of_fields == 1 && !(header_field[0] =~FreeregOptionsConstants::HEADER_FLAG))
      # is an # followed by something either  date or a comment
      process_header_line_four_date_or_comment(header_field,csvfile)
    when (number_of_fields == 2 && header_field[0] =~FreeregOptionsConstants::HEADER_FLAG && @modern_date_field_2)
      #date and no notes
      csvfile.header[:modification_date] = header_field[1]
    when number_of_fields == 2 && header_field[0] =~FreeregOptionsConstants::HEADER_FLAG
      # only a single comment
      csvfile.header[:first_comment] = header_field[1]
    when number_of_fields == 2 && !(header_field[0] =~FreeregOptionsConstants::HEADER_FLAG)
      #date only a single comment but no comma with date in either field
      process_header_line_four_no_comma_and_date_or_comment(header_field,csvfile)
    when (number_of_fields == 3 && header_field[0] =~FreeregOptionsConstants::HEADER_FLAG && @modern_date_field_1)
      # date and one note
      csvfile.header[:modification_date] = header_field[1]
      csvfile.header[:first_comment] = header_field[2]
    when (number_of_fields == 3 && header_field[0] =~FreeregOptionsConstants::HEADER_FLAG && @modern_date_field_2)
      #one note and a date
      csvfile.header[:modification_date] = header_field[2]
      csvfile.header[:first_comment] = header_field[1]
    when number_of_fields == 3  && header_field[0] =~FreeregOptionsConstants::HEADER_FLAG
      # Many comments
      header_field = header_field.drop(1)
      csvfile.header[:first_comment] = header_field.join(" ")
    when (number_of_fields == 4 && header_field[0] =~FreeregOptionsConstants::HEADER_FLAG && @modern_date_field_1)
      #date and 3 comments
      csvfile.header[:modification_date] = header_field[2]
      header_field = header_field.drop(1)
      csvfile.header[:first_comment] = header_field.join(" ")
    when (number_of_fields == 4 && header_field[0] =~FreeregOptionsConstants::HEADER_FLAG && !@modern_date_field_1)
      # 4 comments one of which may be a date that is not in field 2
      csvfile.header[:first_comment] = header_field.join(" ")
    when (number_of_fields == 5 && header_field[0] =~FreeregOptionsConstants::HEADER_FLAG && @modern_date_field_1)
      #,date and 3 comments
      csvfile.header[:modification_date] = header_field[1]
      header_field = header_field.drop(2)
      csvfile.header[:first_comment] = header_field.join(" ")
    else
      csvfile.header[:modification_date] = csvfile.header[:transcription_date]
      csvfile.header_error << "I did not know enough about your data format to extract notes Information at header line 4. <br>"
    end
    if csvfile.header_error.present?
      return false
    else
      csvfile.header[:modification_date] = csvfile.header[:transcription_date] if (csvfile.header[:modification_date].nil? || (Freereg1CsvFile.convert_date(csvfile.header[:transcription_date]) > Freereg1CsvFile.convert_date(csvfile.header[:modification_date])))
      csvfile.header[:modification_date] = csvfile.uploaded_date.strftime("%d %b %Y") if (Freereg1CsvFile.convert_date(csvfile.uploaded_date.strftime("%d %b %Y")) > Freereg1CsvFile.convert_date(csvfile.header[:modification_date]))
      return true
    end
  end

  def process_header_line_four_block(header_field,csvfile)
    csvfile.header[:modification_date] = header_field[1]
    csvfile.header[:first_comment] = header_field[2]
    csvfile.header[:second_comment] = header_field[3]
  end

  def process_header_line_four_date_or_comment(header_field,csvfile)
    a = Array.new
    a = header_field[0].split("")
    if a[0] =~FreeregOptionsConstants::HEADER_FLAG
      a = a.drop(1)
      header_field[0] = a.join("").strip
      if @modern_date_field_0
        csvfile.header[:modification_date] = header_field[0]
      else
        csvfile.header[:first_comment] = header_field[0]
      end
    else
      csvfile.header[:modification_date] = csvfile.header[:transcription_date]
      csvfile.header_error << "I did not know enough about your data format to extract notes Information at header line 4. <br>"

    end
  end

  def process_header_line_four_no_comma_and_date_or_comment(header_field,csvfile)
    a = Array.new
    a = header_field[0].split("")
    if a[0] =~FreeregOptionsConstants::HEADER_FLAG
      a = a.drop(1)
      header_field[0] = a.join("").strip
      case
      when @modern_date_field_0
        csvfile.header[:modification_date] = header_field[0]
        csvfile.header[:first_comment] = header_field[1]
      when @modern_date_field_2
        csvfile.header[:modification_date] = header_field[1]
        csvfile.header[:first_comment] = header_field[0]
      else
        csvfile.header[:first_comment] = header_field[0]
        csvfile.header[:second_comment] = header_field[1]
      end
    else
      csvfile.header[:modification_date] = csvfile.header[:transcription_date]
      csvfile.header_error << "I did not know enough about your data format to extract notes Information at header line 4. <br>"
    end
  end

  def extract_from_header_five(header_field,csvfile,project)
    #process the optional header line 5
    #eg +LDS,,,, #,DEF
    #get an array of current entry fields
    proceed = true
    case
    when header_field[0] == "+LDS"
      csvfile.header[:lds] = "yes"
      @data_entry_order = get_default_data_entry_order(csvfile)
    when header_field[0] == "#" && header_field[1] == "DEF"
      csvfile.header[:def]  = true
      project.write_messages_to_all("Flexible csv flag detected. The next line will be taken a column specification. <p>", true)

      if !valid_field_definition?(@data_lines[0][0].downcase,csvfile)
        proceed = false
        csvfile.header_error << "The field order definition is missing. "
      else
        proceed, @data_entry_order = extract_data_field_order(@data_lines[0],csvfile)
      end

      project.write_messages_to_all("Will use the following column specification \n\r #{@data_lines[0]} ", true)
      @data_lines.shift if proceed
    else
      csvfile.header[:lds] = "no"
      csvfile.header[:def]  = false
      @data_entry_order = get_default_data_entry_order(csvfile)
    end
    csvfile.header[:order]  = @data_entry_order
    return proceed
  end

  def extract_data_field_order(header_fields,csvfile)
    proceed = true
    if header_fields.length == 1
      proceed = false
      csvfile.header_error << "The field order definition contains no fields. <br>"
    end
    n = 0
    while n < header_fields.length
      #need to verify fields
      header_fields[n].nil? ? field = nil : field = header_fields[n].downcase
      if field.present? && valid_field_definition?(field,csvfile)
        @data_entry_order[field.to_sym] = n
      else
        proceed = false
        csvfile.header_error << "The field order definition at position #{n} contains an invalid field: #{header_fields[n]} (is it blank?)}. <br>"
      end
      n = n + 1
    end
    return proceed,  @data_entry_order
  end

  # This extracts the header and entry information from the file and adds it to the database
  def extract_the_data(csvfile,project)
    success = true
    n = 0
    @data_lines.each do |line|
      n = n + 1
      #p "processing line #{n}"
      @record = CsvRecord.new(line)
      success, message = @record.extract_data_line(self, csvfile, project, n)
      #success,message = @record.add_record_to_appropriate_file(location,self,csvfile,project,n) if success.present?
      project.write_messages_to_all(message,true) if !success
      success = true
    end
    message = "Your new file has (#{csvfile.unique_locations.length}) different batches ie a different county/place/church or register type. This creates complexities that should be avoided. We strongly urge you to reconsider the content of the file. <p>"
    project.write_messages_to_all(message, true) if
    csvfile.unique_locations.length.present? && csvfile.unique_locations.length > 1
    return success, n
  end

  def get_default_data_entry_order(csvfile)
    order = FreeregOptionsConstants::ENTRY_ORDER_DEFINITION[csvfile.header[:record_type]]
    #change to array number
    new_order = Hash.new
    order.each do |key,value|
      value = value.to_i - 1
      new_order[key] = value
    end
    return new_order
  end

  def get_the_file_information_from_the_headers(csvfile,project)
    #p "Extracting header information"
    success1 = success2 = success3 = success4 = success5 = true
    success = false
    csvfile.header_error << "There are no valid header lines. <br>" if @header_lines.length == 0
    success = extract_from_header_one(@header_lines[0],csvfile) unless @header_lines.length <= 0
    csvfile.header_error << "There was only one header line. <br>" if @header_lines.length == 1
    success1 = extract_from_header_two(@header_lines[1],csvfile) unless @header_lines.length <= 1
    csvfile.header_error << "There were only two header lines. <br>" if @header_lines.length == 2
    success2 = extract_from_header_three(@header_lines[2],csvfile) unless @header_lines.length <= 2
    csvfile.header_error << "There were only three header lines. <br>" if @header_lines.length == 3
    success3 = extract_from_header_four(@header_lines[3],csvfile)  unless @header_lines.length <= 3
    @data_entry_order = get_default_data_entry_order(csvfile)  if @header_lines.length <= 4 && csvfile.header[:record_type].present?
    success4 = extract_from_header_five(@header_lines[4],csvfile,project) unless @header_lines.length <= 4
    original_file_is_flexible_format = check_original_file_is_flexible_format?(csvfile.file_name,csvfile.userid)
    success5 = false unless !original_file_is_flexible_format || (original_file_is_flexible_format && csvfile.header[:def])
    csvfile.header_error << "The file has been process as extended but this file does not contain a DEF control"  unless success5
    if csvfile.header_error.present?
      if !success || !success1 || !success2 || !success3 || !success4 || !success5
        project.write_messages_to_all("Processing was terminated because of a fatal header error. <p>",true)
        inform_the_user(csvfile,project)
        return false, "Header problem"
      else
        project.write_messages_to_all("While processing continued there were the following header warnings. <p>",true)
        inform_the_user(csvfile,project)
      end
    end
    return true, "OK"
  end

  def check_original_file_is_flexible_format?(batch,userid)
    file = Freereg1CsvFile.file_name(batch).userid(userid).first
    result = false
    if file.present?
      result = true if file.def
    end
    return result
  end

  def inform_the_user(csvfile,project)
    csvfile.header_error.each do |error|
      project.write_messages_to_all(error,true)
    end
  end

  def valid_field_definition?(fields,csvfile)
    record_type = csvfile.header[:record_type]
    case record_type
    when RecordType::BAPTISM
      entry_fields = FreeregOptionsConstants::FLEXIBLE_CSV_FORMAT_BAPTISM
    when RecordType::BURIAL
      entry_fields = FreeregOptionsConstants::FLEXIBLE_CSV_FORMAT_BURIAL
    when RecordType::MARRIAGE
      entry_fields = FreeregOptionsConstants::FLEXIBLE_CSV_FORMAT_MARRIAGE
    end
    #entry_fields = Freereg1CsvEntry.attribute_names
    entry_fields << "chapman_code"
    entry_fields << "place_name"
    result = true
    unless fields.kind_of?(Array)
      result = false if !entry_fields.include?(fields)
      return result
    end
    fields.each do |field|
      result = false if !entry_fields.include?(field)
      break unless result
    end
    return result
  end
end

class CsvRecord < CsvRecords

  attr_accessor :data_line, :data_record

  def initialize(data_line)
    @data_line = data_line
    @data_record = Hash.new
  end

  def extract_data_line(csvrecords, csvfile, project, line)
    #p "extracting data line"
    #p "#{line}"
    success, register_location = self.extract_register_location(csvrecords, csvfile, project, line)
    return false unless success

    #@current_register_location << register_location unless @current_register_location.include?(register_location)
    type = csvfile.header[:record_type]
    case type
    when RecordType::BAPTISM
      self.process_baptism_data_fields(csvrecords, csvfile, project, line)
    when RecordType::BURIAL
      self.process_burial_data_fields(csvrecords, csvfile, project, line)
    when RecordType::MARRIAGE
      self.process_marriage_data_fields(csvrecords, csvfile, project, line)
    end# end of case

    success
  end
  def validate_and_set_register_type(possible_register_type)
    if possible_register_type =~ FreeregOptionsConstants::VALID_REGISTER_TYPES
      # deal with possible register type; clean up variations before we check
      possible_register_type = possible_register_type.gsub(/\(?\)?'?"?[Ss]?/, '')
      possible_register_type = Unicode::upcase(possible_register_type)
      if RegisterType::OPTIONS.values.include?(possible_register_type)
        register_type = possible_register_type
        register_type = "DW" if register_type == "DT"
        register_type = "PH" if register_type == "PT"
        register_type = "TR" if register_type == "OT"
      else
        register_type = " "
      end
    else
      register_type = " "
    end
    register_type
  end

  def extract_register_type_and_church_name(csvrecords,csvfile,project,line)
    #p "extracting register type"
    #get the register type from a church field eg St. Kirk AT
    if @data_line[csvrecords.data_entry_order[:church_name]].present?
      register_words = @data_line[csvrecords.data_entry_order[:church_name]].split(" ")
      n = register_words.length
      if n > 1
        possible_register_type = register_words[-1]
        if possible_register_type =~ FreeregOptionsConstants::VALID_REGISTER_TYPES
          # deal with possible register type; clean up variations before we check
          possible_register_type = possible_register_type.gsub(/\(?\)?'?"?[Ss]?/, '')
          possible_register_type = Unicode::upcase(possible_register_type)
          if RegisterType::OPTIONS.values.include?(possible_register_type)
            register_type = possible_register_type
            n = n - 1
            register_type = "DW" if register_type == "DT"
            register_type = "PH" if register_type == "PT"
            register_type = "TR" if register_type == "OT"
            church_name = register_words.shift(n).join(" ")
          else
            register_type = " "
          end
        else
          #straight church name and no register type
          register_type = " "
          church_name = @data_line[csvrecords.data_entry_order[:church_name]]
        end
      else
        register_type = " "
        church_name = @data_line[csvrecords.data_entry_order[:church_name]]
      end
      success = true
      message = "OK"
    else
      success = false
      message = "Empty church field"
    end
    church_name = Church.standardize_church_name(church_name)
    return success, message, church_name, register_type
  end

  def extract_register_location(csvrecords,csvfile,project,line)
    #p "Extracting location"
    success1 = false
    success4 = false
    success5 = false
    register_location = Hash.new
    if no_location_fields?(@data_line,csvrecords,csvfile)
      project.write_messages_to_all("The line #{line} has no location information ie no place/church/register. <br>", true)
      return false
    end
    chapman_code = @data_line[csvrecords.data_entry_order[:chapman_code]]
    success = true if FreeregValidations.valid_chapman_code?(chapman_code)
    project.write_messages_to_all("The county code #{chapman_code} at field #{@data_line[csvrecords.data_entry_order[:chapman_code]]} is invalid at line #{line}. <br>", true)   if  !success
    place_name = @data_line[csvrecords.data_entry_order[:place_name]]
    success1, set_place_name = validate_place_and_set(place_name,chapman_code)
    project.write_messages_to_all("The place name at field #{@data_line[csvrecords.data_entry_order[:place_name]]} is invalid at line #{line}. <br>", true)   if  !success1
    place_name = set_place_name if success1
    #allows for different Register type input
    if csvfile.header[:def] && csvrecords.data_entry_order[:register_type].present?
      success4 = true
      church_name = @data_line[csvrecords.data_entry_order[:church_name]]
      possible_register_type = @data_line[csvrecords.data_entry_order[:register_type]]
      register_type = validate_and_set_register_type(possible_register_type)
      success5, set_church_name = validate_church_and_set(church_name,chapman_code,place_name) if success1
    else
      #part of church name
      success4,message,church_name,register_type = self.extract_register_type_and_church_name(csvrecords,csvfile,project,line)
      project.write_messages_to_all("The church field #{church_name} is invalid at line #{line}. <br>", true)   if  !success4
      success5, set_church_name = validate_church_and_set(church_name,chapman_code,place_name) if success1 && success4
    end
    project.write_messages_to_all("The church name #{church_name} is not in the database for #{place_name} at line #{line}. <br>", true)   if  !success5
    #we use the server church name in case of case differences
    church_name = set_church_name if  success5
    return false unless success && success1 && success4 && success5
    self.load_data_record(csvfile,chapman_code,place_name,church_name,register_type)
    csvfile.unique_locations[@data_record[:location]] = self.load_hold(csvfile) unless csvfile.unique_locations.key?(@data_record[:location])
    return true, register_location = {:chapman_code=> chapman_code,:place_name => place_name,:church_name => church_name, :register_type => register_type}
  end

  def load_data_record(csvfile,chapman_code,place_name,church_name,register_type)
    @data_record[:chapman_code] = chapman_code
    @data_record[:county] = chapman_code
    @data_record[:place_name] = place_name
    @data_record[:place] = place_name
    @data_record[:church_name] = church_name
    @data_record[:register_type] = register_type
    @data_record[:record_type] = csvfile.header[:record_type]
    args = {:chapman_code => @data_record[:chapman_code],:place_name => @data_record[:place_name],:church_name =>
            @data_record[:church_name],:register_type => @data_record[:register_type], :record_type => csvfile.header[:record_type]}
    @data_record[:location] = csvfile.sum_the_header(args)
  end

  def load_hold(csvfile)
    hold = Hash.new
    hold[:chapman_code] = @data_record[:chapman_code]
    hold[:county] = @data_record[:county]
    hold[:place_name] = @data_record[:place_name]
    hold[:church_name] = @data_record[:church_name]
    hold[:register_type] = @data_record[:register_type]
    hold[:record_type] = csvfile.header[:record_type]
    return hold
  end

  def no_location_fields?(data_line,csvrecords,csvfile)
    location = false
    location = true if data_line[csvrecords.data_entry_order[:chapman_code]].blank? && data_line[csvrecords.data_entry_order[:place_name]].blank? &&
      data_line[csvrecords.data_entry_order[:church_name]].blank?
    return location
  end

  def process_baptism_data_fields(csvrecords, csvfile, project, line)
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
    #(@data_record[:private_baptism].present? && FreeregOptionsConstants::PRIVATE_BAPTISM_OPTIONS.include?(@data_record[:private_baptism].downcase)) ? @data_record[:private_baptism] = true : @data_record[:private_baptism] = false
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
    #(@data_record[:marriage_by_licence].present? && FreeregOptionsConstants::MARRIAGE_BY_LICENCE_OPTIONS.include?(@data_record[:marriage_by_licence].downcase)) ? @data_record[:marriage_by_licence] = true : @data_record[:marriage_by_licence] = false
    #(@data_record[:groom_marked].present? && FreeregOptionsConstants::MARKED_OPTIONS.include?(@data_record[:groom_marked].downcase)) ? @data_record[:groom_marked] = true : @data_record[:groom_marked] = false
    #(@data_record[:bride_marked].present? && FreeregOptionsConstants::MARKED_OPTIONS.include?(@data_record[:bride_marked].downcase)) ? @data_record[:bride_marked] = true : @data_record[:bride_marked] = false
    @data_record[:processed_date] = Time.now
    csvfile.data[line] = @data_record
  end

  def  process_baptism_sex_field(field)
    case
    when field.nil?
      return_field = nil
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
