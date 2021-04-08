class Freecen1VldFile
  include Mongoid::Document
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

  before_validation :add_num_entries, :remove_whitespace


  has_many :freecen1_vld_entries
  has_many :freecen_dwellings


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
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        total_files[year] = Freecen1VldFile.where(_id: { '$lte' => last_id }, full_year: year).count
        total_entries[year] = Freecen1VldFile.where(_id: { '$lte' => last_id }, full_year: year).sum(:num_entries)
      end
      [total_files, total_entries]
    end

    def between_dates_year_totals(time1, time2)
      last_id = BSON::ObjectId.from_time(time2)
      first_id = BSON::ObjectId.from_time(time1)
      total_files = {}
      total_entries = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        total_files[year] = Freecen1VldFile.between(_id: first_id..last_id).where(full_year: year).count
        total_entries[year] = Freecen1VldFile.between(_id: first_id..last_id).where(full_year: year).sum(:num_entries)
      end
      [total_files, total_entries]
    end

    def before_county_year_totals(chapman, time)
      last_id = BSON::ObjectId.from_time(time)
      total_files = {}
      total_entries = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        total_files[year] = Freecen1VldFile.where(_id: { '$lte' => last_id }, dir_name: chapman, full_year: year).count
        total_entries[year] = Freecen1VldFile.where(_id: { '$lte' => last_id }, dir_name: chapman, full_year: year).sum(:num_entries)
      end
      [total_files, total_entries]
    end

    def between_dates_county_year_totals(chapman, time1, time2)
      last_id = BSON::ObjectId.from_time(time2)
      first_id = BSON::ObjectId.from_time(time1)
      total_files = {}
      total_entries = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        total_files[year] = Freecen1VldFile.between(_id: first_id..last_id).where(dir_name: chapman, full_year: year).count
        total_entries[year] = Freecen1VldFile.between(_id: first_id..last_id).where(dir_name: chapman, full_year: year).sum(:num_entries)
      end
      [total_files, total_entries]
    end
  end
  # ######################################################################### instance methods

  def chapman_code
    dir_name.sub(/-.*/, '')
  end

  def create_csv_file
    #this makes aback up copy of the file in the attic and creates a new one
    @chapman_code = chapman_code
    year, piece, series = FreecenPiece.extract_year_and_piece(file_name)
    success, message, file, census_fields = convert_file_name_to_csv(year, piece, series)
    if success
      file_location = Rails.root.join('tmp', file)
      success, message = write_csv_file(file_location, census_fields, year)
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
      message = 'Scotland Code not checked'
      case year
      when '1841'
        file = 'RS41' + '_' + piece.to_s + '.csv'
        census_fields = Freecen::CEN2_SCT_1861
      when '1851'
        file = 'RS51' + '_' + piece.to_s + '.csv'
        census_fields = Freecen::CEN2_SCT_1871
      when '1861'
        file = 'RS61' + '_' + piece.to_s + '.csv'
        census_fields = Freecen::CEN2_SCT_1861
      when '1871'
        file = 'RS71' + '_' + piece.to_s + '.csv'
        census_fields = Freecen::CEN2_SCT_1871
      when '1881'
        file = 'RS81' + '_' + piece.to_s + '.csv'
        census_fields = Freecen::CEN2_SCT_1881
      when '1891'
        file = 'RS91' + '_' + piece.to_s + '.csv'
        census_fields = Freecen::CEN2_SCT_1891
      when '1901'
        file = 'RS' + '_' + piece.to_s + '.csv'
        census_fields = Freecen::CEN2_SCT_1901
      when '1911'
        file = 'RS' + '_' + piece.to_s + '.csv'
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

  def write_csv_file(file_location, census_fields, year)
    header = census_fields
    @initial_line_hash = {}
    @blank = nil
    @dash = '-'
    census_fields.each do |field|
      @initial_line_hash[field] = nil
    end
    CSV.open(file_location, 'wb', { row_sep: "\r\n" }) do |csv|
      csv << header
      records = freecen1_vld_entries
      @record_number = 0
      records.each do |rec|
        next if rec.blank?

        next if rec['deleted_flag'].present?

        @record_number += 1
        line = add_fields(rec, census_fields, year)
        csv << line
      end
    end
    [true, '']
  end

  def add_fields(rec, census_fields, year)
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
        line << compute_schedule_number(rec, census_fields)
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
        line << rec['verbatim_birth_place']
      when 'birth_county'
        county, place = compute_alternate(rec)
        line << county
        line << place
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
      when 'walls', 'roof_type', 'rooms', 'rooms_with_windows', 'class_of_house', 'rooms_with_windows', 'industry', 'at_home', 'years_married',
          'children_born_alive', 'children_living', 'children_deceased', 'nationality', 'disability_notes'
        line << @blank
      else
      end
    end
    line
  end

  def compute_alternate(rec)
    if rec['birth_county'] == rec['verbatim_birth_county'] && rec['birth_place'] == rec['verbatim_birth_place']
      county = @blank
      place = @blank
    else
      county = rec['birth_county'].present? && rec['birth_county'].downcase == 'wal' ? 'WLS' : rec['birth_county']
      place =  rec['birth_place']
    end
    [county, place]
  end

  def verbatim_birth_county(rec)
    county = rec['verbatim_birth_county'].present? && rec['verbatim_birth_county'].downcase == 'wal' ? 'WLS' : rec['verbatim_birth_county']
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
    if special_enumeration_district?(@initial_line_hash['enumeration_district'])
      line = rec['page_number']
      @initial_line_hash['page_number'] = rec['page_number']
    elsif rec['page_number'].present? && rec['page_number'] == @initial_line_hash['page_number']
      line = @blank
    else
      line = rec['page_number']
      @initial_line_hash['page_number'] = rec['page_number']
    end
    line
  end

  def compute_schedule_number(rec, census_fields)
    if %w[b n u v].include?(rec['uninhabited_flag']) || !census_fields.include?('ecclesiastical_parish')
      line = '0'
    elsif rec['sequence_in_household'] == 1 && rec['schedule_number'] == '0'
      line = '0'
      @use_schedule_blank = false
      @initial_line_hash['schedule_number'] = '0'
    elsif rec['uninhabited_flag'] == 'x' && rec['schedule_number'].present?
      line = rec['schedule_number']
      @use_schedule_blank = false
      @initial_line_hash['schedule_number'] = rec['schedule_number']
    elsif rec['uninhabited_flag'] == 'x' && rec['schedule_number'].blank?
      line = '0'
      @use_schedule_blank = false
      @initial_line_hash['schedule_number'] = '0'
    elsif special_enumeration_district?(@initial_line_hash['enumeration_district'])
      line = rec['schedule_number']
      @use_schedule_blank = false
      @initial_line_hash['schedule_number'] = rec['schedule_number']
    elsif rec['schedule_number'].present? && (rec['schedule_number'] == @initial_line_hash['schedule_number'])
      line = @blank
      @use_schedule_blank = true
    else
      line = rec['schedule_number']
      @use_schedule_blank = false
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
    if rec['unoccupied_notes'].blank?
      line = rec['notes']
    elsif rec['notes'].present?
      line = (rec['notes'] + rec['unoccupied_notes']) unless rec['notes'] == rec['unoccupied_notes']
    else
      line = rec['notes']
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

  private

  def add_num_entries
    self.num_entries = freecen1_vld_entries.count
  end
end
