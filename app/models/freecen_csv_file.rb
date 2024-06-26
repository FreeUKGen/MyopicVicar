# Copyright 2012 Trustees of FreeBMD
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class FreecenCsvFile
  include Mongoid::Document
  include Mongoid::Timestamps
  require "#{Rails.root}/app/uploaders/csvfile_uploader"
  require 'record_type'
  require 'name_role'
  require 'chapman_code'
  require 'userid_role'
  require 'register_type'
  require 'freecen_constants'
  require 'freecen_validations'
  require 'csv'
  # Fields correspond to cells in CSV headers
  #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # These field are there in the entry collection from the original files coming in as CSV file.
  # They are NOT USED we use the county and country from the Place collection the church_name from the church collection
  # and the register information from the register collection
  field :action, type: String
  field :field_specification, type: Hash
  field :chapman_code, type: String
  field :characterset, type: String
  field :country, type: String
  field :county, type: String # note in headers this is actually a Chapman code
  field :digest, type: String
  field :total_errors, type: Integer, default: 0
  field :total_warnings, type: Integer, default: 0
  field :total_info, type: Integer, default: 0
  field :file_digest, type: String
  field :file_errors, type: Array
  field :file_name, type: String
  field :file_name_lower_case, type: String
  field :flexible, type: Boolean, default: true
  field :locked_by_coordinator, type: Boolean, default: false
  field :locked_by_transcriber, type: Boolean, default: false
  field :modification_date, type: String, default: -> {'01 Jan 1998'}
  field :processed, type: Boolean, default: true
  field :processed_date, type: DateTime
  field :search_record_version, type: String
  field :series, type: String
  field :software_version, type: String
  field :total_records, type: Integer
  field :transcriber_email, type: String
  field :transcriber_name, type: String
  field :transcriber_syndicate, type: String
  field :transcription_date, type: String, default: -> {'01 Jan 1998'}
  field :uploaded_date, type: DateTime
  field :userid, type: String
  field :userid_lower_case, type: String
  field :year, type: String
  field :traditional, type: Integer
  field :header_line, type: Array
  field :validation, type: Boolean, default: false
  field :was_locked, type: Boolean, default: false
  field :list_of_records, type: Hash # no longer used
  field :incorporated, type: Boolean, default: false
  field :incorporated_date, type: DateTime
  field :enumeration_districts, type: Hash
  field :incorporation_lock, type: Boolean, default: false
  field :total_dwellings, type: Integer
  field :total_individuals, type: Integer
  field :completes_piece, type: Boolean, default: false
  field :incorporating_lock, type: Boolean, default: false
  field :type_of_processing, type: String  # placeholder used by change_userid process


  before_save :add_lower_case_userid_to_file, :add_country_to_file, :add_lower_case_file_name_to_file
  before_create :set_completes_piece_flag
  #after_save :recalculate_last_amended, :update_number_of_files

  before_destroy do |file|
    file.save_to_attic
    FreecenCsvEntry.collection.delete_many(freecen_csv_file_id: file._id)
  end

  belongs_to :userid_detail, index: true, optional: true
  belongs_to :freecen2_place, index: true, optional: true
  belongs_to :freecen2_piece, index: true, optional: true
  belongs_to :freecen2_district, index: true, optional: true

  # register belongs to church which belongs to place

  has_many :freecen_csv_entries, validate: false, order: :id.asc


  VALID_DAY = /\A\d{1,2}\z/
  VALID_MONTH = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP","SEPT", "OCT", "NOV", "DEC", "*","JANUARY","FEBRUARY","MARCH","APRIL","MAY","JUNE","JULY","AUGUST","SEPTEMBER","OCTOBER","NOVEMBER","DECEMBER"]
  VALID_YEAR = /\A\d{4}\z/
  ANOTHER_VALID_YEAR = /\A\d{2}\z/
  MONTHS = {
    'Jan' => '01',
    'Feb' => '02',
    'Mar' => '03',
    'Apr' => '04',
    'May' => '05',
    'Jun' => '06',
    'Jul' => '07',
    'Aug' => '08',
    'Sep' => '09',
    'Oct' => '10',
    'Nov' => '11',
    'Dec' => '12'
  }


  ###################################################################### class methods
  class << self

    def chapman_code(name)
      #note chapman is county in file
      where(:chapman_code => name)
    end

    def year(year)
      where(year: year)
    end

    def incorporated(status)
      where(incorporated: status)
    end

    def coordinator_lock
      where(:locked_by_coordinator => true)
    end

    def county(name)
      where(:county => name)
    end

    def errors
      where(:total_errors.gt => 0)
    end

    def file_name(name)
      where(:file_name => name)
    end

    def id(id)
      where(:id => id)
    end

    def syndicate(name)
      where(:transcriber_syndicate => name)
    end

    def transcriber_lock
      where(:locked_by_transcriber => true)
    end

    def userid(name)
      where(:userid => name)
    end

    def convert_date(date_field)
      #use a custom date conversion to number of days for comparison purposes only
      #dates provided vary in format
      date_day = 0
      date_month = 0
      date_year = 0
      unless date_field.nil?
        a = date_field.split(" ")
        case
        when a.length == 3
          #work with dd mmm yyyy
          #firstly deal with the dd
          date_day = a[0].to_i if(a[0].to_s =~ VALID_DAY)
          #deal with the month
          date_month = MONTHS[a[1]].to_i if (VALID_MONTH.include?(Unicode::upcase(a[1])) )
          #deal with the yyyy
          if a[2].length == 4
            date_year = a[2].to_i if (a[2].to_s =~ VALID_YEAR)
          else
            date_year = a[2].to_i if (a[2].to_s =~ ANOTHER_VALID_YEAR)
            date_year = date_year + 2000
          end

        when a.length == 2
          #deal with dates that are mmm yyyy firstly the mmm then the year
          date_month if (VALID_MONTH.include?(Unicode::upcase(a[0])))
          date_year if (a[1].to_s =~ VALID_YEAR)

        when a.length == 1
          #deal with dates that are year only
          date_year if (a[0].to_s =~ VALID_YEAR)

        end
      end
      my_days = date_year.to_i*365 + date_month.to_i*30 + date_day.to_i
      my_days
    end

    def create_audit_record(action_type, csv_file, who, fc2_piece_id)
      @csv_audit = FreecenCsvFileAudit.new
      @csv_audit.add_fields(action_type, csv_file, who, fc2_piece_id)
      @csv_audit.save
    end

    def delete_file(file)
      file.save_to_attic
      #first the entries
      FreecenCsvFile.where(userid: file.userid, file_name: file.file_name).all.each do |f|
        FreecenCsvEntry.delete_entries_for_a_file(f._id)
        f.delete unless f.nil?
      end
    end

    def file_update_location(file, param, session)
      if session[:selectcountry].blank? || session[:selectcounty].blank? || session[:selectplace].blank? ||  session[:selectchurch].blank? || param.blank? || param[:register_type].blank?
        message = FreecenCsvFile.file_update_location_message(session)
        return [false, "You are missing a selection of #{message}"]
      end
      place = FreecenCsvFile.file_update_location_location_parameters(session, param[:register_type])
      FreecenCsvFile.file_update_location_remove_from_original_register(file)
      file = FreecenCsvFile.file_update_location_update_fields(file, param, session, place, church, selected_register)
      FreecenCsvFile.file_update_location_clean_up(file, place, church)
      [true, '']
    end

    def file_update_location_clean_up(file, place)
      place.update_attribute(:data_present, true) unless place.data_present
      place.recalculate_last_amended_date

      file.propogate_file_location_change(place.id)
      PlaceCache.refresh_cache(place)
      file.update_freereg_contents_after_processing
    end

    def file_update_location_location_parameters(session, register_type)
      place = Freecen2Place.id(session[:selectplace]).first
    end

    def file_update_location_message(session)
      message = ""
      message = message + ": country" if session[:selectcountry].blank?
      message = message + ": county" if session[:selectcounty].blank?
      message = message + ": place" if session[:selectplace].blank?
      message
    end

    def file_update_location_remove_from_original_register(file)
      register = file.register
      register.freereg1_csv_files.delete(file)
      file.update_attribute(:register_id, nil)
      file.reload
      register.calculate_register_numbers
      church = register.church
      church.registers.delete(register) if register.records.to_i == 0
      register.destroy if register.records.to_i == 0
    end

    def file_update_location_update_fields(file, param, session, place, church, selected_register)
      file.place = place.place_name
      file.place_name = place.place_name
      file.church_name = church.church_name
      file.register_type = param[:register_type]
      file.county = session[:selectcounty]
      file.country = session[:selectcountry]
      file.alternate_register_name = church.church_name.to_s + " " + param[:register_type].to_s
      file.register_id = selected_register.id
      if session[:my_own]
        file.locked_by_transcriber = true
      else
        file.locked_by_coordinator = true
      end
      file.save
      file
    end

    def valid_freecen_csv_file?(freecen_csv_file)
      result = false
      return result if freecen_csv_file.blank?

      freecen_csv_file = FreecenCsvFile.find(freecen_csv_file)
      result = true if freecen_csv_file.present? && freecen_csv_file.freecen2_piece_id.present?
      logger.warn("FREECEN:LOCATION:VALIDATION invalid freecen_csv_file #{freecen_csv_file} ") unless result
      result
    end

    def county_year_data_totals(chapman_code)
      totals_csv_files = {}
      totals_csv_files_incorporated = {}
      totals_individuals = {}
      totals_dwellings = {}
      totals_csv_entries = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        totals_dwellings[year] = 0
        totals_individuals[year] = 0
        totals_csv_entries[year] = 0
        FreecenCsvFile.chapman_code(chapman_code).year(year).hint('chapman_code_year_incorporated').each do |file|
          totals_csv_entries[year] += file.total_records if file.total_records.present?
          if file.incorporated(true)
            totals_dwellings[year] += file.total_dwellings if file.total_dwellings.present?
            totals_individuals[year] += file.total_individuals if file.total_individuals.present?
          end
        end
        totals_csv_files[year] = FreecenCsvFile.chapman_code(chapman_code).year(year).hint('chapman_code_year_incorporated').count
        totals_csv_files_incorporated[year] = FreecenCsvFile.chapman_code(chapman_code).year(year).incorporated(true).hint('chapman_code_year_incorporated').count
      end

      [totals_csv_files, totals_csv_files_incorporated, totals_csv_entries, totals_individuals, totals_dwellings]
    end

    def before_year_csv_files(chapman_code, year, time, select_recs)
      last_id = BSON::ObjectId.from_time(time)
      if year != 'all'
        if select_recs == 'all'
          @records = FreecenCsvFile.where(_id: { '$lte' => last_id }, chapman_code: chapman_code, year: year).hint('id_chapman_year_incorporated')
        else
          @records = FreecenCsvFile.where(_id: { '$lte' => last_id }, chapman_code: chapman_code, year: year, incorporated: true).hint('id_chapman_year_incorporated')
        end
      else
        if select_recs == 'all'
          @records = FreecenCsvFile.where(_id: { '$lte' => last_id }, chapman_code: chapman_code).hint('id_year_incorporated')
        else
          @records = FreecenCsvFile.where(_id: { '$lte' => last_id }, chapman_code: chapman_code, incorporated: true).hint('id_year_incorporated')
        end
      end
      @records
    end

    def before_year_totals(time)
      last_id = BSON::ObjectId.from_time(time)
      totals_csv_files = {}
      totals_csv_files_incorporated = {}
      totals_individuals = {}
      totals_dwellings = {}
      totals_csv_entries = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        totals_dwellings[year] = 0
        totals_individuals[year] = 0
        totals_csv_entries[year] = 0
        FreecenCsvFile.where(_id: { '$lte' => last_id }).year(year).hint('id_year_incorporated').each do |file|
          totals_csv_entries[year] += file.total_records if file.total_records.present?
          if file.incorporated == true
            totals_dwellings[year] += file.total_dwellings if file.total_dwellings.present?
            totals_individuals[year] += file.total_individuals if file.total_individuals.present?
          end
        end
        totals_csv_files[year] = FreecenCsvFile.where(_id: { '$lte' => last_id }).year(year).hint('id_year_incorporated').count
        totals_csv_files_incorporated[year] = FreecenCsvFile.where(_id: { '$lte' => last_id }).year(year).incorporated(true).hint('id_year_incorporated').count
      end
      [totals_csv_files, totals_csv_files_incorporated, totals_csv_entries, totals_individuals, totals_dwellings]
    end


    def before_county_year_totals(chapman_code, time)
      last_id = BSON::ObjectId.from_time(time)
      totals_csv_files = {}
      totals_csv_files_incorporated = {}
      totals_individuals = {}
      totals_dwellings = {}
      totals_csv_entries = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        totals_dwellings[year] = 0
        totals_individuals[year] = 0
        totals_csv_entries[year] = 0
        FreecenCsvFile.where(_id: { '$lte' => last_id }).chapman_code(chapman_code).year(year).hint('id_chapman_year_incorporated').each do |file|
          totals_csv_entries[year] += file.total_records if file.total_records.present?
          if file.incorporated == true
            totals_dwellings[year] += file.total_dwellings if file.total_dwellings.present?
            totals_individuals[year] += file.total_individuals if file.total_individuals.present?
          end
        end
        totals_csv_files[year] = FreecenCsvFile.where(_id: { '$lte' => last_id }).chapman_code(chapman_code).year(year).hint('id_chapman_year_incorporated').count
        totals_csv_files_incorporated[year] = FreecenCsvFile.where(_id: { '$lte' => last_id }).chapman_code(chapman_code).year(year).incorporated(true).hint('id_chapman_year_incorporated').count
      end
      [totals_csv_files, totals_csv_files_incorporated, totals_csv_entries, totals_individuals, totals_dwellings]
    end

    def between_dates_county_year_totals(chapman_code, time1, time2)
      last_id = BSON::ObjectId.from_time(time2)
      first_id = BSON::ObjectId.from_time(time1)
      totals_csv_files = {}
      totals_csv_files_incorporated = {}
      totals_individuals = {}
      totals_dwellings = {}
      totals_csv_entries = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        totals_dwellings[year] = 0
        totals_individuals[year] = 0
        totals_csv_entries[year] = 0
        FreecenCsvFile.chapman_code(chapman_code).year(year).hint('chapman_code_year_incorporated').each do |file|
          if file.id.between?(first_id, last_id)
            totals_csv_entries[year] += file.total_records if file.total_records.present?
          end
          if file.incorporated == true && file.incorporated_date.between?(time1, time2)
            totals_dwellings[year] += file.total_dwellings if file.total_dwellings.present?
            totals_individuals[year] += file.total_individuals if file.total_individuals.present?
          end
        end
        totals_csv_files[year] = FreecenCsvFile.chapman_code(chapman_code).year(year).between(_id: first_id..last_id).hint('id_chapman_year_incorporated').count
        totals_csv_files_incorporated[year] = FreecenCsvFile.chapman_code(chapman_code).year(year).incorporated(true).between(incorporated_date: time1..time2).hint('id_chapman_year_incorporated').count
      end
      [totals_csv_files, totals_csv_files_incorporated, totals_csv_entries, totals_individuals, totals_dwellings]
    end

    def between_dates_year_totals(time1, time2)
      last_id = BSON::ObjectId.from_time(time2)
      first_id = BSON::ObjectId.from_time(time1)
      totals_csv_files = {}
      totals_csv_files_incorporated = {}
      totals_individuals = {}
      totals_dwellings = {}
      totals_csv_entries = {}
      Freecen::CENSUS_YEARS_ARRAY.each do |year|
        totals_dwellings[year] = 0
        totals_individuals[year] = 0
        totals_csv_entries[year] = 0
        FreecenCsvFile.year(year).each do |file|
          if file.id.between?(first_id, last_id)
            totals_csv_entries[year] += file.total_records if file.total_records.present?
          end
          if file.incorporated == true && file.incorporated_date.between?(time1, time2)
            totals_dwellings[year] += file.total_dwellings if file.total_dwellings.present?
            totals_individuals[year] += file.total_individuals if file.total_individuals.present?
          end
        end
        totals_csv_files[year] = FreecenCsvFile.between(_id: first_id..last_id).year(year).hint('id_year_incorporated').count
        totals_csv_files_incorporated[year] = FreecenCsvFile.incorporated(true).year(year).between(incorporated_date: time1..time2).hint('id_year_incorporated').count
      end
      [totals_csv_files, totals_csv_files_incorporated, totals_csv_entries, totals_individuals, totals_dwellings]
    end

    def convert_freecen_csv_file_name_to_freecen1_vld_file_name(description)
      # Need to add Ireland
      remove_extension = description.split('.')
      parts = remove_extension[0].split('_')
      case parts[0].upcase
      when 'RG9'
        series = 'RG09'
      when 'RG10'
        series = 'RG10'
      when 'RG11'
        series = 'RG11'
      when 'RG12'
        series = 'RG12'
      when 'RG13'
        series = 'RG13'
      when 'RG14'
        series = 'RG14'
      when 'HO107'
        if parts[1].delete('^0-9').to_i <= 999
          series = 'HO107'
          parts[1] = '0' + parts[1] if parts[1].delete('^0-9').to_i >= 10 && parts[1].delete('^0-9').to_i <= 99
          parts[1] = '00' + parts[1] if parts[1].delete('^0-9').to_i >= 1 && parts[1].delete('^0-9').to_i <= 9
        elsif parts[1].delete('^0-9').to_i <= 1465
          series = 'HO41'
        elsif parts[1].delete('^0-9').to_i >= 1466
          series = 'HO51'
        end
      when 'HS41'
        series = 'HS4'
      when 'HS51'
        series = 'HS5'
      when 'RS6'
        series = 'RS6'
      when 'RS7'
        series = 'RS7'
      when 'RS8'
        series = 'RS8'
      when 'RS9'
        series = 'RS9'
      end
      vld = series.present? ? series + parts[1] + '.VLD' : ''
      vld = vld.upcase if vld.present?
      vld
    end

    def vld_file_exists(file_name)
      if file_name.present?
        vld = FreecenCsvFile.convert_freecen_csv_file_name_to_freecen1_vld_file_name(file_name)
        vld = vld.present? ? vld.downcase : vld
        result = Freecen1VldFile.find_by(file_name_lower_case: vld)
        return [true, 'There is a VLD file of that name that should be deleted first'] if result.present?
      end

      [false, '']
    end
  end # self
  # ######################################################################### instance methods

  def accept_warnings
    return [false, 'The file has been incorporated'] if incorporated

    return [false, 'The file has errors'] if total_errors > 0
    freecen_csv_entries.where(record_valid: 'false').each do |entry|
      entry.update_attributes(record_valid: 'true', warning_messages: nil)
      entry.reload
    end
    warnings = freecen_csv_entries.where(record_valid: 'false').count
    self.total_warnings = warnings
    save
    [true, '']

  end

  def add_country_to_file
    # rspec tested during  csv processing
    chapman = self.chapman_code
    ChapmanCode::CODES.each_pair do |key, value|
      if value.has_value?(chapman)
        country = key
        self.country = key
        return
      end
    end
  end

  def add_lower_case_userid_to_file
    # rspec tested directly
    self[:userid_lower_case] = self[:userid].downcase
  end

  def add_lower_case_file_name_to_file
    self[:file_name_lower_case] = self[:file_name].downcase
  end

  def is_whole_piece(piece)
    return true if piece.number.downcase + ".csv" == self.file_name.downcase
  end

  def set_completes_piece_flag
    unless self.freecen2_piece_id.blank?
      self.completes_piece = false
      piece = Freecen2Piece.find_by(_id: self.freecen2_piece_id)
      self.completes_piece = true if is_whole_piece(piece)
    end
  end

  def add_to_rake_delete_freecen_csv_file_list(action_userid)
    #respected as part of remove batch
    processing_file = Rails.root.join(Rails.application.config.delete_list)
    File.open(processing_file, 'a') do |f|
      f.write("#{self.id},#{self.userid},#{self.file_name}\n")
    end
    FreecenCsvFile.create_audit_record('Removed', self, action_userid,  self.freecen2_piece_id)
  end

  def are_we_changing_location?(param)
    change = false
    change = true unless param[:register_type] == self.register_type
    change = true unless param[:church_name] == self.church_name
    change = true unless param[:place] == self.place
    change
  end

  def augment_record_number_on_creation
    file_line_number = records.to_i + 1
    line_id = userid + '.' + file_name.upcase + '.' + file_line_number.to_s
    update_attributes(records: file_line_number)
    return file_line_number, line_id
  end

  def backup_file
    #this makes aback up copy of the file in the attic and creates a new one
    save_to_attic
    file_folder = File.join(Rails.application.config.datafiles, userid)
    file_location = File.join(Rails.application.config.datafiles, userid, file_name)
    success = false
    if File.exist?(file_folder)
      write_csv_file(file_location)
      success = true
    end
    success
  end

  def can_we_edit?
    result = PhysicalFile.userid(userid).file_name(file_name).waiting.blank? ? true : false
  end

  def can_we_unincorporate?
    return [false, 'Not incorporated'] unless incorporated

    [true, '']
  end

  def can_we_incorporate?
    return [false, 'Already incorporated'] if incorporated

    return [false, 'Has not been validated incorporated'] unless validation

    return [false, 'Cannot be incorporated as the file contains errors or warnings'] if includes_warnings_or_errors?

    return [false, 'Cannot be incorporated as there are No enumeration districts for the file, please reprocess before attempting to incorporate'] if enumeration_districts.blank?

    piece = Freecen2Piece.find_by(_id: freecen2_piece_id)
    return [false, 'Cannot be incorporated as the file does not belong to a Freecen2 Piece'] if piece.blank?

    place = piece.freecen2_place

    return [false, 'Cannot be incorporated as the file does not belong to a Freecen2 Place'] if place.blank?

    result, message = includes_existing_enumeration_districts(piece)
    return [false, "Cannot be incorporated as the file contains enumeration districts #{message}"] if result

    result, message = civil_parishes_have_freecen2_place
    return [false, "Cannot be incorporated as the file contains #{message}"] unless result

    result, message = FreecenCsvFile.vld_file_exists(file_name)
    return [false, "Cannot be incorporated. #{message}"] if result

    [true, '']
  end

  def can_we_unincorporate?
    # need to check is duplication
    if !incorporated
      message = 'File records are not in the database so cannot be removed'
      result = false
    elsif incorporation_lock
      message = 'Records are incorporated but the incorporated lock is set. You must remove before proceeding'
      result = false
    else
      message = 'Proceeding'
      result = true
    end
    [result, message]
  end

  def display_for_csv_show
    [_id, file_name, userid]
  end

  def civil_parishes_have_freecen2_place
    enumeration_districts.each_pair do |civil_parish, _districts|
      parish = Freecen2CivilParish.find_by(year: year, chapman_code: chapman_code, standard_name: Freecen2Place.standard_place(civil_parish))
      if parish.present?
        if parish.freecen2_place.present?
          return [true, '']
        else
          return [false, " a Civil Parish: #{civil_parish} that does not link to a Freecen2 Place"]
        end
      else
        return [false, "Missing Civil Parish: #{civil_parish}"]
      end
    end
  end

  def create_modern_header_file
    @chapman_code = chapman_code
    _year, _piece, census_fields = Freecen2Piece.extract_year_and_piece(file_name, @chapman_code)
    file_location = File.join(Rails.application.config.datafiles, userid, file_name)
    success, message = write_modern_csv_file(file_location, census_fields)
    [success, message, file_location, file_name]
  end

  def write_modern_csv_file(file_location, census_fields)
    header = census_fields
    @initial_line_hash = {}
    @blank = nil
    @dash = '-'
    census_fields.each do |field|
      @initial_line_hash[field] = nil
    end
    CSV.open(file_location, 'wb', row_sep: "\r\n") do |csv|
      csv << header
      records = freecen_csv_entries
      @record_number = 0
      records.each do |rec|
        # next if rec['deleted_flag'].present?

        @record_number += 1
        line = []
        line = add_csv_fields(line, rec, census_fields)
        csv << line
      end
    end
    [true, '']
  end

  def index_type(type)
    if type.blank?
      entries = freecen_csv_entries.all.order_by(record_number: 1)
    elsif type == 'Civ'
      entries = FreecenCsvEntry.where(freecen_csv_file_id: _id).in(data_transition: Freecen::LOCATION).all.order_by(record_number: 1)
    elsif type == 'Pag'
      entries = FreecenCsvEntry.where(freecen_csv_file_id: _id).in(data_transition: Freecen::LOCATION_PAGE).all.order_by(record_number: 1)
    elsif type == 'Dwe'
      entries = FreecenCsvEntry.where(freecen_csv_file_id: _id).in(data_transition: Freecen::LOCATION_DWELLING).all.order_by(record_number: 1)
    elsif type == 'Ind'
      entries = FreecenCsvEntry.where(freecen_csv_file_id: _id).all.order_by(record_number: 1)
    elsif type == 'Err'
      entries = FreecenCsvEntry.where(freecen_csv_file_id: _id).where(:error_messages.gte => 1).all.order_by(record_number: 1)
    elsif type == 'War'
      entries = FreecenCsvEntry.where(freecen_csv_file_id: _id).where(:warning_messages.gte => 1).all.order_by(record_number: 1)
    elsif type == 'Inf'
      entries = FreecenCsvEntry.where(freecen_csv_file_id: _id).where(:info_messages.gte => 1).all.order_by(record_number: 1)
    elsif type == 'Fla'
      entries = FreecenCsvEntry.where(freecen_csv_file_id: _id).where(flag: true).all.order_by(record_number: 1)
    end
    entries
  end

  def add_csv_fields(line, rec, census_fields)
    census_fields.each do |field|
      case field
      when 'enumeration_district'
        line << compute_enumeration_district(rec)
      when 'civil_parish'
        line << compute_civil_parish(rec)
      when 'ecclesiastical_parish'
        line << compute_ecclesiastical_parish(rec)
      when 'where_census_taken'
        line << compute_where_census_taken(rec)
      when 'folio_number'
        line << compute_folio_number(rec)
      when 'page_number'
        line << compute_page_number(rec)
      when 'schedule_number'
        line << compute_schedule_number(rec)
      when 'uninhabited_flag'
        line << compute_uninhabited_flag(rec)
      when 'house_number'
        line << compute_house_number(rec)
      when 'house_or_street_name'
        line << compute_house_or_street_name(rec)
      when 'surname'
        line << rec['surname']
      when 'forenames'
        line << rec['forenames']
      when 'relationship'
        line << rec['relationship']
      when 'marital_status'
        line << rec['marital_status']
      when 'sex'
        line << rec['sex']
      when 'age'
        line << rec.age
      when 'occupation'
        line << rec['occupation']
      when 'occupation_category'
        line << rec['occupation_category']
      when 'verbatim_birth_county'
        line << rec['verbatim_birth_county']
      when 'verbatim_birth_place'
        line << rec['verbatim_birth_place']
      when 'birth_county'
        line << @blank
      when 'birth_place'
        line << @blank
      when 'disability'
        line << rec['disability']
      when 'language'
        line << rec['language']
      when 'notes'
        line << remove_british(rec.notes)
      when 'nationality'
        line << check_for_british(rec.notes)
      when 'ward', 'parliamentary_constituency', 'poor_law_union', 'police_district', 'sanitary_district', 'special_water_district',
          'scavenging_district', 'special_lighting_district', 'school_board'
        entry = @use_blank ? @blank : @dash
        line << entry
      when 'walls', 'roof_type', 'rooms', 'rooms_with_windows', 'class_of_house', 'industry', 'at_home', 'years_married',
          'children_born_alive', 'children_living', 'children_deceased', 'disability_notes'
        line << @blank
      when 'location_flag'
        entry = rec.location_flag.presence || @blank
        line << entry
      when 'address_flag'
        entry = rec.address_flag.presence || @blank
        line << entry
      when 'name_flag'
        entry = rec.name_flag.presence || @blank
        line << entry
      when 'individual_flag'
        entry = rec.individual_flag.presence || @blank
        line << entry
      when 'occupation_flag'
        entry = rec.occupation_flag.presence || @blank
        line << entry
      when 'birth_place_flag'
        entry = rec.birth_place_flag.presence || @blank
        line << entry
      else
      end
    end
    line
  end

  def remove_british(notes)
    new_note = notes
    if notes.present? && notes.include?('British')
      new_note.slice! 'British'
      new_note.squish!
    end
    new_note
  end

  def check_for_british(notes)
    'British' if notes.present? && notes.include?('British')
  end

  def compute_enumeration_district(rec)
    if rec['enumeration_district'] == @initial_line_hash['enumeration_district']
      line = @blank
      @use_blank = true
    else
      line = rec['enumeration_district']
      @use_blank = false
      @initial_line_hash['enumeration_district'] = rec['enumeration_district']
    end
    line
  end

  def compute_civil_parish(rec)
    if @use_blank
      line = @blank
    else
      if rec['civil_parish'].blank?
        line = @dash
      else
        line = rec['civil_parish']
        @initial_line_hash['civil_parish'] = rec['civil_parish']
      end
    end
    line
  end

  def compute_ecclesiastical_parish(rec)
    if @use_blank
      line = @blank
    else
      if rec['ecclesiastical_parish'].blank?
        line = @dash
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
    else
      line = rec['page_number']
      @initial_line_hash['page_number'] = rec['page_number']
    end
    line
  end

  def compute_schedule_number(rec)
    if rec['schedule_number'].present? && rec['schedule_number'] == '0'
      line = rec['schedule_number']
      @use_schedule_blank = false
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

  def compute_house_number(rec)
    entry = @use_schedule_blank ? @blank : rec['house_number']
    line = entry
  end

  def compute_house_or_street_name(rec)
    entry = @use_schedule_blank ? @blank : rec['house_or_street_name']
    line = entry
  end

  def compute_uninhabited_flag(rec)
    entry = rec.uninhabited_flag.presence || @blank
    entry
  end

  def includes_existing_enumeration_districts(piece)
    @result = false
    @message = ''
    FreecenCsvFile.where(freecen2_piece_id: piece.id).all.each do |file|
      next unless file.incorporation_lock
      enumeration_districts.each_pair do |civil_parish, districts|
        if file.enumeration_districts.key?(civil_parish)
          districts.each do |district|
            @result = true if file.enumeration_districts[civil_parish].include?(district)
            @message += "#{civil_parish} with enumeration district #{district} already incorporated, "
          end
        end
      end
    end
    [@result, @message]
  end

  def includes_warnings_or_errors?
    result = total_errors.zero? && total_warnings.zero? ? false : true
    result
  end

  def change_owner_of_file(new_userid, type_of_processing)
    # rspec tested
    # first step is to move the files
    result = [true, '']
    new_userid_folder_location = physical_userid_location(new_userid)
    old_userid_folder_location = physical_userid_location(userid)
    unless Dir.exist?(new_userid_folder_location)
      Dir.mkdir(new_userid_folder_location, 0774)
    end
    new_physical_file_location = physical_file_location(new_userid, file_name)
    write_csv_file(new_physical_file_location)
    if result[0]
      physical_file = PhysicalFile.new(userid: new_userid, file_name: file_name, base: true, base_uploaded_date: Time.new)
      physical_file.save
      physical_file.add_file_change_of_owner('reprocessing',type_of_processing)
    end
    result
  end

  def check_batch
    success = []
    success[0] = true
    success[1] = ''
    batch = self
    case batch
    when nil?
      success[0] = false
      success[1] = success[1] + "batch #{batch} does not exist"
    when file_name.blank?
      success[0] = false
      success[1] = success[1] + "batch name is missing #{batch} "
    when userid.blank?
      success[0] = false
      success[1] = success[1] + "batch userid is missing #{batch} "
    when record_type.blank?
      success[0] = false
      success[1] = success[1] + "batch record type is missing #{batch} "
    when freecen1_csv_entries.count.zero?
      success[0] = false
      success[1] = success[1] + "batch has no entries #{batch} "
    when freecen2_piece.blank?
      success[0] = false
      success[1] = success[1] + "batch has a null freecen_piece #{batch} "
    when freecen2_piece.freecen2_place.blank?
      success[0] = false
      success[1] = success[1] + "batch has a null place #{batch} "
    end
    success
  end

  def check_file
    success = []
    success[0] = true
    success[1] = ''
    FreecenCsvFile.file_name(file_name).userid(userid).each do |batch|
      case batch
      when nil?
        success[0] = false
        success[1] = success[1] + "file #{batch.file_name} does not exist"
      when file_name.blank?
        success[0] = false
        success[1] = success[1] + "file name is missing #{batch.file_name} "
      when userid.blank?
        success[0] = false
        success[1] = success[1] + "userid is missing #{batch.file_name} "
      when freecen_csv_entries.count.zero?
        success[0] = false
        success[1] = success[1] + "file has no entries #{batch.file_name} "
      when freecen2_piece.blank?
        success[0] = false
        success[1] = success[1] + "file has a null piece #{batch.file_name} "
      when freecen2_piece.present? && freecen2_piece.freecen2_place.blank?
        success[0] = false
        success[1] = success[1] + "file has a null place #{batch.file_name} "
      end
    end
    success
  end

  def check_locking_and_set(_param, sess)
    if sess[:my_own]
      update(locked_by_transcriber: true)
    else
      update(locked_by_coordinator: true)
    end
  end

  def clean_up
    update_statistics
  end

  def update_statistics
    update_number_of_files
    piece_id = freecen2_piece
    if piece_id.blank?
      logger.warn("FREECEN:#{id} does not belong to a piece ")
      return
    elsif place == piece_id.freereg2_place
      if place.blank?
        logger.warn("FREECEN:#{piece_id.id} does not belong to a place ")
        return
      end
    else
      place.recalculate_last_amended_date
    end
  end

  def define_colour
    # need to consider storing the processed rather than a look up

    if !processed && total_errors.zero? && total_warnings.zero?
      color = 'color:black'
    elsif !processed && !total_errors.zero?
      color = 'color:red'
    elsif !processed && (locked_by_coordinator || locked_by_transcriber)
      color = 'color:voilet'
    elsif !processed && total_errors.zero? && !total_warnings.zero?
      color = 'color:brown'

    elsif total_errors.zero? && total_warnings.zero? && (locked_by_coordinator || locked_by_transcriber)
      color = 'color:blue'
    elsif total_errors.zero? && total_warnings.zero? && !locked_by_coordinator && !locked_by_transcriber
      color = 'color:green'
    else
      color = 'color:coral'
    end
    color
  end

  def determine_line_information(error_id)
    error_file = batch_errors.find(error_id)
    file_line_number = error_file.record_number if error_file.present?
    line_id = error_file.data_line[:line_id]
    [file_line_number, line_id]
  end

  def force_unlock
    batches = FreecenCsvFile.where(file_name: file_name, userid: userid).all
    batches.each do |batch|
      batch.update(locked_by_transcriber: false)
    end
  end

  def location_from_file
    my_piece = freecen2_piece
    my_place = my_piece.freereg2_place
    [my_place, my_piece]
  end

  def lock(type)
    batches = FreecenCsvFile.where(file_name: file_name, userid: userid).all
    set_transciber_lock = !locked_by_transcriber
    set_coordinator_lock = !locked_by_coordinator
    batches.each do |batch|
      if type
        # transcriber is changing their lock
        batch.update(locked_by_transcriber: set_transciber_lock)
      else
        # coordinator is changing locks
        batch.update(locked_by_coordinator: set_coordinator_lock)
        batch.update(locked_by_transcriber: false) unless set_coordinator_lock
      end
    end
  end

  def lock_all(type)
    batches = FreecenCsvFile.where(file_name: file_name, userid: userid).all
    batches.each do |batch|
      if type
        # transcriber is changing their lock
        batch.update(locked_by_transcriber: true)
      else
        # coordinator is changing locks
        batch.update(locked_by_coordinator: true)
      end
    end
  end

  def merge_batches
    batch_id = _id
    my_piece = freecen2_piece
    force_unlock
    added_records = 0
    my_piece.freecen_csv_files.each do |batch|
      if batch.userid == userid && batch.file_name == file_name
        unless batch._id == batch_id
          batch.freecen_csv_entries.each do |entry|
            added_records = added_records + 1
            entry.update(:freecen_csv_file_id, batch_id)
          end
          freecen2_piece.freecen_csv_files.delete(batch)
          batch.delete
        end
      end
    end
    # TODO need to recompute max, min and range
    unless added_records.zero?
      logger.info "FREECEN:update record count #{records.to_i} and #{added_records}"
      records = records.to_i + added_records
      update(records: records.to_s, locked_by_coordinator: true)
      logger.info "FREECEN:updated record count #{records.to_i} "
    end
    [true, '']
  end

  def next_dwelling(dwel)
    last_dwelling = FreecenCsvEntry.where(freecen_csv_file_id: id).order_by(dwelling_number: 1).last
    dwelling = dwel + 1 unless dwel == last_dwelling.dwelling_number
    dwelling
  end

  def physical_userid_location(userid)
    location = File.join(Rails.application.config.datafiles, userid)
  end

  def physical_file_location(userid, file_name)
    location = File.join(Rails.application.config.datafiles, userid, file_name)
  end

  def old_piece
    piece_id = freecen2_piece_id
    place_id = Freecen2Piece.find(piece_id).freecen2_place_id
  end

  def promulgate_userid_change(new_userid, old_userid)
    # since a file may have many batches we must change them all as we have moved the file
    new_userid_detail = UseridDetail.userid(new_userid).first
    FreecenCsvFile.userid(old_userid).file_name(file_name).each do |batch|
      success = FreecenCsvEntry.update_entries_userid(new_userid, batch)
      batch.update(userid: new_userid, userid_lower_case: new_userid.downcase, userid_detail_id: new_userid_detail.id) if success
    end
  end

  def recalculate_last_amended
    my_piece = freecen2_piece
    return if my_piece.blank?

    my_place = my_piece.freecen2_place
    return if my_place.blank?

    my_place.recalculate_last_amended_date
  end

  def save_to_attic
    # rspected with removal
    #Rails.logger.debug "Saving to attic"
    # to-do unix permissions
    file = file_name
    file_location = File.join(Rails.application.config.datafiles, userid, file)
    if File.file?(file_location)
      newdir = File.join(File.join(Rails.application.config.datafiles, userid), '.attic')
      Dir.mkdir(newdir) unless Dir.exist?(newdir)
      time = Time.now.to_i.to_s
      renamed_file = (file_location + '.' + time).to_s
      File.rename(file_location, renamed_file)
      FileUtils.mv(renamed_file, newdir, verbose: true)
      user = UseridDetail.where(userid: userid).first
      if user.present?
        attic_file = AtticFile.new(name: "#{file}.#{time}", date_created: DateTime.strptime(time, '%s'), userid_detail_id: user.id)
        attic_file.save
      end
    else
      Rails.logger.debug 'Nothing to save to attic'
    end
  end

  def remove_batch(action_userid)
    case
    when locked_by_transcriber || locked_by_coordinator
      [false, 'The removal of the batch was unsuccessful; the batch is locked']

    else
      # deal with file and its records
      add_to_rake_delete_freecen_csv_file_list(action_userid)
      save_to_attic
      delete
      # deal with the Physical Files collection
      PhysicalFile.delete_document(userid, file_name)
      [true, 'The removal of the batch entry was successful']
    end
  end

  def update_statistics_and_access(who_actioned)
    Rails.logger.debug 'update_statistics_and_access'
    self.locked_by_transcriber = true if who_actioned
    self.locked_by_coordinator = true unless who_actioned
    self.modification_date = Time.now.strftime("%d %b %Y")
    #recalculate_last_amended

    save
  end

  def update_number_of_files
    # this code although here and works produces values in fields that are no longer being used
    userid = UseridDetail.find_by(userid: userid)
    return if userid.blank?

    files = userid.freecen_csv_files
    if files.length.blank?
      number = 0
      records = 0
      last_uploaded = DateTime.new(1998, 1, 1)
    else
      number = files.length
      last_uploaded = DateTime.new(1998, 1, 1)
      records = 0
      files.each do |file|
        records = records + file.records.to_i
        last_uploaded = file.uploaded_date if last_uploaded.nil? || file.uploaded_date >= last_uploaded
      end
      userid.update(number_of_files: number, number_of_records: records, last_upload: last_uploaded)
    end
  end

  def update_messages_and_lock(original_warnings, original_errors, new_warnings, new_errors)
    original_number_errors = total_errors
    original_number_warnings = total_warnings
    if original_warnings == new_warnings
      new_number_warnings = original_number_warnings
    elsif new_warnings
      new_number_warnings = original_number_warnings + 1
    else
      new_number_warnings = original_number_warnings - 1
    end
    if original_errors == new_errors
      new_number_errors = original_number_errors
    elsif new_errors
      new_number_errors = original_number_errors + 1
    else
      new_number_errors = original_number_errors - 1
    end
    update_attributes(locked_by_transcriber: true, total_errors: new_number_errors, total_warnings: new_number_warnings)
  end

  def update_freecen_piece
    Freecen2Piece.update_or_create_piece(self)
  end

  def calculate_transcriber_name(key)
    if record_type == key && userid_detail.present? && (userid_detail.person_surname.present? || userid_detail.person_forename.present?)
      answer, transcriber =  UseridDetail.can_we_acknowledge_the_transcriber(userid_detail)
      transcriber = nil unless answer
    end
    transcriber
  end

  def write_csv_file(file_location)
    header = header_line
    header << 'record_valid' if validation && !header_line.include?('record_valid')
    header << 'pob_valid' if validation && !header_line.include?('pob_valid')
    header << 'non_pob_valid' if validation && !header_line.include?('non_pob_valid')
    CSV.open(file_location, 'wb', { row_sep: "\r\n" }) do |csv|
      csv << header
      records = freecen_csv_entries.order_by(_id: 1)
      records.each do |rec|
        line = []
        line = add_fields(line, rec)
        if validation
          pob_ok = pob_valid(rec)
          line << pob_ok
          line << non_pob_valid(pob_ok, rec)
        end
        csv << line
      end
    end
  end

  def write_spreadsheet_header(header)
    file_location = File.join(Rails.root, 'tmp', 'spreadersheet_header.csv')
    CSV.open(file_location, 'wb', { row_sep: "\r\n" }) do |csv|
      csv << header
    end
    file_location
  end

  def add_fields(line, rec)
    field_specification.values.each do |field|
      if Freecen::LOCATION.include?(rec[:data_transition])
        @entry = rec[field]
      elsif Freecen::LOCATION_FOLIO.include?(rec[:data_transition])
        @entry = Freecen::LOCATION.include?(field) ? nil : rec[field]
      elsif Freecen::LOCATION_PAGE.include?(rec[:data_transition])
        @entry = Freecen::LOCATION_FOLIO.include?(field) ? nil : rec[field]
      elsif Freecen::LOCATION_DWELLING.include?(rec[:data_transition])
        @entry = Freecen::LOCATION_PAGE.include?(field) ? nil : rec[field]
      else
        @entry = Freecen::LOCATION_DWELLING.include?(field) ? nil : rec[field]
      end
      line << @entry
    end
    if validation
      line << rec[:record_valid] if validation && !field_specification.value?('record_valid')
    end
    line
  end

  def set_total_dwellings
    if total_dwellings.blank?
      last_dwelling = FreecenCsvEntry.where(freecen_csv_file_id: id).order_by(dwelling_number: -1).first
      number_of_dwellings = last_dwelling.dwelling_number if last_dwelling.present?
      update_attributes(total_dwellings: number_of_dwellings)
    end
  end

  def set_total_individuals
    if total_individuals.blank?
      number_of_individuals = 0
      freecen_csv_entries.each do |entry|
        number_of_individuals += 1 if entry.sequence_in_household.present?
      end
      update_attributes(total_individuals: number_of_individuals)
    end
  end

  def pob_valid(rec)
    result = false
    if rec.record_valid == 'true'
      result = true
    else
      has_pob_warning = false
      warning_message_parts = rec.warning_messages.split('<br>')
      warning_message_parts.each do |part|
        has_pob_warning = true if part.include?('Warning:') && part.include?('Birth')
        break if has_pob_warning
      end
      result = true unless has_pob_warning
    end
    result
  end

  def non_pob_valid(pob_ok, rec)
    result = false
    if rec.record_valid == 'true'
      result = true
    elsif pob_ok == 'true'
      result = false
    else
      has_non_pob_warning = false
      warning_message_parts = rec.warning_messages.split('<br>')
      warning_message_parts.each do |part|
        has_non_pob_warning = true if part.include?('Warning:') && !part.include?('Birth') && !part.include?('Alternate')
        break if has_non_pob_warning
      end
      result = true unless has_non_pob_warning
    end
    result
  end
end
