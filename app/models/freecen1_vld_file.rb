class Freecen1VldFile
  include Mongoid::Document
  include Mongoid::Timestamps::Short
  require 'chapman_code'
  require 'freecen_constants'

  field :file_name, type: String
  field :dir_name, type: String
  field :census_type, type: String
  field :raw_year, type: String
  field :full_year, type: String
  field :piece, type: Integer
  field :series, type: String
  field :sctpar, type: String
  field :file_digest, type: String
  field :file_errors, type: Array
  field :transcriber_name, type: String
  field :transcriber_email_address, type: String
  field :transcriber_userid, type: String
  field :num_entries, type: Integer, default: 0
  field :num_individuals, type: Integer, default: 0
  field :num_dwellings, type: Integer, default: 0
  field :num_invalid_pobs, type: Integer

  field :userid, type: String
  field :action, type: String
  field :uploaded_file, type: String
  field :uploaded_file_name, type: String
  field :uploaded_file_location, type: String
  field :file_name_lower_case, type: String

  before_validation :remove_whitespace
  before_save :add_lower_case
  mount_uploader :uploaded_file, VldfileUploader

  has_many :freecen1_vld_entries
  has_many :freecen_dwellings
  has_many :search_records
  belongs_to :freecen_piece, optional: true, index: true
  belongs_to :freecen2_place, optional: true, index: true
  belongs_to :freecen2_piece, optional: true, index: true
  belongs_to :freecen2_district, optional: true, index: true

  class << self
    def chapman(chapman)
      where(dir_name: chapman)
    end

    def valid_freecen1_vld_file?(freecen1_vld_file)
      result = false
      return result if freecen1_vld_file.blank?

      file = Freecen1VldFile.find_by(id: freecen1_vld_file)
      result = true if file.present? && ChapmanCode.value?(file.dir_name) && Freecen::CENSUS_YEARS_ARRAY.include?(file.full_year)
      logger.warn("FREECEN:LOCATION:VALIDATION invalid freecen1_vld_file #{freecen1_vld_file} ") unless result
      result
    end

    def before_year_totals(time)
      last_id = BSON::ObjectId.from_time(time)
      total_files = {}
      total_entries = {}
      total_individuals = {}
      total_dwellings = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        total_files[year] = Freecen1VldFile.where(_id: { '$lte' => last_id }, full_year: year).hint('id_county_year_file').count
        total_entries[year] = 0
        total_dwellings[year] = 0
        total_individuals[year] = 0
        Freecen1VldFile.where(_id: { '$lte' => last_id }, full_year: year).hint('id_year_file').each do |file|
          total_entries[year] += file.num_entries
          total_dwellings[year] += file.num_dwellings
          total_individuals[year] += file.num_individuals
        end
      end
      [total_files, total_entries, total_individuals, total_dwellings]
    end

    def between_dates_year_totals(time1, time2)
      last_id = BSON::ObjectId.from_time(time2)
      first_id = BSON::ObjectId.from_time(time1)
      total_files = {}
      total_entries = {}
      total_individuals = {}
      total_dwellings = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        files = Freecen1VldFile.between(_id: first_id..last_id).where(full_year: year).hint('id_year_file')
        total_files[year] = files.count
        total_entries[year] = 0
        total_individuals[year] = 0
        total_dwellings[year] = 0
        files.each do |file|
          total_entries[year] += file.num_entries
          total_dwellings[year] += file.num_dwellings
          total_individuals[year] += file.num_individuals
        end
      end
      [total_files, total_entries, total_individuals, total_dwellings]
    end

    def before_county_year_totals(chapman, time)
      last_id = BSON::ObjectId.from_time(time)
      total_files = {}
      total_entries = {}
      total_individuals = {}
      total_dwellings = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        total_files[year] = Freecen1VldFile.where(_id: { '$lte' => last_id }, dir_name: chapman, full_year: year).hint('id_county_year_file').count
        total_entries[year] = 0
        total_individuals[year] = 0
        total_dwellings[year] = 0
        Freecen1VldFile.where(_id: { '$lte' => last_id }, dir_name: chapman, full_year: year).hint('id_county_year_file').each do |file|
          total_entries[year] += file.num_entries
          total_dwellings[year] += file.num_dwellings
          total_individuals[year] += file.num_individuals
        end
      end
      [total_files, total_entries, total_individuals, total_dwellings]
    end

    def between_dates_county_year_totals(chapman, time1, time2)
      last_id = BSON::ObjectId.from_time(time2)
      first_id = BSON::ObjectId.from_time(time1)
      total_files = {}
      total_entries = {}
      total_individuals = {}
      total_dwellings = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        total_files[year] = Freecen1VldFile.between(_id: first_id..last_id).where(dir_name: chapman, full_year: year).hint('id_county_year_file').count
        total_entries[year] = 0
        total_individuals[year] = 0
        total_dwellings[year] = 0
        Freecen1VldFile.between(_id: first_id..last_id).where(dir_name: chapman, full_year: year).hint('id_county_year_file').each do |file|
          total_entries[year] += file.num_entries
          total_dwellings[year] += file.num_dwellings
          total_individuals[year] += file.num_individuals
        end
      end
      [total_files, total_entries, total_individuals, total_dwellings]
    end

    def create_audit_record(vld_file, who, loaded_date, fc2_piece_id)
      @vld_audit = Freecen1VldFileAudit.new
      @vld_audit.add_fields(vld_file, who, loaded_date, fc2_piece_id)
      @vld_audit.save
    end

    def delete_search_records(dir_name, file_name)
      Freecen1VldFile.where(dir_name: dir_name, file_name: file_name).each do |file|
        SearchRecord.where(freecen1_vld_file_id: file.id).destroy_all
      end
    end

    def delete_freecen1_vld_entries(dir_name, file_name)
      Freecen1VldFile.where(dir_name: dir_name, file_name: file_name).each do |file|
        Freecen1VldEntry.where(freecen1_vld_file_id: file.id).destroy_all
      end
    end

    def delete_dwellings(dir_name, file_name)
      Freecen1VldFile.where(dir_name: dir_name, file_name: file_name).each do |file|
        FreecenDwelling.where(freecen1_vld_file_id: file.id).destroy_all
      end
    end

    def delete_individuals(dir_name, file_name)
      Freecen1VldFile.where(dir_name: dir_name, file_name: file_name).each do |file|
        FreecenIndividual.where(freecen1_vld_file_id: file.id).destroy_all
      end
    end

    def delete_file_errors(dir_name, file_name)
      Freecen1VldFile.where(dir_name: dir_name, file_name: file_name).each do |file|
        file.update_attributes(file_errors: nil)
      end
    end

    def save_to_attic(dir_name, file_name)
      attic_dir = File.join(File.join(Rails.application.config.vld_file_locations, dir_name), '.attic')
      FileUtils.mkdir_p(attic_dir)
      file_location = File.join(Rails.application.config.vld_file_locations, dir_name, file_name)
      if File.file?(file_location)
        time = Time.now.to_i.to_s
        renamed_file = (file_location + '.' + time).to_s
        File.rename(file_location, renamed_file)
        FileUtils.mv(renamed_file, attic_dir, verbose: true)
      end
    end
  end
  # ######################################################################### instance methods

  def add_lower_case
    self[:file_name_lower_case] = self[:file_name].downcase if self[:file_name].present?
  end

  def auto_validate_pobs(email_userid)
    mode = 'F'
    logger.warn("FREECEN:VLD_POB_VALIDATION: Starting rake task for #{email_userid} VLD File #{file_name} in #{dir_name}")
    pid1 = spawn("bundle exec rake freecen:vld_auto_validate_pob[#{mode},#{dir_name},#{file_name},#{email_userid}]")
    logger.warn("FREECEN:VLD_POB_VALIDATION: rake task for #{pid1}")
  end

  def chapman_code
    dir_name.sub(/-.*/, '')
  end

  def create_csv_file
    @chapman_code = chapman_code
    year, piece, series = FreecenPiece.extract_year_and_piece(file_name)
    success, message, file, census_fields = convert_file_name_to_csv(year, piece, series)
    if success
      file_location = Rails.root.join('tmp', file)
      success, message = write_csv_file(file_location, census_fields, series, year)
    end
    [success, message, file_location, file]
  end

  def create_entry_csv_file
    @chapman_code = chapman_code
    year, piece, series = FreecenPiece.extract_year_and_piece(file_name)
    success, message, file, census_fields = convert_file_name_to_csv(year, piece, series)
    if success
      file_location = Rails.root.join('tmp', file)
      success, message = write_entry_csv_file(file_location, Freecen1VldEntry.fields.keys, year)
    end
    [success, message, file_location, file]
  end

  def convert_file_name_to_csv(year, piece, series)
    case series
    when 'RG'
      success = true
      message = ''
      case year
      when '1861'
        file = 'RG9' + '_' + piece.to_s + '.csv'
        census_fields = Freecen::CEN2_1861
      when '1871'
        file = 'RG10' + '_' + piece.to_s + '.csv'
        census_fields = Freecen::CEN2_1871
      when '1881'
        file = 'RG11' + '_' + piece.to_s + '.csv'
        census_fields = Freecen::CEN2_1881
      when '1891'
        file = 'RG12' + '_' + piece.to_s + '.csv'
        census_fields = Freecen::CEN2_1891
      when '1901'
        file = 'RG13' + '_' + piece.to_s + '.csv'
        census_fields = Freecen::CEN2_1901
      when '1911'
        file = 'RG14' + '_' + piece.to_s + '.csv'
        census_fields = Freecen::CEN2_1911
        census_fields = Freecen::CEN2_CHANNEL_ISLANDS_1911 if %w[CHI ALD GSY JSY].include?(@chapman_code)
      when '1921'
        file = 'RG15' + '_' + piece.to_s + '.csv'
        census_fields = Freecen::CEN2_1921
      end
    when 'HS'
      success = false
      case year
      when '1841'
        success = true
        message = ''
        file = 'HS4' + '_' + piece.to_s + '.csv'
        census_fields = Freecen::CEN2_SCT_1841
      when '1851'
        success = true
        message = ''
        file = 'HS5' + '_' + piece.to_s + '.csv'
        census_fields = Freecen::CEN2_SCT_1851
      end
    when 'RS'
      success = false
      case year
      when '1861'
        success = true
        message = ''
        file = 'RS6' + '_' + piece.to_s + '.csv'
        census_fields = Freecen::CEN2_SCT_1861
      when '1871'
        success = true
        message = ''
        file = 'RS7' + '_' + piece.to_s + '.csv'
        census_fields = Freecen::CEN2_SCT_1871
      when '1881'
        success = true
        message = ''
        file = 'RS8' + '_' + piece.to_s + '.csv'
        census_fields = Freecen::CEN2_SCT_1881
      when '1891'
        success = true
        message = ''
        file = 'RS9' + '_' + piece.to_s + '.csv'
        census_fields = Freecen::CEN2_SCT_1891
      when '1901'
        file = 'RS10' + '_' + piece.to_s + '.csv'
        census_fields = Freecen::CEN2_SCT_1901
      when '1911'
        file = 'RS11' + '_' + piece.to_s + '.csv'
        census_fields = Freecen::CEN2_SCT_1911
      end
    when 'HO'
      success = true
      message = ''
      file = 'HO107' + '_' + piece.to_s + '.csv'
      census_fields = piece.to_i <= 1465 ? Freecen::CEN2_1841 : Freecen::CEN2_1851
    else
    end
    [success, message, file, census_fields]
  end

  def write_csv_file(file_location, census_fields, series, year)
    header = census_fields
    @initial_line_hash = {}
    @blank = nil
    @dash = '-'
    census_fields.each do |field|
      @initial_line_hash[field] = nil
    end
    CSV.open(file_location, 'wb', { row_sep: "\r\n" }) do |csv|
      csv << header
      records = freecen1_vld_entries.order_by(_id: 1)
      @record_number = 0
      records.each do |rec|
        next if rec.blank?

        @record_number += 1
        line = add_fields(rec, census_fields, series, year)
        csv << line
      end
    end
    [true, '']
  end

  def write_entry_csv_file(file_location, census_fields, year)
    header = census_fields
    @initial_line_hash = {}
    @blank = nil
    @dash = '-'
    census_fields.each do |field|
      @initial_line_hash[field] = nil
    end
    CSV.open(file_location, 'wb', { row_sep: "\r\n" }) do |csv|
      csv << header
      records = freecen1_vld_entries.order_by(_id: 1)
      @record_number = 0
      records.each do |rec|
        @record_number += 1
        line = add_entry_fields(rec, census_fields, year)
        csv << line
      end
    end
    [true, '']
  end

  def add_entry_fields(rec, census_fields, year)
    line = []
    census_fields.each do |field|
      if (field.to_s == 'birth_county' && rec[field.to_s] == rec['verbatim_birth_county'] && rec['birth_place'] == rec['verbatim_birth_place']) ||
          (field.to_s == 'birth_place' && rec[field.to_s] == rec['verbatim_birth_place'] && rec['birth_county'] == rec['verbatim_birth_county'])
        line << ''
      else
        line << rec[field.to_s]
      end
    end
    line
  end

  def add_fields(rec, census_fields, series, year)
    line = []
    census_fields.each do |field|
      case field
      when 'enumeration_district'
        line << compute_enumeration_district(rec, census_fields)
      when 'civil_parish'
        line << compute_civil_parish(rec)
      when 'ecclesiastical_parish'
        line << compute_ecclesiastical_parish(rec)
      when 'where_census_taken'
        line << compute_where_census_taken(rec)
      when 'location_flag', 'address_flag', 'name_flag', 'individual_flag', 'occupation_flag', 'birth_place_flag'
        line << @blank
      when 'folio_number'
        line << compute_folio_number(rec)
      when 'page_number'
        line << compute_page_number(rec)
      when 'schedule_number'
        line << compute_schedule_number(rec, census_fields, series, year)
      when 'uninhabited_flag'
        line << compute_uninhabited_flag(rec)
      when 'house_or_street_name'
        number, address = compute_address(rec)
        line << number
        line << address
      when 'surname'
        line << compute_surname(rec)
      when 'forenames'
        line << rec['forenames']
      when 'relationship'
        line << rec['relationship']
      when 'marital_status'
        line << rec['marital_status']
      when 'sex'
        line << rec['sex']
      when 'age'
        line << compute_age(rec)
      when 'occupation'
        line << compute_occupation(rec, year)
      when 'occupation_category'
        line << compute_occupation_category(rec, year)
      when 'verbatim_birth_county'
        line << verbatim_birth_county(rec)
      when 'verbatim_birth_place'
        line << replace_chars_in_pob(rec['verbatim_birth_place'])
      when 'birth_county'
        county, place = compute_alternate(rec)
        line << county
        unless series == 'HS' && year == '1841'
          line << place if census_fields.include?('ecclesiastical_parish') # birth place not in 1841 census
        end
      when 'disability'
        line << rec['disability']
      when 'language'
        line << rec['language']
      when 'notes'
        line << compute_notes(rec)
      when 'ward', 'parliamentary_constituency', 'poor_law_union', 'police_district', 'sanitary_district', 'special_water_district',
          'scavenging_district', 'special_lighting_district', 'school_board'
        entry = @use_blank ? @blank : @dash
        line << entry
      when 'walls', 'roof_type', 'rooms', 'rooms_with_windows', 'school_children', 'class_of_house', 'rooms_with_windows', 'industry', 'at_home', 'years_married',
          'children_born_alive', 'children_living', 'children_deceased', 'nationality', 'disability_notes'
        line << @blank
      else
      end
    end
    line
  end

  def compute_alternate(rec)
    if (rec['birth_county'] == rec['verbatim_birth_county'] && rec['birth_place'] == rec['verbatim_birth_place']) || %w[b n u v].include?(rec['uninhabited_flag'])
      county = @blank
      place = @blank
    else
      county = rec['birth_county'].present? && rec['birth_county'].downcase == 'wal' ? 'WLS' : rec['birth_county']
      place =  replace_chars_in_pob(rec['birth_place'])
    end
    [county, place]
  end

  def verbatim_birth_county(rec)
    county = rec['verbatim_birth_county'].present? && rec['verbatim_birth_county'].downcase == 'wal' ? 'WLS' : rec['verbatim_birth_county']
    county = %w[b n u v].include?(rec['uninhabited_flag']) ? @blank : county
    county
  end

  def compute_enumeration_district(rec, census_fields)
    rec['enumeration_district'] = reformat_enumeration_district(rec['enumeration_district']) if special_enumeration_district?(rec['enumeration_district'])
    if census_fields.include?('ecclesiastical_parish') && (rec['enumeration_district'] == @initial_line_hash['enumeration_district']) && (rec['civil_parish'] == @initial_line_hash['civil_parish']) && (@initial_line_hash['ecclesiastical_parish'] == rec['ecclesiastical_parish'])
      line = @blank
      @use_blank = true
    elsif !census_fields.include?('ecclesiastical_parish') && (rec['enumeration_district'] == @initial_line_hash['enumeration_district']) && (rec['civil_parish'] == @initial_line_hash['civil_parish'])
      line = @blank
      @use_blank = true
    else
      line = rec['enumeration_district']
      @use_blank = false
      @initial_line_hash['enumeration_district'] = rec['enumeration_district']
    end
    line
  end

  def special_enumeration_district?(rec)
    ed_chars = rec.chars
    special_format = (ed_chars.length == 2 && ed_chars[0] == '0') || (ed_chars.length == 3 && ed_chars[1] == '#') ? true : false
    special_format
  end

  def reformat_enumeration_district(rec)
    ed_chars = rec.chars
    ed_chars[0] + '#' + ed_chars[1]
  end

  def compute_civil_parish(rec)
    if !@use_blank
      line = rec['civil_parish']
      @initial_line_hash['civil_parish'] = rec['civil_parish']
    else
      if rec['civil_parish'] == @initial_line_hash['civil_parish']
        line = @blank
      else
        line = rec['civil_parish']
      end
    end
    line
  end

  def compute_ecclesiastical_parish(rec)
    if !@use_blank
      line = rec['ecclesiastical_parish']
      @initial_line_hash['ecclesiastical_parish'] = rec['ecclesiastical_parish']
    else
      if rec['ecclesiastical_parish'] == @initial_line_hash['ecclesiastical_parish']
        line = @blank
      else
        line = rec['ecclesiastical_parish']
        @initial_line_hash['ecclesiastical_parish'] = rec['ecclesiastical_parish']
      end
    end
    line
  end

  def compute_where_census_taken(rec)
    if !@use_blank
      line = rec['ecclesiastical_parish'] if rec['ecclesiastical_parish'].present?
      line = rec['civil_parish'] if rec['civil_parish'].present? && rec['ecclesiastical_parish'].blank?
      @initial_line_hash['where_census_taken'] = line
    else
      if rec['ecclesiastical_parish'].present? && rec['ecclesiastical_parish'] == @initial_line_hash['where_census_taken']
        line = @blank
      elsif rec['civil_parish'].present? && rec['civil_parish'] == @initial_line_hash['where_census_taken']
        line = @blank
      elsif rec['ecclesiastical_parish'].present?
        line = rec['ecclesiastical_parish']
        @initial_line_hash['where_census_taken'] = rec['ecclesiastical_parish']
      elsif rec['civil_parish'].present?
        line = rec['civil_parish']
        @initial_line_hash['where_census_taken'] = rec['civil_parish']
      else
        line = @dash
      end
    end
    line
  end

  def compute_folio_number(rec)
    if rec['folio_number'].present? && rec['folio_number'] == @initial_line_hash['folio_number']
      line = @blank
    else
      line = rec['folio_number']
      @initial_line_hash['folio_number'] = rec['folio_number']
    end
    line
  end

  def compute_page_number(rec)
    if rec['page_number'].present? && rec['page_number'] == @initial_line_hash['page_number']
      line = @blank
    elsif special_enumeration_district?(@initial_line_hash['enumeration_district'])
      line = rec['sequence_in_household'] == 1 ? rec['page_number'] : line = @blank
      @initial_line_hash['page_number'] = rec['page_number']
    else
      line = rec['page_number']
      @initial_line_hash['page_number'] = rec['page_number']
    end
    line
  end

  def compute_schedule_number(rec, census_fields, series, year)
    if rec['dwelling_number'] == @initial_line_hash['dwelling_number'] # NB dwelling_number holds col 5-10 from VLD file (A six digit number (leading zeros) which counts the households)
      line = @blank
    elsif !census_fields.include?('ecclesiastical_parish') || rec['uninhabited_flag'] == 'x' && rec['schedule_number'].blank?
      line = '0'
    elsif series == 'HS' && year == '1841' && rec['schedule_number'].blank?
      line = '0'
    else
      line = rec['schedule_number']
      @initial_line_hash['schedule_number'] = rec['schedule_number']
    end
    line
  end

  def compute_address(rec)
    if rec['dwelling_number'] == @initial_line_hash['dwelling_number']
      number = @blank
      address = @blank
    else
      @initial_line_hash['dwelling_number'] = rec['dwelling_number']
      number = rec['house_number']
      address = rec['house_or_street_name']
    end
    [number, address]
  end

  def compute_surname(rec)
    line = %w[b n u v].include?(rec['uninhabited_flag']) ? '' : rec[:surname]
    line
  end

  def compute_age(rec)
    line = rec['age_unit'].present? ? rec['age'] + rec['age_unit'] : rec['age']
    line
  end

  def compute_occupation(rec, year)
    if %w[1841 1851 1861 1871 1881].include?(year)
      line = rec['occupation']
    elsif /\(em'ee\)/i.match(rec['occupation']) || /\(em'er\)/i.match(rec['occupation'])|| /\(Notem\)/i.match(rec['occupation'])
      parts = rec['occupation'].split('(')
      line = parts[0].strip
    else
      line = rec['occupation']
    end
    line
  end

  def compute_occupation_category(rec, year)
    if %w[1841 1851 1861 1871 1881].include?(year)
      line = ''
    elsif /\(em'ee\)/i.match(rec['occupation'])
      line = 'e'
    elsif /\(em'er\)/i.match(rec['occupation'])
      line = 'r'
    elsif /\(Notem\)/i.match(rec['occupation'])
      line = 'n'
    end
    line
  end

  def compute_notes(rec)
    if rec['notes'].present? && rec['unoccupied_notes'].present?
      line = rec['notes'] == rec['unoccupied_notes']  ?  rec['notes'] : (rec['notes'] + rec['unoccupied_notes'])
    elsif rec['notes'].present? && rec['unoccupied_notes'].blank?
      line = rec['notes']
    elsif rec['unoccupied_notes'].present?
      line = rec['unoccupied_notes']
    else
      line = @blank
    end
    line
  end

  def compute_uninhabited_flag(rec)
    line = rec['uninhabited_flag'] == @dash ? @blank : rec['uninhabited_flag']
    line
  end

  def remove_whitespace
    self[:transcriber_name] = self[:transcriber_name].squeeze(' ').strip if self[:transcriber_name].present?
  end

# ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,upload

  def check_name(name)
    decision = false
    decision = true if uploaded_file_name == name
    decision
  end

  def clean_up
    file_location = File.join(Rails.application.config.vld_file_locations, dir_name, uploaded_file_name)
    File.delete(file_location) if File.file?(file_location)
  end

  def check_extension
    file_name_parts = uploaded_file_name.split('.')
    result = file_name_parts[1].present? && file_name_parts[1].casecmp('vld').zero? ? true : false
    result
  end

  def check_exists_on_upload
    file_location = File.join(Rails.application.config.vld_file_locations, dir_name, uploaded_file_name)
    result = File.file?(file_location) ? true : false
    result
  end

  def check_batch_upload
    files = Freecen1VldFile.where(:dir_name => dir_name, :file_name => uploaded_file_name, :action.ne => 'Upload').count
    result = files > 0 ? true : false
    result
  end

  def estimate_size
    place = File.join(Rails.application.config.vld_file_locations, dir_name, uploaded_file_name)
    size = File.size?(place)
    size
  end

  def process_the_batch
    size = estimate_size
    if size.blank? || size.present? && size < 100
      proceed = false
      message = 'The file either does not exist or is too small to be a valid file.'
      clean_up
      return [proceed, message]
    end
    logger.warn("FREECEN:VLD_PROCESSING: Starting rake task for #{userid} #{uploaded_file_name} in #{dir_name}")
    pid1 = spawn("rake freecen:process_freecen1_vld[#{ File.join(Rails.application.config.vld_file_locations, dir_name, uploaded_file_name)},#{userid}]")
    message = "The vld file #{uploaded_file_name} is being processed. You will receive an email when it has been completed."
    logger.warn("FREECEN:VLD_PROCESSING: rake task for #{pid1}")
    process = true
    [process, message]
  end

  def replace_chars_in_pob(place_of_birth)
    updated_place_of_birth = place_of_birth
    if updated_place_of_birth.present?
      has_char = false
      chars = ",.'"
      chars.each_char do |char|
        has_char = true if place_of_birth.include?(char)
        break if has_char
      end
      if has_char
        updated_place_of_birth = place_of_birth.tr(',.', ' ').squeeze(' ')
        updated_place_of_birth = updated_place_of_birth.tr("'", '')
        updated_place_of_birth = '-' if updated_place_of_birth == ' ' || updated_place_of_birth.blank?
      end
    end
    updated_place_of_birth
  end

  def setup_batch_on_upload
    file_location = File.join(Rails.application.config.vld_file_locations, dir_name, uploaded_file_name)
    if File.file?(file_location)
      delete_search_records
      delete_freecen1_vld_entries
      delete_dwellings
      delete_individuals
      save_to_attic
    end
    file = Freecen1VldFile.find_by(dir_name: dir_name, uploaded_file_name: uploaded_file_name)
    if file.present? && file.freecen_piece.present?
      piece = file.freecen_piece
      piece.update_attributes(num_dwellings: 0, num_individuals: 0, freecen1_filename: '', status: '') if piece.present?
      piece.freecen1_vld_files.delete(file) if piece.present?
      file.delete
    elsif file.present?
      piece = FreecenPiece.find_by(file_name: file.file_name)
      piece.update_attributes(num_dwellings: 0, num_individuals: 0, freecen1_filename: '', status: '') if piece.present?
      piece.freecen1_vld_files.delete(file) if piece.present?
      file.delete
    end
  end

  private

  def add_num_entries
    self.num_entries = freecen1_vld_entries.count
  end
end
