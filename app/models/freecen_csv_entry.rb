# Copyright 2012 Trustees of FreeBMD
#
# Licensed under the Apache License, String\n  key Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, String\n  key software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, String\n  key either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
class FreecenCsvEntry
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  include Mongoid::Attributes::Dynamic
  require 'freecen_validations'
  require 'record_type'
  require 'freecen_constants'
  require 'chapman_code'


  validate :errors_in_fields

  belongs_to :freecen_csv_file, index: true, optional: true

  embeds_many :multiple_witnesses, cascade_callbacks: true
  embeds_many :embargo_records
  has_one :search_record, dependent: :restrict_with_error

  before_save :add_digest, :captitalize_surnames, :check_register_type

  before_destroy do |entry|
    SearchRecord.destroy_all(:freecen_csv_entry_id => entry._id)
  end


  index({ freecen_csv_file_id: 1, year: 1 }, { name: 'freecen_csv_file_id_year' })
  index({freecen_csv_file_id: 1,file_line_number:1})
  index({freecen_csv_file_id: 1, record_digest:1})

  class << self
    def id(id)
      where(id: id)
    end

    def freecen_csv_file(id)
      where(freecen_csv_file_id: id)
    end

    def year(year)
      where(year: year)
    end

    def compare_baptism_fields?(one, two)
      # used in  task check_record_digest
      fields = FreeregOptionsConstants::ORIGINAL_BAPTISM_FIELDS + FreeregOptionsConstants::ADDITIONAL_BAPTISM_FIELDS + FreeregOptionsConstants::ORIGINAL_COMMON_FIELDS + FreeregOptionsConstants::ADDITIONAL_COMMON_FIELDS
      equal = true
      fields.each do |field|
        one[field.to_sym] == two[field.to_sym] && equal ? equal = true : equal = false
      end
      equal
    end

    def compare_marriage_fields?(one, two)
      # used in  task check_record_digest
      fields = FreeregOptionsConstants::ORIGINAL_MARRIAGE_FIELDS + FreeregOptionsConstants::ADDITIONAL_MARRIAGE_FIELDS + FreeregOptionsConstants::ORIGINAL_COMMON_FIELDS + FreeregOptionsConstants::ADDITIONAL_COMMON_FIELDS
      equal = true
      fields.each do |field|
        one[field.to_sym] == two[field.to_sym] && equal ? equal = true : equal = false
      end
      equal
    end

    def compare_burial_fields?(one, two)
      # used in  task check_record_digest
      fields = FreeregOptionsConstants::ORIGINAL_BURIAL_FIELDS + FreeregOptionsConstants::ADDITIONAL_BURIAL_FIELDS + FreeregOptionsConstants::ORIGINAL_COMMON_FIELDS + FreeregOptionsConstants::ADDITIONAL_COMMON_FIELDS
      equal = true
      fields.each do |field|
        one[field.to_sym] == two[field.to_sym] && equal ? equal = true : equal = false
      end
      equal
    end

    def delete_entries_for_a_file(fileid)
      entries = FreecenCsvEntry.where(freecen_csv_file_id: fileid).all.no_timeout
      entries.destroy_all
    end

    def calculate_dwelling_digest(record)
      string = 'dwelling' + record[:schedule_number] if record[:schedule_number].present?
      string = string + record[:house_number]  if record[:house_number].present?
      string = string + record[:house_or_street_name] if record[:house_or_street_name].present?
      the_digest = calculate_digest(string)
    end

    def calculate_individual_digest(record)
      string = 'individual' + record[:surname] if record[:surname].present?
      string = string  + record[:forenames] if record[:forenames].present?
      string = string  + record[:sex] if record[:sex].present?
      string = string  + record[:marital_status] if record[:marital_status].present?
      string = string  + record[:age] if record[:age].present?
      string = string  + record[:occupation] if record[:occupation].present?

      the_digest = calculate_digest(string)
    end

    def calculate_digest(string)
      md5 = OpenSSL::Digest::MD5.new
      the_digest = hex_to_base64_digest(md5.hexdigest(string)) unless string.blank?
    end

    def hex_to_base64_digest(hexdigest)
      [[hexdigest].pack("H*")].pack("m").strip
    end

    def update_parameters(params, entry)
      #clean up old null entries
      params = params.delete_if { |k, v| v == '' }
      return params
    end

    def valid_freecen_csv_entry?(freecen_csv_entry)
      result = false
      return result if freecen_csv_entry.blank?

      freecen_csv_entry_object = FreecenCsvEntry.find(freecen_csv_entry)
      result = true if freecen_csv_entry_object.present? && FreecenCsvFile.valid_freecen_csv_file?(freecen_csv_entry_object.freecen_csv_file_id)
      logger.warn("FREEREG:LOCATION:VALIDATION invalid freecen_csv_entry id #{freecen_csv_entry}.<br> ") unless result
      result
    end

    def validate_civil_parish(record, previous_civil_parish)
      # p 'civil_parish change validate'
      # p previous_civil_parish

      civil_parish = record[:civil_parish]
      # p civil_parish
      flexible = record[:flexible]
      num = record[:record_number]
      info_messages = record[:info_messages]
      result = true
      new_civil_parish = civil_parish
      if flexible
        # p 'flexible not coded'
      else
        success, messagea = FreecenValidations.fixed_valid_civil_parish?(civil_parish)
        unless success
          result = false
          message = message + "ERROR: line #{num} Civil Parish has too many characters #{civil_parish}.<br>" if messagea == 'field length'
          message = message + "ERROR: line #{num} Civil Parish is blank.<br> " if messagea == 'blank'
          message = message + "ERROR: line #{num} Civil Parish has invalid text #{civil_parish}.<br>" if messagea == 'VALID_TEXT'
          new_civil_parish = previous_civil_parish
          return [result, message, new_civil_parish]
        end
      end
      valid = false
      record[:piece].subplaces.each do |subplace|
        valid = true if subplace[:name].to_s.downcase == civil_parish.to_s.downcase
        break if valid
      end
      if previous_civil_parish == ''
        message = "Warning: line #{num} New Civil Parish #{civil_parish}.<br>"
        result = true
      elsif previous_civil_parish == civil_parish
        result = true
      elsif !valid
        message = "ERROR: line #{num} Civil Parish has changed to #{civil_parish} which is not in the list of subplaces.<br>"
        result = false
      elsif valid
        message = "Warning: line #{num} Civil Parish has changed to #{civil_parish}.<br>"
        result = false
      else
        message = "ERROR: line #{num} Civil Parish has changed to #{civil_parish} but failed all tests.<br>"
        result = false
      end
      [result, message, new_civil_parish]
    end

    def validate_enumeration_district(record, previous_enumeration_district)
      # p 'validate_enumeration_district'
      # p previous_enumeration_district

      enumeration_district = record[:enumeration_district]
      # p enumeration_district
      flexible = record[:flexible]
      num = record[:record_number]
      info_messages = record[:info_messages]
      result = true
      new_enumeration_district = previous_enumeration_district
      if flexible
        # p 'flexible not coded'
      else
        success, messagea = FreecenValidations.fixed_enumeration_district?(enumeration_district)
        unless success
          result = false
          new_enumeration_district = previous_enumeration_district
          message = message + "ERROR: line #{num} Enumeration District #{enumeration_district} is #{messagea}.<br>"
          return [result, message, new_enumeration_district]
        end
      end
      parts = ''
      parts = enumeration_district.split('#') if enumeration_district.present?
      # p parts
      special = parts.length > 0 ? parts[1] : nil
      if previous_enumeration_district == ''
        message = "Info: line #{num} New Enumeration District #{enumeration_district}.<br>" if info_messages
        new_enumeration_district = enumeration_district
        result = true
      elsif previous_enumeration_district == enumeration_district
        result = true
      else
        message = "Warning: line #{num} Enumeration District changed to #{enumeration_district}.<br>" if special.blank? && enumeration_district.present?
        message = "Info: line #{num} Enumeration District changed to blank.<br>" if special.blank? && enumeration_district.blank? && info_messages
        message = "Info: line #{num} Enumeration District changed to #{Freecen::SpecialEnumerationDistricts::CODES[special.to_i]}.<br>" if special.present? && info_messages

        new_enumeration_district = enumeration_district
        new_folio_number, new_folio_suffix = suffix_extract(record[:folio_number])
        new_page_number = record[:page_number]
        new_schedule_number, new_schedule_suffix = suffix_extract(record[:schedule_number])
        result = false
      end
      [result, message, new_enumeration_district, new_folio_number, new_folio_suffix, new_page_number, new_schedule_number, new_schedule_suffix]
    end

    def suffix_present?(field)
      (/\D/ =~ field.slice(-1, 1)).present?
    end

    def suffix_extract(field)
      if field.blank?
        stem = field
        suffix = nil
      elsif suffix_present?(field)
        suffix = field.slice(-1, 1)
        stem = field.slice(0..-2)
      else
        stem = field
        suffix = nil
      end
      [stem, suffix]
    end

    def validate_folio(record, previous_folio_number, previous_folio_suffix)
      # p 'validate_folio'
      folio_number, folio_suffix = suffix_extract(record[:folio_number])
      page_number = record[:page_number]
      flexible = record[:flexible]
      num = record[:record_number]
      transition = record[:data_transition]
      info_messages = record[:info_messages]
      year = record[:year]
      # p previous_folio_number
      # p previous_folio_suffix
      # p folio_number
      # p folio_suffix
      result = true
      new_folio_number = previous_folio_number
      new_folio_suffix = previous_folio_suffix
      if flexible
        p 'flexible not coded'
      else
        message = "\r\n"
        success, messagea = FreecenValidations.fixed_folio_number?(record[:folio_number])
        unless success
          result = false
          message = message + "ERROR: line #{num} Folio number #{record[:folio_number]} is #{messagea}.<br>"
          return [result, message, new_folio_number, new_folio_suffix]
        end
      end
      if previous_folio_number == 0
        message = "Info: line #{num} Initial Folio number set to #{folio_number}.<br>" if info_messages
        new_folio_number = folio_number.to_i
        new_folio_suffix = folio_suffix
        result = true
      elsif  folio_number.blank? && ['Folio', 'Page'].include?(transition)
        message = ''
        result = false
      elsif  folio_number.blank? && year == '1841' && page_number.to_i.even?
        message = "Warning: line #{num} New Folio number is blank.<br>"
        result = false
      elsif folio_number.blank? && year != '1841' && page_number.to_i.odd?
        message = "Warning: line #{num} New Folio number is blank.<br>"
        result = false
      elsif folio_number.blank?
        result = true
      elsif previous_folio_number.present? && (folio_number.to_i > (previous_folio_number.to_i + 1))
        message = "Warning: line #{num} New Folio number increment larger than 1 #{folio_number}.<br>"
        new_folio_number = folio_number.to_i
        new_folio_suffix = folio_suffix
        result = true
      elsif folio_number.to_i == previous_folio_number.to_i
        message = "Warning: line #{num} New Folio number is the same as the previous number #{folio_number}.<br>"
        result = false
      elsif previous_folio_number.present? && (folio_number.to_i < previous_folio_number.to_i)
        message = "Warning: line #{num} New Folio number is less than the previous number #{folio_number}.<br>"
        new_folio_number = folio_number.to_i
        new_folio_suffix = folio_suffix
        result = true
      else
        message = "Info: line #{num} New Folio number #{folio_number}.<br>" if info_messages
        new_folio_number = folio_number
        new_folio_suffix = folio_suffix
        result = true
      end
      [result, message, new_folio_number, new_folio_suffix]
    end

    def validate_page(record, previous_page_number)
      # p 'validate_page'
      page_number = record[:page_number]
      flexible = record[:flexible]
      num = record[:record_number]
      transition = record[:data_transition]
      info_messages = record[:info_messages]
      # p previous_page_number
      # p page_number
      result = true
      new_page_number = previous_page_number
      if flexible
        p 'flexible not coded'
      else
        success, messagea = FreecenValidations.fixed_page_number?(page_number)
        unless success
          result = false
          new_page_number = previous_page_number
          message = message + "ERROR: line #{num} Page number #{page_number} is #{messagea}.<br>"
          return [result, message, new_page_number]
        end
      end
      if previous_page_number == 0
        message = "Info: line #{num} Initial Page number set to #{page_number}.<br>" if info_messages
        new_page_number = page_number.to_i
        result = true
      elsif  page_number.blank? && ['Folio', 'Page'].include?(transition)
        message = ''
        result = true
      elsif  page_number.blank?
        message = "Warning: line #{num} New Page number is blank.<br>"
        result = false
      elsif page_number.to_i > previous_page_number + 1
        message = "Warning: line #{num} New Page number increment larger than 1 #{page_number}.<br>"
        new_page_number = page_number.to_i
        result = true
      elsif page_number.to_i == previous_page_number
        message = "Warning: line #{num} New Page number is the same as the previous number #{page_number}.<br>"
        result = false
      elsif page_number.to_i < previous_page_number && page_number.to_i != 1
        message = "Warning: line #{num} New Page number is less than the previous number #{page_number}.<br>"
        new_page_number = page_number.to_i
        result = false
      elsif page_number.to_i < previous_page_number && page_number.to_i == 1
        message = "Info: line #{num} reset Page number to 1.<br>" if info_messages
        new_page_number = 1
        result = true
      else
        message = "Info: line #{num} New Page number #{page_number}.<br>" if info_messages
        new_page_number = page_number.to_i
        result = true
      end
      [result, message, new_page_number]
    end

    def validate_dwelling(record, previous_schedule_number, previous_schedule_suffix)
      # p 'validate_dwelling'
      schedule_number, schedule_suffix = suffix_extract(record[:schedule_number])
      house_number = record[:house_number]
      transition = record[:data_transition]
      uncertainy_location = record[:uncertainy_location]
      # p previous_schedule_number
      # p previous_schedule_suffix
      # p schedule_number
      # p schedule_suffix
      flexible = record[:flexible]
      num = record[:record_number]
      info_messages = record[:info_messages]
      overall_result = true
      new_schedule_number = schedule_number
      new_schedule_suffix = schedule_suffix
      if flexible
        # new code tests
        p 'flexible not coded'
        message = 'mine<br>'
      else
        message = ''
        success, messagea = FreecenValidations.fixed_schedule_number?(record[:schedule_number])
        if !success
          new_schedule_number = previous_schedule_number
          new_schedule_suffix = previous_schedule_suffix
          if messagea == 'blank' && ['Civil Parish', 'Enumeration District', 'Folio', 'Page'].include?(transition) && house_number.blank?
            message = "Info: line #{num} Schedule number retained at #{new_schedule_number}.<br>" if info_messages
            result = true
          elsif messagea == 'blank'
            result = false
            message = message + "ERROR: line #{num} Schedule number is blank and not a page transition.<br>"
          else
            result = false
            message = message + "ERROR: line #{num} Schedule number #{record[:schedule_number]} is #{messagea}.<br>"
          end
        elsif schedule_number.to_i > (previous_schedule_number.to_i + 1)
          message = "Warning: line #{num} Schedule number #{record[:schedule_number]} increments more than 1 .<br>"
        elsif schedule_number.to_i < previous_schedule_number.to_i
          new_schedule_number = previous_schedule_number if ['b', 'n', 'u', 'v'].include?(uncertainy_location)
          new_schedule_suffix = previous_schedule_suffix if ['b', 'n', 'u', 'v'].include?(uncertainy_location)
          message = "Warning: line #{num} Schedule number #{record[:schedule_number]} is less than the previous one .<br>" unless ['u', 'v'].include?(uncertainy_location)
        end

        overall_result = false if result == false

        success, messagea = FreecenValidations.fixed_house_number?(house_number)
        if !success
          result = false
          message = message + "ERROR: line #{num} House number #{house_number} is #{messagea}.<br>"
        end
        overall_result = false if result == false

        success, messagea = FreecenValidations.fixed_house_address?(record[:house_or_street_name])
        unless success
          result = false
          if messagea == '?'
            message = message + "Warning: line #{num} House address #{record[:house_or_street_name]}  has trailing ?. Removed and flag set.<br>"
            record[:uncertainy_location] = 'x' unless ['b', 'n', 'u', 'v'].include?(uncertainy_location)
            record[:house_or_street_name] = record[:house_or_street_name][0...-1]
          elsif messagea == 'blank'
            result = true
          else
            result = false
            message = message + "ERROR: line #{num} House address #{record[:house_or_street_name]} is #{messagea}.<br>"
          end
        end
        overall_result = false if result == false

        success, messagea = FreecenValidations.fixed_uncertainy_location?(uncertainy_location)
        unless success
          result = false
          message = message + "ERROR: line #{num} Special use #{uncertainy_location} is #{messagea}.<br>"
        else
          if ['u', 'v'].include?(uncertainy_location) && schedule_number.blank?
            message = message + "Warning: line #{num} has special #{uncertainy_location} but no schedule number.<br>"
          end
        end
      end
      overall_result = false if result == false
      [overall_result, message, new_schedule_number, new_schedule_suffix]
    end

    def validate_individual(record)
      # p 'validate_individual'
      flexible = record[:flexible]
      num = record[:record_number]
      info_messages = record[:info_messages]
      result = true

      return [true, ''] if ['b', 'n', 'u', 'v'].include?(record[:uncertainy_location])
      if flexible
        # new code tests
        p 'flexible not coded'
        message = 'mine'
      else
        message = ''
        success, messagea = FreecenValidations.fixed_surname?(record[:surname])
        unless success
          result = false
          if messagea == '?'
            message = message + "Warning: line #{num} Surname  #{record[:surname]} has trailing ?. Removed and flag set.<br>"
            record[:uncertainty_name] = 'x'
            record[:surname] = record[:surname][0...-1]
          else
            message = message + "ERROR: line #{num} Surname #{record[:surname]} is #{messagea}.<br>"
          end
        end
        success, messagea = FreecenValidations.fixed_forenames?(record[:forenames])
        unless success
          result = false
          if messagea == '?'
            message = message + "Warning: line #{num} Forenames  #{record[:forenames]} has trailing ?. Removed and flag set.<br>"
            record[:uncertainty_name] = 'x'
            record[:forenames] = record[:forenames][0...-1]
          else
            message = message + "ERROR: line #{num} Forenames #{record[:forenames]} is #{messagea}.<br>"
          end
        end
        success, messagea = FreecenValidations.fixed_name_question?(record[:uncertainty_name])
        unless success
          result = false
          message = message + "ERROR: line #{num} Uncertainty #{record[:uncertainty_name]} is #{messagea}.<br>"
        end
        success, messagea = FreecenValidations.fixed_relationship?(record[:relationship])
        unless success
          result = false
          message = message + "ERROR: line #{num} Relationship #{record[:relationship]} is #{messagea}.<br>"
        end
        success, messagea = FreecenValidations.fixed_marital_status?(record[:marital_status])
        unless success
          result = false
          message = message + "ERROR: line #{num} Marital status #{record[:marital_status]} is #{messagea}.<br>"
        end
        success, messagea = FreecenValidations.fixed_sex?(record[:sex])
        unless success
          result = false
          message = message + "ERROR: line #{num} Sex #{record[:sex]} is #{messagea}.<br>"
        end
        success, messagea = FreecenValidations.fixed_age?(record[:age], record[:marital_status], record[:sex])
        unless success
          result = false
          message = message + "ERROR: line #{num} Age #{record[:age]} is #{messagea}.<br>"
        end
        success, messagea = FreecenValidations.fixed_uncertainty_status?(record[:uncertainty_status])
        unless success
          result = false
          message = message + "ERROR: line #{num} Query #{record[:uncertainty_status]} is #{messagea}.<br>"
        end
        success, messagea = FreecenValidations.fixed_occupation?(record[:occupation], record[:age])
        unless success
          result = false
          if messagea == '?'
            message = message + "Warning: line #{num} Occupation #{record[:occupation]} has trailing ?. Removed and flag set.<br>"
            record[:uncertainty_occupation] = 'x'
            record[:occupation] = record[:occupation][0...-1]
          else
            message = message + "ERROR: line #{num} Occupation #{record[:occupation]} is #{messagea}.<br>"
          end
        end
        success, messagea = FreecenValidations.fixed_occupation_category?(record[:occupation_category])
        unless success
          result = false
          message = message + "ERROR: line #{num} Occupation category #{record[:occupation_category]} is #{messagea}.<br>"
        end
        success, messagea = FreecenValidations.fixed_uncertainty_occupation?(record[:uncertainty_occupation])
        unless success
          result = false
          message = message + "ERROR: line #{num} Occupation uncertainty #{record[:uncertainty_occupation]} is #{messagea}.<br>"
        end
        success, messagea = FreecenValidations.fixed_verbatim_birth_county?(record[:verbatim_birth_county])
        unless success
          result = false
          message = message + "ERROR: line #{num} Birth County #{record[:verbatim_birth_county]} is #{messagea}.<br>"
        end
        success, messagea = FreecenValidations.fixed_verbatim_birth_place?(record[:verbatim_birth_place])
        unless success
          result = false
          message = message + "ERROR: line #{num} Birth Place #{record[:verbatim_birth_place]} is #{messagea}.<br>"
        end
        success, messagea = FreecenValidations.fixed_uncertainy_birth?(record[:uncertainy_birth])
        unless success
          result = false
          message = message + "ERROR: line #{num} Birth uncertainty #{record[:uncertainy_birth]} is #{messagea}.<br>"
        end
        success, messagea = FreecenValidations.fixed_disability?(record[:disability])
        unless success
          result = false
          message = message + "ERROR: line #{num} Disability #{record[:disability]} is #{messagea}.<br>"
        end
        success, messagea = FreecenValidations.fixed_language?(record[:language])
        unless success
          result = false
          message = message + "ERROR: line #{num} Language #{record[:language]} is #{messagea}.<br>"
        end
        success, messagea = FreecenValidations.fixed_notes?(record[:notes])
        unless success
          result = false
          message = message + "ERROR: line #{num} Notes #{record[:notes]} is #{messagea}.<br>"
        end
        if ['1901', '1911'].include?(record[:year])
          success, messagea = FreecenValidations.at_home?(record[:at_home])
          unless success
            result = false
            message = message + "ERROR: line #{num} At Home #{record[:at_home]} is #{messagea}.<br>"
          end
          success, messagea = FreecenValidations.rooms?(record[:rooms], record[:year])
          unless success
            result = false
            message = message + "ERROR: line #{num} Rooms #{record[:rooms]} is #{messagea}.<br>"
          end
        end
        [result, message]
      end
    end

  end

  # ...........................................................................Instance methods

  def acknowledge
    file = self.freecen_csv_file
    if file.present?
      transcriber = file.userid_detail
      if transcriber.nil?
        userid = file.userid
        if userid.present?
          transcriber = UseridDetail.userid(userid).first
        end
      end
      show, transcribed_by = UseridDetail.can_we_acknowledge_the_transcriber(transcriber)
      credit = file.credit_name
    else
      transcribed_by = nil
      credit = nil
    end
    self.update_attributes(:transcribed_by => transcribed_by, :credit => credit)
  end

  def add_digest
    self.record_digest = self.cal_digest
  end

  def adjust_parameters(param)
    param[:year] = get_year(param, year)
    param[:processed_date] = Time.now
    param
  end

  def display_fields(search_record)
    self['register_type'] = ""
    self['register_type'] = search_record[:location_names][1].gsub('[','').gsub(']','') unless search_record[:location_names].nil? || search_record[:location_names][1].nil?
    place = ''
    church = ''
    unless search_record[:location_names].nil? || search_record[:location_names][0].nil?
      name_parts = search_record[:location_names][0].split(') ')
      case
      when name_parts.length == 1
        (place, church) = search_record[:location_names][0].split(' (')
      when name_parts.length == 2
        place = name_parts[0] + ")"
        name_parts[1][0] = ""
        church = name_parts[1]
      else
      end
    end
    place.present? ? self['place'] = place.strip : self['place'] = ''
    church.present? ? self['church_name'] = church[0..-2] : self['church_name'] = ''
    self['county'] = ""
    code = search_record[:chapman_code] unless search_record[:chapman_code].nil?
    ChapmanCode::CODES.each_pair do |key,value|
      if value.has_value?(code)
        self['county'] = value.key(code)
      end
    end
  end

  def get(date_string)
    if date_string && md = date_string.match(/(\d\d\d\d)/)
      md.captures.first.to_i
    else
      1 # assume illegible dates are old -- start with year 1
    end
  end

  def get_year(param, year)
    case param[:record_type]
    when "ba"
      year = FreeregValidations.year_extract(param[:baptism_date]) if param[:baptism_date].present?
      year = FreeregValidations.year_extract(param[:birth_date]) if param[:birth_date].present? && year.blank?
      year = FreeregValidations.year_extract(param[:confirmation_date]) if param[:confirmation_date].present? && year.blank?
      year = FreeregValidations.year_extract(param[:received_into_church_date]) if param[:received_into_church_date].present? && year.blank?
    when "bu"
      year = FreeregValidations.year_extract(param[:burial_date]) if  param[:burial_date].present?
      year = FreeregValidations.year_extract(param[:death_date]) if  param[:death_date].present? && year.blank?
    when "ma"
      year = FreeregValidations.year_extract(param[:marriage_date]) if  param[:marriage_date].present?
      year = FreeregValidations.year_extract(param[:contract_date]) if  param[:contract_date].present?  && year.blank?
    else
      flash[:notice] = 'No record type'
    end
    year
  end

  def transcribed_by_me?(user)
    if user.person_role == 'transcriber'
      all_assignments = user.assignments
      all_assignments.each do |assignment|
        image = assignment.image_server_images.where(:image_file_name => self.image_file_name).first
        return true if image.present?
      end
    end
    false
  end
end
