# -*- coding: utf-8 -*-
module FreeregCsvUpdateProcessor
  # This class processes a file or files of CSV records.
  #It converts them into entries and stores them in the freereg1_csv_entries     collection

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
  

  #BOM = /ï»¿/
  DATEMAX = 2020
  DATEMIN = 1530
 
  


  VALID_MALE_SEX = ["M","M." ,"SON","MALE","MM","SON OF"]
  UNCERTAIN_MALE_SEX = ["M?","SON?","[M]" ,"MF"]
  UNCERTAIN_FEMALE_SEX = ["F?", "DAU?"]
  UNCERTAIN_SEX = ["?", "-", "*","_","??"]
  VALID_FEMALE_SEX = ["F","FF","FFF","FM","F.","FEMALE","DAUGHTER","WIFE","DAUGHTER OF","DAU", "DAU OF"]
 
  WILD_CHARACTER = /[\*\[\]\-\_\?]/
  def self.process_csv_files(create_search_records,type,force,range)
    p "procees started"
    @project =  ProjectControls.new(Rails.application.config.datafiles,create_search_records,type,force,range,Time.now.strftime("%d/%m/%Y %H:%M"))
    @project.write_log_file("Started processor project. #{@project.inspect} using website #{Rails.application.config.website}")
    @csvfiles = CsvFiles.new
    success, files_to_be_processed = @csvfiles.get_the_files_to_be_processed(@project)
    if !success || files_to_be_processed == 0
      @project.write_log_file("processing terminated as we have no records to process")
      return
    end
    @project.write_log_file "#{files_to_be_processed.length}\t files selected for processing\n"
    files_to_be_processed.each do |file|
      p "Started a file"
      @csvfile = CsvFile.new(file)
      success, records_processed = @csvfile.process_single_csv_file(@project)
      p success
      p records_processed
      if success
        p "processed file"
        @project.total_records = @project.total_records + records_processed unless records_processed.nil?
        @project.total_files =  @project.total_files  + 1
      else
        p "failed to process file"
        @project.write_log_file(records_processed)
        @csvfile.communicate_failure_to_member(records_processed)
        @csvfile.clean_up_physical_files_after_failure(records_processed)
      end
    end
    p "manager communication"
    @project.communicate_to_managers(@csvfile) unless @project.type_of_project == "individual"
    at_exit do
      p "goodbye"
    end
    @success
  end
  class ProjectControls
    #:create_search_records has values create_search_records or no_search_records
    #:type_of_project has values waiting, range or individual
    #:force_rebuild causes all files to be processed
    #::file_range
    #:message_file is the log file where system and processing messages are written
    attr_accessor :freereg_files_directory,:create_search_records,:type_of_project,:force_rebuild,
      :file_range,:message_file,:project_start_time,:total_records, :total_files

    def initialize(a,b,c,d,e,f)
      self.freereg_files_directory = a
      self.create_search_records = b
      self.type_of_project = c
      self.force_rebuild = d
      self.file_range = e
      self.project_start_time = f
      self.total_records = 0
      self.total_files = 0
      self.message_file = define_message_file
      EmailVeracity::Config[:skip_lookup]=true
    end
    def define_message_file
      file_for_warning_messages = File.join(Rails.root,"log/update_freereg_messages")
      time = Time.new.to_i.to_s
      file_for_warning_messages = (file_for_warning_messages + "." + time + ".log").to_s
      message_file = File.new(file_for_warning_messages, "w")
      return message_file
    end
    def write_log_file(message)
      self.message_file.puts message
    end
    def communicate_to_managers(csvfile)
      time = 0
      time = (((Time.now  - self.project_start_time)/self.total_records)*1000) unless self.total_records == 0
      p "Created  #{self.total_records} entries at an average time of #{time}ms per record" 
      self.write_log_file ("Created  #{self.total_records} entries at an average time of #{time}ms per record at #{Time.new}\n")
      file = self.message_file
      self.message_file.close 
      user = UseridDetail.where(userid: "REGManager").first
      UserMailer.update_report_to_freereg_manager(file,user).deliver
      user = UseridDetail.where(userid: "ericb").first
      UserMailer.update_report_to_freereg_manager(file,user).deliver
    end  
  end
  class CsvFiles < ProjectControls
    def initialize
    end
    def get_the_files_to_be_processed(project)
      case project.type_of_project
      when "waiting"
        files = self.get_the_waiting_files_to_be_processed(project)     
      when "range"
        files = self.get_the_range_files_to_be_processed(project)
      when "individual"
        files = self.get_the_individual_file_to_be_processed(project)
      end
      return true,files
    end
    def get_the_waiting_files_to_be_processed(project)
      physical_waiting_files = PhysicalFile.waiting.all
      files = Array.new
      physical_waiting_files.each do |file|
        files << File.join(project.freereg_files_directory, file.userid, file.file_name)
      end
      return files
    end
    def get_the_range_files_to_be_processed(project)
      files = GetFiles.get_all_of_the_filenames(project.freereg_files_directory,project.file_range)
    end
    def get_the_individual_file_to_be_processed(project)
      files = GetFiles.get_all_of_the_filenames(project.freereg_files_directory,project.file_range)
    end
  end

  class CsvFile < CsvFiles
     
    #initializes variables
    #gets information on the file to be processed
    attr_accessor :header, :csvdata, :list_of_registers, :header_error, :system_error, :data_hold, :current_register_location,
      :array_of_data_lines, :default_charset, :file, :file_name, :userid, :uploaded_date, :slurp_fail_reason, :update,
      :place, :file_start, :member_message_file, :slurp_fail_message
     
    def initialize(file)
      standalone_filename = File.basename(file)
      full_dirname = File.dirname(file)
      parent_dirname = File.dirname(full_dirname)
      user_dirname = full_dirname.sub(parent_dirname, '').gsub(File::SEPARATOR, '')
      self.uploaded_date = Time.now
      self.uploaded_date = File.mtime(file) if File.exists?(file)	
      self.update = false
      self.place = nil
      self.csvdata = Array.new
      self.header_error = Array.new()
      self.array_of_data_lines = Array.new {Array.new}
      self.default_charset = "iso-8859-1"
      self.file = file 
      self.file_name = standalone_filename
      self.userid = user_dirname
      self.slurp_fail_reason = nil
      self.file_start
      self.member_message_file = define_member_message_file
      self.current_register_location = Array.new
      self.header = Hash.new
      self.header[:digest] = Digest::MD5.file(file).hexdigest if File.exists?(file) 
      self.header[:file_name] = standalone_filename #do not capitalize filenames
      self.header[:userid] = user_dirname
      self.header[:uploaded_date] = uploaded_date
      
    end
    def process_single_csv_file(project)
      p "single csv file"
      success = true
      self.file_start = Time.now
      p "Started on the file #{self.header[:file_name]} at #{self.file_start }"
      project.write_log_file("Started on the file #{self.header[:file_name]} at #{self.file_start}")
      success, message = self.ensure_processable(project) unless project.force_rebuild == "force_rebuild"
      p message 
      p "finished file checking"
      return false,message unless success
      success, message = self.slurp_the_csv_file(project)
      p "finished slurp"
      p message 
      return false, message unless success
      @csv_records = CsvRecords.new(self.array_of_data_lines) 
      success, message = @csv_records.separate_into_header_and_data_lines(self,project) 
      p "got header and data lines"
      p message 
      return false,"lines not extracted" unless success
      success, message = @csv_records.get_the_file_information_from_the_headers(self,project) 
      p "finished header"
       p message 
      return false,"headers not extracted" unless success 
      success,records_processed = @csv_records.extract_the_data(self,project)
      p "finished data"
      p records_processed
      return false,"data not extracted" unless success
      success, message = self.clean_up_supporting_information
      p "finished clean up"
      p message
      return false,"clean up failed" unless success
      success, message = self.communicate_file_processing_results
      p "finished com"
      p message 
      return false,"communication failed" unless success
      return true,records_processed 
    end

          
    def ensure_processable(project)
      p "ensuring processable"
      success, message = self.ensure_file_exists?
      success, message = self.check_userid_exists? if success
      batch = Freereg1CsvFile.userid(self.userid).file_name(self.file_name).first if success
      success, message = self.check_file_is_more_recent?(batch) if success
      success, message = self.check_file_is_not_locked?(batch) if success
      return true, "OK" if success
      return false, message unless success 
    end
    def check_file_is_not_locked?(batch)
      return true, "OK" if batch.blank?
      return false, "#{self.userid} #{self.file_name} file on system is locked" if 
      batch.locked_by_transcriber || batch.locked_by_coordinator 
      return true, "OK"
    end
    def check_file_is_more_recent?(batch)
      return true, "OK" if batch.blank?
      return false, "#{self.userid} #{self.file_name} file is older than one on system" if
       batch.uploaded_date.strftime("%s").to_i > self.uploaded_date.strftime("%s").to_i
      return true, "OK"
    end
    def ensure_file_exists?
      #make sure file actually exists                                 
      return false, "#{self.userid} #{self.file_name} file does not exist" unless File.exists?(self.file) 
      return true, "OK"
    end
    def check_userid_exists?
       return false, "#{self.userid} #{self.file_name} userid does not exist" unless 
       UseridDetail.userid(self.userid).first.present?
       return true, "OK"
    end

    def slurp_the_csv_file(project)
      p "starting the slurp"
      #read entire .csv as binary text (no encoding/conversion)
      begin
        csvtxt = File.open(self.file, "rb", :encoding => "ASCII-8BIT:ASCII-8BIT"){|f| f.read}
        return false, "Empty file" if csvtxt.blank?
        code = self.determine_if_utf8(csvtxt)
        code = self.get_codeset_from_header(csvtxt) if code.nil?
        code, message = self.check_and_set_characterset(code,csvtxt)
        csvtext = self.standardize_line_endings(csvtxt)
        success = self.extract_the_array_of_lines(csvtxt)
        return success, message
      rescue  => e
        #p "rescue block entered " + (@@slurp_fail_reason.nil? ? "" : @@slurp_fail_reason)
        p "csv slurp rescue " + (e.message)
        project.write_log_file "#{self.userid}\t#{self.file_name} *We were unable to process the file possibly due to an invalid structure or character. Please consult the System Administrator*"
        project.write_log_file self.slurp_fail_message if self.slurp_fail_message.present?
        project.write_log_file e.message
        project.write_log_file e.backtrace.inspect
        success = false,e.message
      ensure
        #we ensure that processing keeps going by dropping out through the bottom
      end #begin end
    end
    def standardize_line_endings(csvtxt)
      xxx = csvtxt.gsub(/\r?\n/, "\r\n").gsub(/\r\n?/, "\r\n")
      return xxx
    end 
      def extract_the_array_of_lines(csvtxt)
        #now get all the data
        self.slurp_fail_message = "the CSV parser failed. The CSV file might not be formatted correctly"
        self.array_of_data_lines = CSV.parse(csvtxt, {:row_sep => "\r\n",:skip_blanks => true})
        #remove zzz fields and white space
        self.array_of_data_lines.each do |line|
          line.each_index    {|x| line[x] = line[x].gsub(/zzz/, ' ').gsub(/\s+/, ' ').strip unless line[x].nil? }
        end
        self.slurp_fail_message = nil # no exception thrown
        return true
      end

      def check_and_set_characterset(code,csvtxt)
        code_set = "Windows-1252" if (code.nil? || code.empty? || code == "chset")
        code_set = "UTF-8" if (code_set.upcase == "UTF8")
        #Deal with the cp437 code which is IBM437 in ruby
        code_set = "IBM437" if (code_set.upcase == "CP437")
        #Deal with the macintosh instruction in freereg1
        code_set = "macRoman" if (code_set.downcase == "macintosh")
        code_set = code_set.upcase if code_set.length == 5 || code_set.length == 6
        message = "Invalid Character Set detected #{code_set} have assumed Windows-1252" unless Encoding.name_list.include?(code_set)
        code_set = "Windows-1252" unless Encoding.name_list.include?(code_set)
        self.header[:characterset] = code_set
        unless csvtxt.encoding == 'UTF-8'
          csvtxt.force_encoding(code_set)
          self.slurp_fail_message = "the processor failed to convert to UTF-8 from character set #{code_set}"
          csvtxt = csvtxt.encode('UTF-8', invalid: :replace, undef: :replace)
          self.slurp_fail_message = nil # no exception thrown
        end
        return code_set, message
      end
      def get_codeset_from_header(csvtxt)
        self.slurp_fail_message = "CSV parse failure on first line"
        first_data_line = CSV.parse_line(csvtxt)
        self.slurp_fail_message = nil # no exception thrown
        if !first_data_line.nil? && first_data_line[0] == "+INFO" && !first_data_line[5].nil?
          code_set_specified_in_csv = first_data_line[5].strip
        end
        return code_set_specified_in_csv
      end
      def determine_if_utf8(csvtxt)
        #check for BOM and if found, assume corresponding
        # unicode encoding (unless invalid sequences found),
        # regardless of what user specified in column 5 since it
        # may have been edited and saved as unicode by coord
        # without updating col 5 to reflect the new encoding.
        if !csvtxt.nil? && csvtxt.length > 2
          if csvtxt[0].ord==0xEF && csvtxt[1].ord==0xBB && csvtxt[2].ord==0xBF
            #p "UTF-8 BOM found"
            csvtxt = csvtxt[3..-1]#remove BOM
            code_set = 'UTF-8'
            self.slurp_fail_message = "BOM detected so using UTF8"
            csvtxt.force_encoding(code_set)
            if !csvtxt.valid_encoding?
              #not really a UTF-8 file. probably was edited in
              #software that added BOM to beginning without
              #properly transcoding existing characters to UTF-8
              code_set = nil
              csvtxt.force_encoding('ASCII-8BIT')
            else
              csvtxt=csvtxt.encode('utf-8', :undef => :replace)
            end
          else
            #No BOM
            code_set = nil
            self.slurp_fail_message = nil
          end
        else
          #No BOM
          self.slurp_fail_message = nil
          code_set = nil
        end
        self.slurp_fail_message = "BOM detected so using UTF8"
        return code_set
      end

      def clean_up_supporting_information
        return true
      end
      def communicate_file_processing_results
        return true
      end

      def define_member_message_file
        file_for_member_messages = File.join(Rails.root,"log/member_update_messages")
        time = Time.new.to_i.to_s
        file_for_member_messages = (file_for_member_messages + "." + time + ".log").to_s
        member_message_file = File.new(file_for_member_messages, "w")
        return member_message_file
      end

      def write_member_message_file(message)
        self.member_message_file.puts message
      end

      def communicate_failure_to_member(message)
        p "communicating failure"
        p message
        self.member_message_file.puts message
        member_message_file.close
        file = self.member_message_file
        UserMailer.batch_processing_failure(file,self.userid,self.file_name).deliver
        self.clean_up_message
        return true
      end
      def clean_up_physical_files_after_failure(message)
        p "clean up after failure"
        batch = PhysicalFile.userid(self.userid).file_name(self.file_name).first
        return true if batch.blank?
        PhysicalFile.remove_base_flag(self.userid,self.file_name) if message.include? "file does not exist"
        PhysicalFile.userid(self.userid).file_name(self.file_name).delete if message.include? "userid does not exist"
        PhysicalFile.remove_waiting_flag(self.userid,self.file_name) if message.include? "file is older than one on system"
        PhysicalFile.remove_waiting_flag(self.userid,self.file_name) if message.include? "file on system is locked"
      end
      def clean_up_message
        File.delete(self.member_message_file)
      end
    end

	class CsvRecords <  CsvFiles
		attr_accessor :array_of_lines, :header_lines, :data_lines
		def initialize(data_array)
		  self.array_of_lines = data_array
		  self.header_lines = Array.new {Array.new}
		  self.data_lines = Array.new {Array.new}
		  self.data_entry_order = Hash.new
		end
		def separate_into_header_and_data_lines(csvfile,project)
		  p "Getting header and data lines"
		  n = 0
		  self.array_of_lines.each do |line|
		    n = n + 1
		    break if n == 8
		    first_character = "?"
		    first_character = line[0].slice(0) unless  line[0].nil?
		    if (first_character == "+" || first_character ==  "#") || line[0] =~ FreeregOptionsConstants::HEADER_DETECTION
		      self.header_lines << line
		    else
		      self.data_lines << line
		    end
		  end
		  return true
		end
		def get_the_file_information_from_the_headers(csvfile,project)
		  p "Extracting header information"
		  p self.header_lines
		  success = extract_from_header_one(self.header_lines[0],csvfile) unless self.header_lines.length <= 0
		  p "after header 1"
		  p csvfile.header
		  success1 = extract_from_header_two(self.header_lines[1],csvfile) unless self.header_lines.length <= 1
		  p "after header 2"
		  p csvfile.header
		  success2 = extract_from_header_three(self.header_lines[2],csvfile) unless self.header_lines.length <= 2
		  p "after header 3"
		  p csvfile.header
		  success3 = extract_from_header_four(self.header_lines[3],csvfile)  unless self.header_lines.length <= 3
		  p "after header 4"
		  p csvfile.header
		  success4 = extract_from_header_five(self.header_lines[4],csvfile) unless self.header_lines.length <= 4
		  p "after header 5"
		  p csvfile.header
		  return false, csvfile.header_error if  csvfile.header_error.present?
		  return true
		end
		def extract_from_header_one(header_field,csvfile)
		  p "header one"
		  p header_field
		  #process the header line 1
		  # eg +INFO,David@davejo.eclipse.co.uk,password,SEQUENCED,BURIALS,cp850,,,,,,,
		  csvfile.header_error << "First line of file does not start with +INFO it has #{header_line[0]}" unless (header_field[0] =~ FreeregOptionsConstants::HEADER_DETECTION)
		  #We only use the file email address where there is not one in the userid #csvfile.header[:transcriber_email] = header_line[1]
		  userid  = UseridDetail.userid(csvfile.header[:userid]).first
		  new_email = userid.email_address if userid.present?
		  csvfile.header[:transcriber_email] = new_email unless new_email.nil?
		  csvfile.header_error << "Invalid file type #{header_field[4]} in first line of header" unless FreeregOptionsConstants::VALID_RECORD_TYPE.include?(header_field[4].gsub(/\s+/, ' ').strip.upcase)
		  # canonicalize record type
		  scrubbed_record_type = Unicode::upcase(header_field[4]).gsub(/\s/, '')
		  csvfile.header[:record_type] =  FreeregOptionsConstants::RECORD_TYPE_TRANSLATION[scrubbed_record_type]
		  p csvfile.header
		end
		def extract_from_header_two(header_field,csvfile)
		  p "header two"
		  p header_field
		  #process the header line 2
		  # eg #,CCCC,David Newbury,Derbyshire,dbysmalbur.CSV,02-Mar-05,,,,,,,
		  header_field = header_field.compact
		  number_of_fields = header_field.length
		  csvfile.header_error << "The second header line is completely empty; please check the file for blank lines" if number_of_fields == 0
		  header_field[1] = header_field[1].upcase unless header_field[1].nil?
		  case
		  when header_field[0] =~ FreeregOptionsConstants::HEADER_FLAG && header_field[1] =~ FreeregOptionsConstants::VALID_CCC_CODE
		    #deal with correctly formatted header
		    process_header_line_two_block(header_field,csvfile)
		  when number_of_fields == 1 && header_field[0] =~ FreeregOptionsConstants::HEADER_FLAG
		    #empty line
		    csvfile.header_error << "The second header line has no usable fields"
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
		    csvfile.header_error << "I did not know enough about your data format to extract transcriber information at header line 2"
		  end
		  p csvfile.header
		end
		def process_header_line_two_block_eric_special(header_field,csvfile)
		  eric = Array.new
		  eric[2] = header_field[1]
		  eric[3] = header_field[2]
		  eric[4] = header_field[4]
		  eric[5] = header_field[5]
		  i = 2
		  while i < 6  do
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
	       while i < 4  do
	        header_field[5-i] = header_field[3-i]
	        i +=1
	       end
	       header_field[2] = header_field[2].gsub(/#/, '')
	       process_header_line_two_block(header_field,csvfile)
	      end
	    def process_header_line_two_block(header_field,csvfile)
	      csvfile.header_error << "The transcriber's name #{header_field[2]} can only contain alphabetic and space characters in the second header line" unless FreeregValidations.cleantext(header_field[2])
	      csvfile.header[:transcriber_name] = header_field[2]
	      csvfile.header_error << "The syndicate can only contain alphabetic and space characters in the second header line" unless FreeregValidations.cleantext(header_field[3])
	      csvfile.header[:transcriber_syndicate] = header_field[3]
	      header_field[5] = '01 Jan 1998' unless FreeregValidations.modern_date_valid?(header_field[5])
	      csvfile.header[:transcription_date] = header_field[5]
	      userid = UseridDetail.where(:userid => csvfile.header[:userid] ).first
	      csvfile.header[:transcriber_syndicate] = userid.syndicate unless userid.nil?
	    end
	    def extract_from_header_three(header_field,csvfile)
	      # => process the csvfile.headerer line 3
	      # eg #,Credit,Libby,email address,,,,,,
	      p "header three"
	      header_field = header_field.compact
	      number_of_fields = header_field.length
	      csvfile.header_error << "The third header line is completely empty; please check the file for blank lines" if number_of_fields == 0
	      case
	      when (header_field[0] =~ FreeregOptionsConstants::HEADER_FLAG &&  FreeregOptionsConstants::VALID_CREDIT_CODE.include?(header_field[1]))
	        #the normal case
	        process_header_line_three_block(header_field,csvfile)
	      when number_of_fields == 1 && header_field[0] =~FreeregOptionsConstants::HEADER_FLAG
	        #no information just keep going
	        csvfile.header_error << "The second header line has no usable fields"
	      when number_of_fields == 2 && !FreeregOptionsConstants::VALID_CREDIT_CODE.include?(header_field[1])
	        #eric special #,Credit name
	        process_header_line_two_eric_special(header_field,csvfile)
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
	        csvfile.header_error << "I did not know enough about your data format to extract Credit Information at header line 3"
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
	      csvfile.header_error << "The credit person name #{header_field[2]} can only contain alphabetic and space characters in the third header line" unless FreeregValidations.cleantext(header_field[2])
	      csvfile.header[:credit_name] = header_field[2]
	      # # suppressing for the moment
	      # address = EmailVeracity::Address.new(header_field[3])
	      # raise FreeREGError, "Invalid email address '#{header_field[3]}' for the credit person in the third line of header" unless address.valid? || header_field[3].nil?
	      csvfile.header[:credit_name] = header_field[3]
	    end
	    def extract_from_header_four(header_field,csvfile)
	    	p "header four"
	      header_field = header_field.compact
	      number_of_fields = header_field.length
	      csvfile.header_error << "The forth header line is completely empty; please check the file for blank lines" if number_of_fields == 0
	      @modern_date_field_0 = FreeregValidations.modern_date_valid?(header_field[0])
	      @modern_date_field_1 = FreeregValidations.modern_date_valid?(header_field[1])
	      @modern_date_field_2 = FreeregValidations.modern_date_valid?(header_field[2])
	      case
	      when number_of_fields == 4 && header_field[0] =~FreeregOptionsConstants::HEADER_FLAG && @modern_date_field_1
	        #the normal case
	        process_header_line_four_block(header_field,csvfile)
	      when (number_of_fields == 1 && header_field[0] =~FreeregOptionsConstants::HEADER_FLAG)
	        # an empty line follows the #
	        csvfile.header_error << "The third header line has no usable fields"
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
	        header_field.drop(1)
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
	        csvfile.header_error << "I did not know enough about your data format to extract notes Information at header line 4"
	      end
	      csvfile.header[:modification_date] = csvfile.header[:transcription_date] if (csvfile.header[:modification_date].nil? || (Freereg1CsvFile.convert_date(csvfile.header[:transcription_date]) > Freereg1CsvFile.convert_date(csvfile.header[:modification_date])))
	      csvfile.header[:modification_date] = csvfile.uploaded_date.strftime("%d %b %Y") if (Freereg1CsvFile.convert_date(csvfile.uploaded_date.strftime("%d %b %Y")) > Freereg1CsvFile.convert_date(csvfile.header[:modification_date]))
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
	        csvfile.header_error << "I did not know enough about your data format to extract notes Information at header line 4"

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
	        csvfile.header_error << "I did not know enough about your data format to extract notes Information at header line 4"
	      end
	    end
	    def extract_from_header_five(header_field,csvfile)
	      #process the optional header line 5
	      #eg +LDS,,,,
	      	p "header five"
	      case header_field[0]
	      when "+LDS"
	        csvfile.header[:lds] = true
	      when "+DEF"
	        csvfile.header[:def]  = true
	      else
	        csvfile.header[:lds] = false
	        csvfile.header[:def]  = false
	      end
	      if csvfile.header[:def]
	      	n = 1
	      	if header_field[n].present?
	      		definition = header_field[n].split("=")
	      		csvfile.data_entry_order[definition[0]] = definition[1]
	      		n = n + 1
	      	end
	      else
	      	csvfile.data_entry_order = FreeregOptionsConstants::ENTRY_ORDER_DEFINITION[csvfile.header[:record_type]]
	      end
	    end

	    def extract_the_data(csvfile,project)
	    	p "processing #{self.data_lines.length} data lines"
	    	n = 0 
	      self.data_lines.each do |line|
	      	n = n + 1
	      	p "processing line #{n}"
	        @record = CsvRecord.new(line)
	        success,message = @record.process_data_line(csvfile,project,n)
	      end
	    end
	  end
	  class CsvRecord < CsvRecords
	    attr_accessor :data_line
	    def initialize(data_line)
	      self.data_line = data_line
	      self.entry = Hash.new
	    end
	    def process_data_line(csvfile,project,line)
	      p "processing data line"
	      p self.data_line
	      begin
		    success, register_location = self.extract_register_location(csvfile,project,line)
		    return false, "The line #{line} did not contain a valid register location" unless success
		    csvfile.current_register_location << register_location unless csvfile.current_register_location.include?(register_location)
		    type = csvfile.header[:record_type]
			case type
			    when RecordType::BAPTISM
			      success, message = self.process_baptism_data_fields
			    when RecordType::BURIAL
			     success, message = self.process_burial_data_fields
			    when RecordType::MARRIAGE
			     success, message = self.process_marriage_data_fields
			end# end of case

			  return success, message
	      rescue  => e
			puts e.message
			puts e.backtrace
			csvfile.header_error << "#{csvfile.userid}\t#{csvfile.filename} line #{line} crashed the processor\n"
			csvfile.header_error << e.message
			csvfile.header_error << e.backtrace.inspect 
	    end
	  end
	  def extract_register_location(csvfile,project,line)
	  	register_location = Hash.new
	  	chapman_code = self.data_line(csvfile.data_entry_order[:chapman_code])
       	success = false unless FreeregValidations.valid_chapman_code?(chapman_code)
        csvfile.header_error << "The county code #{} at field #{chapman_code} is invalid at line #{line}"   if  success.blank?
        place_name = self.data_line(csvfile.data_entry_order[:place_name])
        success1 = false unless  FreeregValidations.valid_place?(church_name,chapman_code)  if success.present?                        
        csvfile.header_error << "The place name at field #{self.data_line(csvfile.data_entry_order[:place_name])} is invalid at line #{line}"   if  success1.blank?
        if csvfile.header[:def] 
        	church_name = self.data_line(csvfile.data_entry_order[:church_name])
        	success2 = false unless FreeregValidations.valid_church?(church_name,chapman_code,place_name) if success1.present? 
        	csvfile.header_error << "The church name at field #{self.data_line(csvfile.data_entry_order[:church_name])} is invalid at line #{line}"   if  success2.blank?
        	register_type = self.data_line(csvfile.data_entry_order[:register_type])
        	success3 = false unless FreeregValidations.valid_register_type?(register_type,chapman_code,place_name,church_name) if success2.present?
        	csvfile.header_error << "The register type at field #{self.data_line(csvfile.data_entry_order[:register_type])} is invalid at line #{line}"   if  success3.blank?
        	return false unless success && success1 && success2 && success3
        else
        	register_type = self.extract_register_type(csvfile,project,line)
        	church_name = self.extract_church_name(csvfile,project,line)
        	success4 = false unless FreeregValidations.valid_church?(church_name,chapman_code,place_name) if success1.present? 
        	csvfile.header_error << "The church name at field #{self.data_line(csvfile.data_entry_order[:church_name])} is invalid at line #{line}"   if  success4.blank?
        	return false unless success && success1 && success4
        end
          return register_location = {:chapman_code=> chapman_code,:place_name => place_name,:church_name => church_name, :register_type => register_type}  	
	  end
	  def extract_register_type(csvfile,project,line)
	  	#get the register type from a church field eg St. Kirk AT
	  	register_words = self.data_line(csvfile.data_entry_order[:church_name]).split(" ")
        n = register_words.length
        if n > 1
          if possible_register_type =~ FreeregOptionsConstants::VALID_REGISTER_TYPES 
          	# deal with possible register type; clean up variations before we check
            possible_register_type = possible_register_type.gsub(/\(?\)?'?"?[Ss]?/, '')
            possible_register_type = Unicode::upcase(possible_register_type)                           
            if RegisterType::OPTIONS.values.include?(possible_register_type)
            	register_type = possible_register_type
                 n = n - 1
                 register_type = "DW" if @register_type == "DT"
                 register_type = "PH" if @register_type == "PT"
                 register_type = "TR" if @register_type == "OT"
            else
            	register_type = ""	
            end                                                    
        else
         #straight church name and no register type
         register_type = ""	
        end
        return register_type
	  end

	  def extract_church_name(csvfile,project,line)
	  	#get the register type from a church field eg St. Kirk AT
	  	register_words = self.data_line(csvfile.data_entry_order[:church_name]).split(" ")
        n = register_words.length
        if n > 1 && csvheader(:register_type) == ""
            n = n - 1
        end
        return register_words
	  end
	  

                  def self.process_single_file(filename, force, delta,  recreate, filename_count=1, create_search_records=true)
                    p "Started on the file #{filename} at #{Time.now}"
                    @@create_search_records = create_search_records unless defined? @@create_search_records
                    @@file_start = Time.new
                    setup_for_new_file(filename)
                    #do we process the file
                      process = false
                      process = check_for_replace(filename,force) unless recreate == "recreate"
                      #get the data for the file in one gob
                      @success = slurp_the_csv_file(filename) if process == true
                      #check to see that we need to process the data and we got it all
                      if @success == true  && process == true
                        #how many records did we process?
                        n = process_the_data
                        if n == 0
                          #lets deal with a null file
                          UserMailer.batch_processing_failure("there were no valid records, possibly because each record had an invalid county or place name",@@header[:userid],@@header[:file_name]).deliver
                          batch = PhysicalFile.where(:userid => @@header[:userid], :file_name => @@header[:file_name] ).first
                          batch.destroy unless batch.nil?
                        else
                          #now lets clean up the files and send out messages
                          #do we have a record of this physical file
                            batch = PhysicalFile.where(:userid => @@header[:userid], :file_name => @@header[:file_name] ).first
                            if batch.nil?
                              #file did not come in through FR2 so its unknown
                              batch = PhysicalFile.new(:userid => @@header[:userid], :file_name => @@header[:file_name],:change => true, :change_uploaded_date => Time.now)
                              batch.save
                            end
                            if delta == "delta"
                              file_location = File.join(base_directory, @@header[:userid])
                              Dir.mkdir(file_location) unless Dir.exists?(file_location)
                              p "copying file to freereg2 base"
                              FileUtils.cp(filename,File.join(file_location, @@header[:file_name] ),:verbose => true)
                              batch.update_attributes( :base => true, :base_uploaded_date => Time.now)
                            end
                            if @@create_search_records
                              # we created search records so its in the search database database
                              batch.update_attributes( :file_processed => true, :file_processed_date => Time.now,:waiting_to_be_processed => false, :waiting_date => nil)
                            else
                              #only checked for errors so file is not processed into search database
                              batch.update_attributes(:file_processed => false, :file_processed_date => nil,:waiting_to_be_processed => false, :waiting_date => nil)
                            end
                            batch.update_attributes(:file_processed => false, :file_processed_date => nil,:waiting_to_be_processed => false, :waiting_date => nil) if n == 0
                            #kludge to send email to user
                            header_errors = 0
                            header_errors= @@header_error.length unless  @@header_error.nil?
                            batch_errors = @@number_of_error_messages - header_errors
                            batch_errors = 0 if batch_errors <= 0
                            UserMailer.batch_processing_success(@@header[:userid],@@header[:file_name],n,batch_errors, header_errors).deliver if delta == 'process' || (delta == 'change' && filename_count == 1)
                            if defined? @@nn
                              @@nn += n unless n.nil?
                            end
                          end
                        else
                          #another kludge to send a message to user that the file did not get processed when the processing failed
                          if (delta == 'change' && filename_count == 1 && process == true)
                            message_file.puts "File not processed" if @success == false
                            message_file.close
                            file = message_file
                            user_msg = file
                            if !@@slurp_fail_reason.nil?
                              user_msg = @@slurp_fail_reason + file.to_s
                            end
                            UserMailer.batch_processing_failure( user_msg,@@header[:userid],@@header[:file_name]).deliver
                            user = UseridDetail.where(userid: "REGManager").first
                            UserMailer.update_report_to_freereg_manager(file,user).deliver
                          end
                          if delta == 'process' && process == true
                            file = "There was a malfunction in the processing; contact system administration"
                            UserMailer.batch_processing_failure( file,@@header[:userid],@@header[:file_name]).deliver
                          end
                          PhysicalFile.remove_waiting_flag(@@userid,@@header[:file_name])
                        end
                        #reset for next file
                        @success = true
                        #we pause for a time to allow the slaves to really catch up
                      end

                      #calculate the minimum and maximum dates in the file; also populate the decadal content table starting at 1530
                      def self.datestat(x)
                        xx = x.to_i
                        daterange = Array.new
                        datemax = @@list_of_registers[@@place_register_key].fetch(:datemax)
                        datemin = @@list_of_registers[@@place_register_key].fetch(:datemin)
                        daterange = @@list_of_registers[@@place_register_key].fetch(:daterange)
                        datemax = xx if xx > datemax && xx < FreeregValidations::YEAR_MAX
                        datemin = xx if xx < datemin
                        bin = ((xx-FreeregOptionsConstants::DATERANGE_MINIMUM)/10).to_i
						bin = 0 if bin < 0
						bin = 49 if bin >= 50
						daterange[bin] = daterange[bin] + 1
						#   p "data range #{datemax} #{datemin} #{bin} #{daterange}"
						@@list_of_registers[@@place_register_key].store(:datemax,datemax)
						@@list_of_registers[@@place_register_key].store(:datemin,datemin)
						@@list_of_registers[@@place_register_key].store(:daterange,daterange)
					end

#validate dates in the record and allow for the split date format 1567/8 and 1567/68 creates a base year and a split year eg /8



                               #clean up the sex field
                               def self.cleansex(field)
                                 if field.nil? || field.empty?
                                   field = nil
                                 else
                                   case
                                   when VALID_MALE_SEX.include?(field.upcase)
                                     field = "M"

                                   when UNCERTAIN_MALE_SEX.include?(field.upcase)
                                     field = "M?"

                                   when VALID_FEMALE_SEX.include?(field.upcase)
                                     field = "F"

                                   when UNCERTAIN_FEMALE_SEX.include?(field.upcase)
                                     field = "F?"

                                   when UNCERTAIN_SEX.include?(field.upcase)
                                     field = "?"
                                   else
                                     field
                                   end #end case
                                 end #end if
                                 field
                               end #end meth

                                 



                                 #process the baptism record columns
                                 def self.process_baptism_data_records(n)
                                   data_record = Hash.new
                                   data_record[:line_id] = @@userid + "." + File.basename(@@filename.upcase) + "." + n.to_s
                                   data_record[:file_line_number] = n
                                   data_record[:register_entry_number] = @csvdata[3]
                                   data_record[:birth_date] = @csvdata[4]
                                   data_record[:baptism_date] = @csvdata[5]
                                   data_record[:year] = FreeregValidations.year_extract(@csvdata[5])
                                   data_record[:year] = FreeregValidations.year_extract(@csvdata[4]) if FreeregValidations.year_extract(@csvdata[5]).nil?
                                   datestat(data_record[:year]) unless data_record[:year].nil?
                                   data_record[:person_forename] = @csvdata[6]
                                   data_record[:person_sex] = cleansex(@csvdata[7])
                                   data_record[:father_forename] = @csvdata[8]
                                   data_record[:mother_forename] = @csvdata[9]
                                   data_record[:father_surname] = Unicode::upcase(@csvdata[10]) unless @csvdata[10].nil?
                                   data_record[:father_surname] = @csvdata[10]  if @csvdata[10].nil?
                                   data_record[:mother_surname] = Unicode::upcase(@csvdata[11]) unless @csvdata[11].nil?
                                   data_record[:mother_surname] = @csvdata[11]  if @csvdata[11].nil?
                                   data_record[:person_abode] = @csvdata[12]
                                   data_record[:father_occupation] = @csvdata[13]
                                   data_record[:notes] = @csvdata[14]
                                   number = @@list_of_registers[@@place_register_key].fetch(:records)
                                   number = number + 1
                                   @@list_of_registers[@@place_register_key].store(:records,number)

                                   if @@header[:lds] then
                                     data_record[:film] = @csvdata[15]
                                     data_record[:film_number] = @csvdata[16]
                                   end
                                   @@data_hold[@@place_register_key].store(number,data_record)

                                 end
                                 #process the marriage data columns

                                 def self.process_marriage_data_records(n)
                                   data_record = Hash.new
                                   data_record[:line_id] = @@userid + "." + File.basename(@@filename.upcase) + "." + n.to_s
                                   data_record[:file_line_number] = n

                                   data_record[:register_entry_number] = @csvdata[3]

                                   data_record[:marriage_date] = @csvdata[4]
                                   data_record[:year] = FreeregValidations.year_extract(@csvdata[4])
                                   datestat(data_record[:year]) unless data_record[:year].nil?
                                   data_record[:groom_forename] = @csvdata[5]
                                   data_record[:groom_surname] = Unicode::upcase(@csvdata[6]) unless @csvdata[6].nil?
                                   data_record[:groom_surname] = @csvdata[6]  if @csvdata[6].nil?
                                   data_record[:groom_age] = @csvdata[7]
                                   data_record[:groom_parish] = @csvdata[8]
                                   #    raise FreeREGError, "The groom's condition #{@csvdata[9]} contains unknown condition #{@csvdata[9]} in line #{n}" unless cleancondition(9)
                                   data_record[:groom_condition] = @csvdata[9]
                                   data_record[:groom_occupation] = @csvdata[10]
                                   data_record[:groom_abode] = @csvdata[11]
                                   data_record[:bride_forename] = @csvdata[12]
                                   data_record[:bride_surname] = Unicode::upcase(@csvdata[13]) unless @csvdata[13].nil?
                                   data_record[:bride_surname] = @csvdata[13] if @csvdata[13].nil?
                                   data_record[:bride_age] = @csvdata[14]
                                   data_record[:bride_parish] = @csvdata[15]
                                   #    raise FreeREGError, "The bride's condition #{@csvdata[16]} contains unknown condition in line #{n}" unless cleancondition(16)
                                   data_record[:bride_condition] = @csvdata[16]
                                   data_record[:bride_occupation] = @csvdata[17]
                                   data_record[:bride_abode] = @csvdata[18]
                                   data_record[:groom_father_forename] = @csvdata[19]
                                   data_record[:groom_father_surname] = Unicode::upcase(@csvdata[20]) unless @csvdata[20].nil?
                                   data_record[:groom_father_surname] = @csvdata[20] if @csvdata[20].nil?
                                   data_record[:groom_father_occupation] = @csvdata[21]
                                   data_record[:bride_father_forename] = @csvdata[22]
                                   data_record[:bride_father_surname] = Unicode::upcase(@csvdata[23]) unless @csvdata[23].nil?
                                   data_record[:bride_father_surname] = @csvdata[23] if @csvdata[23].nil?
                                   data_record[:bride_father_occupation] = @csvdata[24]
                                   data_record[:witness1_forename] = @csvdata[25]
                                   data_record[:witness1_surname] = Unicode::upcase(@csvdata[26]) unless @csvdata[26].nil?
                                   data_record[:witness1_surname] = @csvdata[26] if @csvdata[26].nil?
                                   data_record[:witness2_forename] = @csvdata[27]
                                   data_record[:witness2_surname] = Unicode::upcase(@csvdata[28]) unless @csvdata[28].nil?
                                   data_record[:witness2_surname] = @csvdata[28] if @csvdata[28].nil?
                                   data_record[:notes] = @csvdata[29]

                                   number = @@list_of_registers[@@place_register_key].fetch(:records)
                                   number = number + 1
                                   @@list_of_registers[@@place_register_key].store(:records,number)

                                   if @@header[:lds]  then
                                     data_record[:film] = @csvdata[30]
                                     data_record[:film_number] = @csvdata[31]
                                   end
                                   @@data_hold[@@place_register_key].store(number,data_record)
                                 end

                                 #process the burial data columns
                                 def self.process_burial_data_records(n)
                                   data_record = Hash.new
                                   data_record[:line_id] = @@userid + "." + File.basename(@@filename.upcase) + "." + n.to_s
                                   data_record[:file_line_number] = n
                                   data_record[:register_entry_number] = @csvdata[3]
                                   data_record[:burial_date] = @csvdata[4]
                                   data_record[:year] = FreeregValidations.year_extract(@csvdata[4])
                                   datestat(data_record[:year]) unless data_record[:year].nil?
                                   data_record[:burial_person_forename] = @csvdata[5]
                                   data_record[:relationship] = @csvdata[6]
                                   data_record[:male_relative_forename] = @csvdata[7]
                                   data_record[:female_relative_forename] = @csvdata[8]
                                   data_record[:relative_surname] = Unicode::upcase(@csvdata[9]) unless @csvdata[9].nil?
                                   data_record[:relative_surname] = @csvdata[9] if @csvdata[9].nil?
                                   data_record[:burial_person_surname] = Unicode::upcase(@csvdata[10])  unless @csvdata[10].nil?
                                   data_record[:burial_person_surname] = @csvdata[10]  if @csvdata[10].nil?
                                   data_record[:person_age] = @csvdata[11]
                                   data_record[:burial_person_abode] = @csvdata[12]
                                   data_record[:notes] = @csvdata[13]
                                   number = @@list_of_registers[@@place_register_key].fetch(:records)
                                   number = number + 1
                                   @@list_of_registers[@@place_register_key].store(:records,number)

                                   if @@header[:lds]   then
                                     data_record[:film] = @csvdata[14]
                                     data_record[:film_number] = @csvdata[15]
                                   end
                                   @@data_hold[@@place_register_key].store(number,data_record)
                                 end

                                 def self.delete_all
                                   Freereg1CsvEntry.delete_all
                                   Freereg1CsvFile.delete_all
                                   SearchRecord.delete_freereg1_csv_entries
                                 end
                                 #process the first 4 columns of the data record
                                 # County, Place, Church, Reg #
                                 def self.setup_or_add_to_list_of_registers(place_register_key,data_record)
                                   #this code is needed to permit multiple places and churches in a single batch in any order
                                   @@datemax = DATEMIN
                                   @@datemin = DATEMAX
                                   @@daterange = Array.new(50){|i| i * 0 }
                                   @number_of_records = 0
                                   @@list_of_registers[place_register_key] = Hash.new
                                   @@data_hold[place_register_key] = Hash.new
                                   @@list_of_registers[place_register_key].store(:county,data_record[:county])
                                   @@list_of_registers[place_register_key].store(:place,data_record[:place])
                                   @@list_of_registers[place_register_key].store(:church_name,data_record[:church_name])
                                   @@list_of_registers[place_register_key].store(:register_type,data_record[:register_type])
                                   @@list_of_registers[place_register_key].store(:record_type,data_record[:record_type])
                                   @@list_of_registers[place_register_key].store(:alternate_register_name,data_record[:alternate_register_name])
                                   @@list_of_registers[place_register_key].store(:records,@number_of_records)
                                   @@list_of_registers[place_register_key].store(:datemax,@@datemax)
                                   @@list_of_registers[place_register_key].store(:datemin,@@datemin)
                                   @@list_of_registers[place_register_key].store(:daterange,@@daterange)
                                 end

                                 def self.process_register_headers
                                   @all_records_hash = Hash.new
                                   @all_error_batches_hash = Hash.new
                                   @batches_with_errors = Array.new
                                   @locations = Array.new
                                   #p "start"
                                   #p @@update
                                   if @@update
                                     # Need to get all the records for this file regardless of location
                                     @freereg1_csv_files = Freereg1CsvFile.where(:file_name => @@header[:file_name], :userid => @@header[:userid]).all
                                     @freereg1_csv_files.each do |batch|
                                       @locations << batch._id
                                       batch.batch_errors.delete_all
                                       batch.freereg1_csv_entries.each do |entry|
                                         @all_records_hash[entry.id] = entry.record_digest
                                       end
                                     end
                                     @locations.uniq
                                     p "There are #{@locations.length} locations and #{@all_records_hash.length} existing records for this file"
                                     #p @all_records_hash.inspect
                                   end
                                   @@list_of_registers.each do |place_key,head_value|
                                     #deal with a location. Firstly deal with the batch entry
                                     @batch_errors = 0
                                     @@header.merge!(head_value)
                                     #p "Processing #{@@header[:records]} records for this location"
                                     if @@update
                                       #lets get the file
                                       @freereg1_csv_file = Freereg1CsvFile.where(:file_name => @@header[:file_name], :userid => @@header[:userid],
                                                                                  :county => @@header[:county], :place => @@header[:place], :church_name => @@header[:church_name], :register_type => @@header[:register_type],
                                                                                  :record_type => @@header[:record_type]).first

                                       if @freereg1_csv_file.nil?
                                         @freereg1_csv_file = Freereg1CsvFile.new(@@header)
                                         p "No records in the original batch for this location"
                                       else
                                         p "#{@freereg1_csv_file.records} in the original batch for this location"
                                         #This adds in record count and range etc
                                         @freereg1_csv_file.update_attributes(@@header)
                                         #remove batch errors for this location
                                         @freereg1_csv_file.error = 0
                                         #remove this location from the total locations
                                         ind = @locations.find_index( @freereg1_csv_file._id)
                                         @locations.delete_at(ind) unless ind.nil?
                                       end
                                       #p @freereg1_csv_file
                                     else
                                       # not in update mode
                                       @freereg1_csv_file = Freereg1CsvFile.new(@@header)
                                     end
                                     #locate the batch in a register
                                     @freereg1_csv_file.update_register
                                     #p @freereg1_csv_file
                                     @not_updated = 0
                                     @deleted = 0
                                     @batch_errors = 0
                                     #write the data records for this place/church
                                     @@data_hold[place_key].each do |datakey,datarecord|
                                       datarecord[:county] = head_value[:county]
                                       datarecord[:place] = head_value[:place]
                                       datarecord[:church_name] = head_value[:church_name]
                                       datarecord[:register_type] = head_value[:register_type]
                                       datarecord[:record_type] = head_value[:record_type]
                                       #puts "Data record #{datakey} \n #{datarecord} \n"
                                       success = check_and_create_db_record_for_entry(datarecord,@freereg1_csv_file)
                                       #p "success after check and create"
                                       #p success
                                       if success.nil? || success == "change" || success == "new"
                                         #ok to proceed
                                       elsif success == "nochange"
                                         @not_updated = @not_updated + 1
                                       else
                                         #p "error"
                                         #deal with batch error
                                         batch_error = BatchError.new(error_type: 'Data_Error', record_number: datarecord[:file_line_number],error_message: success,record_type: @freereg1_csv_file.record_type, data_line: datarecord)
                                         batch_error.freereg1_csv_file = @freereg1_csv_file
                                         batch_error.save
                                         @@number_of_error_messages = @@number_of_error_messages + 1
                                         @batch_errors = @batch_errors + 1
                                       end #end success  no change
                                     end #end @@data_hold
                                     #we have finished with the records for that location
                                     #record header errors
                                     errors = @batch_errors
                                     unless @@header_error.nil?
                                       @@header_error.each do |error_key,error_value|
                                         batch_error = BatchError.new(error_type: 'Header_Error', record_number: error_value[:line],error_message: error_value[:error],data_line: error_value[:data])
                                         batch_error.freereg1_csv_file = @freereg1_csv_file
                                         errors = errors + 1
                                         batch_error.save
                                       end #end header errors
                                     end # #header error nil

                                     @freereg1_csv_file.update_attribute(:processed, false) if !@@create_search_records
                                     @freereg1_csv_file.update_attributes(:processed => true, :processed_date => Time.now) if @@create_search_records
                                     @freereg1_csv_file.update_attribute(:error, errors)
                                     @freereg1_csv_file.save
                                     header_errors = 0
                                     header_errors = @@header_error.length unless  @@header_error.nil?
                                     puts "#@@userid #{@@filename} processed  #{@@header[:records]} data lines for location #{@freereg1_csv_file.county}, #{@freereg1_csv_file.place}, #{@freereg1_csv_file.church_name}, #{@freereg1_csv_file.register_type}, #{@freereg1_csv_file.record_type}; #{@not_updated} unchanged and #{@deleted} removed.  #{header_errors} header errors and #{@batch_errors} data errors "
                                     message_file.puts "#@@userid\t#{@@filename}\tprocessed  #{@@header[:records]} data lines for location #{@freereg1_csv_file.county}, #{@freereg1_csv_file.place}, #{@freereg1_csv_file.church_name}, #{@freereg1_csv_file.register_type}, #{@freereg1_csv_file.record_type};  #{@not_updated} unchanged and #{@deleted} removed.  #{header_errors} header errors and #{@batch_errors} data errors"
                                     if @freereg1_csv_file.register.church.place.error_flag == "Place name is not approved"
                                       message_file.puts "Place name is unapproved"
                                     end
                                     #reset ready for next batch
                                     #@@number_of_error_messages = 0
                                     #@@header_error = nil
                                   end #end @@list
                                   #clean out old locations
                                   counter = 0
                                   #p "about to clear hash"
                                   #p @all_records_hash
                                   @all_records_hash.each_key do |record|
                                     counter = counter + 1
                                     actual_record = Freereg1CsvEntry.id(record).first
                                     actual_record.destroy unless actual_record.nil?
                                     sleep_time = 20*(Rails.application.config.sleep.to_f).to_f
                                     sleep(sleep_time) unless actual_record.nil?
                                   end
                                   p "Deleted #{counter} remaining entries and records"
                                   p "deleting #{@locations.length} locations" unless @locations.empty?
                                   @locations.each do |location|
                                     loc = Freereg1CsvFile.find(location)
                                     puts "Removing batch for location #{loc.county}, #{loc.place}, #{loc.church_name}, #{loc.register_type}, #{loc.record_type} for #{loc.file_name} in #{loc.userid}"
                                     message_file.puts "#{loc.userid} #{loc.file_name} removing batch for location #{loc.county}, #{loc.place}, #{loc.church_name}, #{loc.register_type}, #{loc.record_type} for "
                                     loc.delete
                                   end
                                 end

                                 def self.check_and_create_db_record_for_entry(data_record,file_for_record)
                                   if @@update
                                     entry = Freereg1CsvEntry.new(data_record)
                                     new_digest = entry.cal_digest
                                     #p "digest"
                                     #p new_digest.inspect
                                     if @all_records_hash.has_value?(new_digest)
                                       #we have an existing record but may be for different location
                                       #p "existing record"
                                       existing_record = Freereg1CsvEntry.id(@all_records_hash.key(new_digest)).first
                                       #        binding.pry
                                       if existing_record.present?
                                         #p existing_record.inspect
                                         if existing_record.same_location(existing_record,file_for_record)
                                           #p "same location"
                                           #record location is OK
                                           if existing_record.search_record.present?
                                             # search record and entry are OK
                                             success = "nochange"
                                             #p success
                                           else
                                             success = "change"
                                             #need to create search record as one does not exist
                                             #p "creating search as not there"
                                             existing_record.transform_search_record if  @@create_search_records == true
                                           end
                                         else
                                           #p "changing location"
                                           #change of location
                                           #update location of record
                                           record = existing_record.search_record
                                           existing_record.update_location(data_record,file_for_record)

                                           if  record.present?
                                             success = "nochange"
                                             #p "updating record"
                                             #p record.inspect
                                             # need to update search record  with location
                                             record.update_location(data_record,file_for_record)
                                             #p "updated record"
                                             #p record.inspect
                                           else
                                             success = "change"
                                             #need to create search record as one does not exist
                                             #p "created record"
                                             existing_record.transform_search_record if  @@create_search_records == true
                                             #p existing_record.search_record
                                           end
                                         end
                                         #we need to eliminate this record from hash
                                         @all_records_hash.delete(@all_records_hash.key(new_digest))
                                         #p "dropping hash entry"
                                         #p @all_records_hash.inspect
                                       else
                                         #this should never happen but it has
                                         success = "new"
                                         #new entry and record
                                         #p "creating new entry"
                                         success = create_db_record_for_entry(data_record)
                                         #p "new"
                                         #p success
                                         sleep_time = 10*(Rails.application.config.sleep.to_f).to_f
                                         sleep(sleep_time)
                                       end
                                     else
                                       success = "new"
                                       #new entry and record
                                       #p "creating new entry"
                                       success = create_db_record_for_entry(data_record)
                                       #p "new"
                                       #p success
                                       sleep_time = 10*(Rails.application.config.sleep.to_f).to_f
                                       sleep(sleep_time)
                                     end
                                   else
                                     success = "new"
                                     #new entry and record
                                     #p "creating new entry"
                                     success = create_db_record_for_entry(data_record)
                                     #p "new"
                                     #p success
                                     sleep_time = 10*(Rails.application.config.sleep.to_f).to_f
                                     sleep(sleep_time)
                                   end
                                   success
                                 end

                                 def self.create_db_record_for_entry(data_record)
                                   # TODO: bring data_record hash keys in line with those in Freereg1CsvEntry
                                   entry = Freereg1CsvEntry.new(data_record)
                                   if data_record[:record_type] == "ma"
                                     entry.multiple_witnesses << MultipleWitness.new(:witness_forename => data_record[:witness1_forename],:witness_surname => data_record[:witness1_surname]) unless data_record[:witness1_forename].blank? && data_record[:witness1_surname].blank?
                                     entry.multiple_witnesses << MultipleWitness.new(:witness_forename => data_record[:witness2_forename],:witness_surname => data_record[:witness2_surname]) unless data_record[:witness2_forename].blank? && data_record[:witness2_surname].blank?
                                   end
                                   entry.freereg1_csv_file = @freereg1_csv_file
                                   # p "creating entry"
                                   entry.save
                                   # p entry
                                   if entry.errors.any?
                                     success = entry.errors.messages
                                   else
                                     entry.transform_search_record if  @@create_search_records == true
                                     success = "new"
                                   end
                                   # p entry.search_record
                                   success
                                 end

                                 def self.process_the_data
                                   #we do this here so that the logfile is only deleted if we actually process the file!


                                   @@number_of_line = 0
                                   @@number_of_error_messages = 0
                                   @line_type = 'hold'
                                   @@header_line = 1
                                   n = 1
                                   loop do
                                     begin
                                       @line_type = get_line_of_data
                                       if @line_type == 'Header'
                                         case
                                         when @@header_line == 1
                                           process_header_line_one
                                           @@header_line = @@header_line + 1
                                         when @@header_line == 2
                                           process_header_line_two
                                           @@header_line = @@header_line + 1
                                         when @@header_line == 3
                                           process_header_line_threee
                                           @@header_line = @@header_line + 1
                                         when @@header_line == 4
                                           process_header_line_four
                                           @@header_line = @@header_line + 1
                                         when @@header_line == 5
                                           process_header_line_five
                                           @@header_line = @@header_line + 1
                                         else
                                           raise FreeREGError,  "Header_Error,Unknown header "
                                         end #end of case

                                       else

                                         type = @@header[:record_type]
                                         process_register_location(n)
                                         case type
                                         when RecordType::BAPTISM then process_baptism_data_records(n)
                                         when RecordType::BURIAL then process_burial_data_records(n)
                                         when RecordType::MARRIAGE then process_marriage_data_records(n)
                                         end# end of case
                                         n =  n + 1

                                       end #end of line type loop

                                       @@number_of_line = @@number_of_line + 1

                                       #  break if n == 10

                                       #rescue the freereg data errors and continue processing the file

                                     rescue FreeREGError => free
                                       unless free.message == "Empty data line" then

                                         @@number_of_error_messages = @@number_of_error_messages + 1
                                         @csvdata = @@array_of_data_lines[@@number_of_line]
                                         puts "#{@@userid} #{@@filename}" + free.message + " at line #{@@number_of_line}"
                                         message_file.puts "#{@@userid}\t#{@@filename}" + free.message + " at line #{@@number_of_line}"


                                         @@header_error[@@number_of_error_messages] = Hash.new
                                         @@header_error[@@number_of_error_messages].store(:line,@@number_of_line)
                                         @@header_error[@@number_of_error_messages].store(:error,free.message)
                                         @@header_error[@@number_of_error_messages].store(:data,@csvdata)
                                       end
                                       @@number_of_line = @@number_of_line + 1
                                       #    n = n - 1 unless n == 0
                                       @@header_line = @@header_line + 1 if @line_type == 'Header'
                                       break if free.message == "Empty file"
                                       retry
                                     rescue FreeREGEnd => free
                                       n = n - 1
                                       process_register_headers
                                       break
                                     rescue  => e


                                       puts e.message
                                       puts e.backtrace
                                       message_file.puts "#{@@userid}\t#{@@filename} line #{n} crashed the processor\n"
                                       message_file.puts e.message
                                       message_file.puts e.backtrace.inspect
                                       break

                                     end#end of begin

                                   end #end of loop
                                   return n
                                 end #end of method


                                 def self.qualify_path(path)
                                   unless path.match(/^\//) || path.match(/:/) # unix root or windows
                                     path = File.join(Rails.root, path)
                                   end

                                   path
                                 end

                                 def self.message_file
                                   unless defined? @@message_file
                                     file_for_warning_messages = File.join(Rails.root,"log/update_freereg_messages")
                                     time = Time.new.to_i.to_s
                                     file_for_warning_messages = (file_for_warning_messages + "." + time + ".log").to_s
                                     @@message_file = File.new(file_for_warning_messages, "w")
                                     @@message_file.puts " Using #{Rails.application.config.website}"

                                   end

                                   @@message_file
                                 end



                               end #class end

                               #set the FreeREG error conditions
                               class FreeREGError < StandardError
                               end

                               class FreeREGEnd < StandardError
                               end
