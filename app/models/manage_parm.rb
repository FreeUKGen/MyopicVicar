class ManageParm
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  field :year, type: String
  field :chapman_code, type: String
  field :userid, type: String
  field :file_name, type: String
  field :date_of_addition, type: DateTime
  field :process, type: Integer, default: 0
  validate :validate_file_name, on: :create
  validate :validate_file_type, on: :create
  validate :validate_file_header_format, on: :create
  validate :validate_parms_header, on: :create
  validate :validate_file_content, on: :create
  attr_accessor :parm_file, :file_path

  DESTINATION = "#{Rails.root}/parms_files/"
  ALLOWED_FILE_TYPES = ['.dat', '.DAT', '.csv', '.CSV']

  def import
    self.file_name = self.parm_file.original_filename
    self.file_path = self.parm_file.tempfile.path
  end

  def load_parm_files#(file, year)
    #file_name = file.original_filename
    #file_path = file.tempfile.path
    move_parm_files(file_path, file_name, year)
  end

  def validate_file_name
    chapman = self.file_name[0,3].upcase
    csv_file = "Parms.csv".downcase
    dat_file = "Parms.dat".downcase
    if chapman != self.chapman_code.upcase
      errors.add(:file_name, "Please upload the #{self.chapman_code} Parms File. Current Parms file belongs to #{chapman}")
    end
    unless self.file_name.downcase.end_with?(csv_file,dat_file)
      errors.add(:file_name, "Please rename the parm file as #{self.chapman_code}Parms.csv or #{self.chapman_code}Parms.dat")
    end
  end

  def validate_parms_header
    unless read_parm_file.length > 1 && read_parm_file[0].length >= 3
      errors.add(:parm_file, "Invalid ctyPARMS.CSV file. Please make sure it is a .CSV (not a .DAT file), and that it is properly formatted as a .CSV, has the correct 3-column header, and uses a UTF-8 compatible character set.") and return
    end
  end

  def parms_header
    read_parm_file[0]
  end

  def read_parm_file
    CSV.read(file_path)
  end

  def validate_file_type
    unless ALLOWED_FILE_TYPES.include? File.extname(file_name)
      errors.add(:base, "Invalid File type. Please use CSV or DAT file types")
    end
  end

  def move_parm_files(origin_file_path, file_name, year)
    destination_file_path = "#{DESTINATION}#{year}"
    # Create directory if not exists
    dest = File.join(destination_file_path, file_name)
    FileUtils.mkdir_p(File.dirname(dest))

    # Move parm files to destination
    if File.exists? File.join(destination_file_path, file_name)
      # Add 1- if the filename already exists
      FileUtils.move origin_file_path, File.join(destination_file_path, "1-#{file_name}")
    else
      FileUtils.move origin_file_path, "#{destination_file_path}/#{file_name}"
    end
  end

  def parm_file_info
    #parm = Dir.glob(File.join("#{DESTINATION}#{year}", "#{file_name}")) rescue []
    digest = Digest::MD5.file(self.parm_file.tempfile.path) rescue nil
    base_name = File.basename(file_name) rescue nil
    chapman = base_name[0, 3].upcase rescue nil
    if chap.blank? || bn.blank? || dig.blank? || !ChapmanCode::values.include?(chap)
      log_message("***WARNING: SKIPPING parms file for unrecognized CHAPMAN CODE or failed to compute md5 (possibly a permissions issue?) '#{chap}' ('#{yy_file}')") if log_messages
    else
      parms_info << {'year' => yy, 'chapman' => chap, 'file' => yy_file, 'base' => bn, 'digest' => dig}
    end
    parms_info
  end

  def get_file
    Freecen1FixedDatFile.where(year: self.year, chapman_code: self.chapman_code)
  end

  def check_file_present?
    get_file.present?
  end

  def check_for_changes_if_parm_exists
    true if get_file.first.file_digest.blank? || (get_file.first.file_digest != parm_file_info['digest'])
  end

  def run_new_file_processer
    new_file_path = "#{DESTINATION}#{self.year}/#{self.file_name}"
    unless checkfile_present?
      begin
        process_parms_file(new_file_path)
      rescue => e # rescue any exceptions and continue processing the other VLDs
        log_message("***EXCEPTION CAUGHT while processing process_parms_file :\n  #{e.message}")
        unless e.message && e.message.include?("Place name can't be blank")
          log_message(e.backtrace.inspect)
        end
        # remove the parms from the database because it didn't load properly
        begin
          delete_parms_and_associated_vlds_from_db(self.year, self.chapman_code)
        rescue => e
          log_message("  ***EXCEPTION CAUGHT while trying to clean up during rescue from previous exception! The database may not have been fully cleaned up for this PARMS file.\n  #{e.message}")
          log_message(e.backtrace.inspect)
        end
      end
    end
  end

  def deleted_parms
    parm_file_info
  end

  def drop_deleted_parms

  end

  def validate_file_header_format
    year = parms_header[2].to_s[0,4]
    chapman = parms_header[2].to_s[4,3]
    errors.add(:parm_file, "Invalid year specified in header. Third column of .csv header should have the county chapman code and year, for example 'CON1841' for Cornwall 1841.") unless Freecen::CENSUS_YEARS.include? year
    errors.add(:parm_file, "Please upload #{self.year} parm file. The year in current parm file(#{year}) does not match the year selected") unless year == self.year
    errors.add(:parm_file, "Invalid chapman code specified in header. Third column of .csv header should have the county chapman code and year, for example 'CON1841' for Cornwall 1841.") unless ChapmanCode.values.include? chapman
  end

  def validate_file_content_length line, idx
    length_lims = [4,4,7,7,8,24,3,1]
    line.each_with_index do |col, colidx|
      next if colidx == 2 || colidx == 3
      if col.present? && col.to_s.length > length_lims[colidx].to_i
        errors.add(:parm_file, "line #{idx}, column #{colidx+1}: length greater than (#{length_lims[colidx].to_i})")
      end
    end
  end

  def validate_file_content
    file_content.each_with_index do |line, idx|
      validate_file_content_length line, idx
      validate_file_content_character line, idx
      presence_of_civil_or_enumeration_district_names line, idx
      absence_of_short_lines line, idx
    end
  end

  def validate_file_content_character line, idx
    if line[7] != 'a' && line[7] != 'b'
      errors.add(:parm_file, "line #{idx}, column 7: should be a single character, either 'a' or 'b'")
    end
    if line[2].present? && line[7]== 'b'
      errors.add(:parm_file, "line #{idx} column 3 is specified for a 'b' record")
    end
    if line[3].present? && line[7]== 'a'
      errors.add(:parm_file, "line #{idx} column 4 is specified for an 'a' record")
    end
  end

  def presence_of_civil_or_enumeration_district_names line, idx
    if line[2].blank? && line[3].blank?
      errors.add(:parm_file, "line #{idx}: columns 3 and 4 are both blank.")
    end
  end

  def absence_of_short_lines line, idx
    if line.length < 8
      errors.add(:parm_file, "line #{idx} has less than 8 columns. This system expects 8 columns of data for each line.")
    end
  end

  def file_content
    read_parm_file.drop(1)
  end
end
