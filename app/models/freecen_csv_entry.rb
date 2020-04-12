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

  field :address_flag, type: String
  field :age, type: String
  field :age_unit, type: String #  Created from age
  field :at_home, type: String
  field :birth_county, type: String
  field :birth_place, type: String
  field :birth_place_flag, type: String
  field :children_born_alive, type: Integer
  field :children_deceased, type: Integer
  field :children_living, type: Integer
  field :civil_parish, type: String
  field :data_transition, type: String
  field :deleted_flag, type: String
  field :individual_flag, type: String
  field :disability, type: String
  field :disability_notes, type: String
  field :dwelling_number, type: Integer # derived
  field :ecclesiastical_parish, type: String
  field :enumeration_district, type: String
  field :error_messages, type: String
  field :flag, type: Boolean, default: false
  field :flexible, type: Boolean, default: false
  field :folio_number, type: String
  field :forenames, type: String
  field :house_number, type: String
  field :house_or_street_name, type: String
  field :individual_number, type: Integer
  field :info_messages, type: String
  field :language, type: String
  field :address_flag,  type: String
  field :marital_status, type: String
  field :municipal_borough, type: String
  field :name_flag, type: String
  field :nationality, type: String
  field :notes, type: String
  field :occupation, type: String
  field :occupation_category, type: String
  field :occupation_flag, type: String
  field :page_number, type: String
  field :parliamentary_constituency, type: String
  field :piece_number, type: Integer
  field :read_write, type: String
  field :record_number, type: Integer
  field :relationship, type: String
  field :religion, type: String
  field :roof_type, type: String
  field :rooms, type: String
  field :rooms_with_windows, type: String
  field :sanitary_district, type: String
  field :schedule_number, type: String
  field :school_board, type: String
  Field :school_children, type: Integer
  field :sequence_in_household, type: Integer # derived
  field :sex, type: String
  field :surname, type: String
  field :surname_maiden, type: String
  field :uninhabited_flag, type: String
  field :verbatim_birth_county, type: String
  field :verbatim_birth_place, type: String
  field :ward, type: String
  field :warning_messages, type: String
  field :year, type: String
  field :years_married, type: String

  belongs_to :freecen_csv_file, index: true, optional: true

  has_one :search_record, dependent: :restrict_with_error

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
      logger.warn("FREECEN:LOCATION:VALIDATION invalid freecen_csv_entry id #{freecen_csv_entry}.<br> ") unless result
      result
    end

    def validate_civil_parish(record, previous_civil_parish)
      # p 'civil_parish change validate'
      # p previous_civil_parish
      civil_parish = record[:civil_parish]
      # p civil_parish
      flexible = record[:flexible]
      num = record[:record_number]
      info_messages = record[:messages]
      result = true
      new_civil_parish = civil_parish

      success, messagea = FreecenValidations.fixed_valid_civil_parish?(civil_parish)
      unless success
        result = false
        messagea = "ERROR: line #{num} Civil Parish is blank.<br> " if messagea == 'blank'
        messagea = "ERROR: line #{num} Civil Parish has invalid text #{civil_parish}.<br>" if messagea == 'VALID_TEXT'
        record[:error_messages] = record[:error_messages] + messagea
        new_civil_parish = previous_civil_parish
        return [result, messagea, new_civil_parish]
      end

      valid = false
      record[:piece].subplaces.each do |subplace|
        valid = true if subplace[:name].to_s.downcase == civil_parish.to_s.downcase
        break if valid
      end
      if previous_civil_parish == ''
        message = "Info: line #{num} New Civil Parish #{civil_parish}.<br>"
        record[:info_messages] = record[:info_messages] + message if info_messages
        result = true
      elsif previous_civil_parish == civil_parish
        result = true
      elsif !valid
        message = "ERROR: line #{num} Civil Parish has changed to #{civil_parish} which is not in the list of subplaces.<br>"
        record[:error_messages] = record[:error_messages] + message
        result = false
      elsif valid
        message = "Info: line #{num} Civil Parish has changed to #{civil_parish}.<br>"
        record[:info_messages] = record[:info_messages] + message if info_messages
        result = false
      else
        message = "ERROR: line #{num} Civil Parish has changed to #{civil_parish} but failed all tests.<br>"
        record[:error_messages] = record[:error_messages] + message
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
      info_messages = record[:messages]
      result = true
      new_enumeration_district = previous_enumeration_district

      success, messagea = FreecenValidations.fixed_enumeration_district?(enumeration_district)
      unless success
        result = false
        new_enumeration_district = previous_enumeration_district
        messageb = "ERROR: line #{num} Enumeration District #{enumeration_district} is #{messagea}.<br>"
        message = messagea + messageb
        record[:error_messages] = record[:error_messages] + messageb
        return [result, message, new_enumeration_district]
      end

      parts = ''
      parts = enumeration_district.split('#') if enumeration_district.present?
      # p parts
      special = parts.length > 0 ? parts[1] : nil
      if previous_enumeration_district == ''
        message = "Info: line #{num} New Enumeration District #{enumeration_district}.<br>" if info_messages
        record[:info_messages] = record[:info_messages] + message if info_messages
        new_enumeration_district = enumeration_district
        result = true
      elsif previous_enumeration_district == enumeration_district
        result = true
      else
        message = "Warning: line #{num} Enumeration District changed to #{enumeration_district}.<br>" if special.blank? && enumeration_district.present?
        record[:warning_messages] = record[:warning_messages] + message if special.blank? && enumeration_district.present?
        message = "Info: line #{num} Enumeration District changed to blank.<br>" if special.blank? && enumeration_district.blank? && info_messages
        record[:info_messages] = record[:info_messages] + message if special.blank? && enumeration_district.blank?  && info_messages
        message = "Info: line #{num} Enumeration District changed to #{Freecen::SpecialEnumerationDistricts::CODES[special.to_i]}.<br>" if special.present? && info_messages
        record[:info_messages] = record[:info_messages] + message if special.present?  && info_messages
        new_enumeration_district = enumeration_district
        result = false
      end
      [result, message, new_enumeration_district]
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
      flexible = record[:flexible]
      num = record[:record_number]
      page_number = record[:page_number]
      transition = record[:data_transition]
      info_messages = record[:messages]
      year = record[:year]
      # p previous_folio_number
      # p previous_folio_suffix
      # p folio_number
      # p folio_suffix
      result = true
      new_folio_number = previous_folio_number
      new_folio_suffix = previous_folio_suffix

      message = "\r\n"
      success, messagea = FreecenValidations.fixed_folio_number?(record[:folio_number])
      unless success
        result = false
        messagea = "ERROR: line #{num} Folio number #{record[:folio_number]} is #{messagea}.<br>"
        record[:error_messages] = record[:error_messages] + messagea
        return [result, messagea, new_folio_number, new_folio_suffix]
      end

      if previous_folio_number == 0
        message = "Info: line #{num} Initial Folio number set to #{folio_number}.<br>" if info_messages
        record[:info_messages] = record[:info_messages] + message if info_messages
        new_folio_number = folio_number.to_i
        new_folio_suffix = folio_suffix
        result = true
      elsif  folio_number.blank? && ['Folio', 'Page'].include?(transition)
        message = ''
        result = false
      elsif  folio_number.blank? && year == '1841' && page_number.to_i.even?
        message = "Warning: line #{num} New Folio number is blank.<br>"
        record[:warning_messages] = record[:warning_messages] + message
        result = false
      elsif folio_number.blank? && year != '1841' && page_number.to_i.odd?
        message = "Warning: line #{num} New Folio number is blank.<br>"
        record[:warning_messages] = record[:warning_messages] + message
        result = false
      elsif folio_number.blank?
        result = true
      elsif previous_folio_number.present? && (folio_number.to_i > (previous_folio_number.to_i + 1))
        message = "Warning: line #{num} New Folio number increment larger than 1 #{folio_number}.<br>"
        record[:warning_messages] = record[:warning_messages] + message
        new_folio_number = folio_number.to_i
        new_folio_suffix = folio_suffix
        result = true
      elsif folio_number.to_i == previous_folio_number.to_i
        message = "Warning: line #{num} New Folio number is the same as the previous number #{folio_number}.<br>"
        record[:warning_messages] = record[:warning_messages] + message
        result = false
      elsif previous_folio_number.present? && (folio_number.to_i < previous_folio_number.to_i)
        message = "Warning: line #{num} New Folio number is less than the previous number #{folio_number}.<br>"
        record[:warning_messages] = record[:warning_messages] + message
        new_folio_number = folio_number.to_i
        new_folio_suffix = folio_suffix
        result = true
      else
        message = "Info: line #{num} New Folio number #{folio_number}.<br>" if info_messages
        record[:info_messages] = record[:info_messages] + message if info_messages
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
      info_messages = record[:messages]
      # p previous_page_number
      # p page_number
      result = true
      new_page_number = previous_page_number
      success, messagea = FreecenValidations.fixed_page_number?(page_number)
      unless success
        result = false
        new_page_number = previous_page_number
        messagea = "ERROR: line #{num} Page number #{page_number} is #{messagea}.<br>"
        record[:error_messages] = record[:error_messages] + messagea
        return [result, messagea, new_page_number]
      end

      if previous_page_number == 0
        message = "Info: line #{num} Initial Page number set to #{page_number}.<br>" if info_messages
        record[:info_messages] = record[:info_messages] + message if info_messages
        new_page_number = page_number.to_i
        result = true
      elsif  page_number.blank? && ['Folio', 'Page'].include?(transition)
        message = ''
        result = true
      elsif  page_number.blank?
        message = "Warning: line #{num} New Page number is blank.<br>"
        record[:warning_messages] = record[:warning_messages] + message
        result = false
      elsif page_number.to_i > previous_page_number + 1
        message = "Warning: line #{num} New Page number increment larger than 1 #{page_number}.<br>"
        record[:warning_messages] = record[:warning_messages] + message
        new_page_number = page_number.to_i
        result = true
      elsif page_number.to_i == previous_page_number
        message = "Warning: line #{num} New Page number is the same as the previous number #{page_number}.<br>"
        record[:warning_messages] = record[:warning_messages] + message
        result = false
      elsif page_number.to_i < previous_page_number && page_number.to_i != 1
        message = "Warning: line #{num} New Page number is less than the previous number #{page_number}.<br>"
        record[:warning_messages] = record[:warning_messages] + message
        new_page_number = page_number.to_i
        result = false
      elsif page_number.to_i < previous_page_number && page_number.to_i == 1
        message = "Info: line #{num} reset Page number to 1.<br>" if info_messages
        record[:info_messages] = record[:info_messages] + message if info_messages
        new_page_number = 1
        result = true
      else
        message = "Info: line #{num} New Page number #{page_number}.<br>" if info_messages
        record[:info_messages] = record[:info_messages] + message if info_messages
        new_page_number = page_number.to_i
        result = true
      end
      [result, message, new_page_number.to_i]
    end

    def validate_dwelling(record, previous_schedule_number, previous_schedule_suffix)
      # p 'validate_dwelling'
      schedule_number, schedule_suffix = suffix_extract(record[:schedule_number])
      house_number = record[:house_number]
      transition = record[:data_transition]
      uninhabited_flag = record[:uninhabited_flag]
      # p previous_schedule_number
      # p previous_schedule_suffix
      # p schedule_number
      # p schedule_suffix
      flexible = record[:flexible]
      num = record[:record_number]
      info_messages = record[:messages]
      overall_result = true
      new_schedule_number = schedule_number
      new_schedule_suffix = schedule_suffix

      message = ''
      success, messagea = FreecenValidations.fixed_schedule_number?(record[:schedule_number])
      if !success
        new_schedule_number = previous_schedule_number
        new_schedule_suffix = previous_schedule_suffix
        if messagea == 'blank' && ['Civil Parish', 'Enumeration District', 'Folio', 'Page'].include?(transition) && house_number.blank?
          message = "Info: line #{num} Schedule number retained at #{new_schedule_number}.<br>" if info_messages
          record[:info_messages] = record[:info_messages] + message if info_messages
          result = true
        elsif messagea == 'blank'
          result = false
          messagea = "ERROR: line #{num} Schedule number is blank and not a page transition.<br>"
          message = message + messagea
          record[:error_messages] = record[:error_messages] + messagea
        else
          result = false
          messagea = "ERROR: line #{num} Schedule number #{record[:schedule_number]} is #{messagea}.<br>"
          message = message + messagea
          record[:error_messages] = record[:error_messages] + messagea
        end
      elsif schedule_number.to_i > (previous_schedule_number.to_i + 1)
        message = "Warning: line #{num} Schedule number #{record[:schedule_number]} increments more than 1 .<br>"
        record[:warning_messages] = record[:warning_messages] + message
      elsif schedule_number.to_i < previous_schedule_number.to_i
        new_schedule_number = previous_schedule_number if ['b', 'n', 'u', 'v'].include?(uninhabited_flag)
        new_schedule_suffix = previous_schedule_suffix if ['b', 'n', 'u', 'v'].include?(uninhabited_flag)
        message = "Warning: line #{num} Schedule number #{record[:schedule_number]} is less than the previous one .<br>" unless ['u', 'v'].include?(uninhabited_flag)
        record[:warning_messages] = record[:warning_messages] + message
      end

      overall_result = false if result == false

      success, messagea = FreecenValidations.fixed_house_number?(house_number)
      if !success
        result = false
        messageb = "ERROR: line #{num} House number #{house_number} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messagea
      end
      overall_result = false if result == false

      success, messagea = FreecenValidations.fixed_house_address?(record[:house_or_street_name])
      unless success
        result = false
        if messagea == '?'
          messagea = "Warning: line #{num} House address #{record[:house_or_street_name]}  has trailing ?. Removed and address_flag set.<br>"
          message = message + messagea
          record[:warning_messages] = record[:warning_messages] + messagea
          record[:address_flag] = 'x'
          record[:house_or_street_name] = record[:house_or_street_name][0...-1]
        elsif messagea == 'blank'
          result = true
        else
          result = false
          messageb = "ERROR: line #{num} House address #{record[:house_or_street_name]} is #{messagea}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      end
      overall_result = false if result == false

      success, messagea = FreecenValidations.fixed_uninhabited_flag?(uninhabited_flag)
      unless success
        result = false
        messageb = "ERROR: line #{num} Special use #{uninhabited_flag} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messageb
      else
        if ['u', 'v'].include?(uninhabited_flag) && schedule_number.blank?
          messageb = "Warning: line #{num} has special #{uninhabited_flag} but no schedule number.<br>"
          message = message + messageb
          record[:warning_messages] = record[:warning_messages] + messageb
        end
        if uninhabited_flag == 'x'
          record[:address_flag] = 'x'
          record[:uninhabited_flag] = ''
          messageb = "Info: line #{num} uninhabited_flag if x is moved to loaction_flag.<br>"
        end
      end
      overall_result = false if result == false
      [overall_result, message, new_schedule_number, new_schedule_suffix]
    end

    def validate_individual(record)
      # p 'validate_individual'
      flexible = record[:flexible]
      num = record[:record_number]
      info_messages = record[:messages]
      result = true

      return [true, ''] if ['b', 'n', 'u', 'v'].include?(record[:uninhabited_flag])

      message = ''
      success, messagea = FreecenValidations.fixed_surname?(record[:surname])
      unless success
        result = false
        if messagea == '?'
          messageb = "Warning: line #{num} Surname  #{record[:surname]} has trailing ?. Removed and flag set.<br>"
          message = message + messageb
          record[:warning_messages] = record[:warning_messages] + messageb
          record[:name_flag] = 'x'
          record[:surname] = record[:surname][0...-1]
        else
          messageb = "ERROR: line #{num} Surname #{record[:surname]} is #{messagea}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      end
      success, messagea = FreecenValidations.fixed_forenames?(record[:forenames])
      unless success
        result = false
        if messagea == '?'
          messageb = "Warning: line #{num} Forenames  #{record[:forenames]} has trailing ?. Removed and flag set.<br>"
          message = message + messageb
          record[:warning_messages] = record[:warning_messages] + messageb
          record[:name_flag] = 'x'
          record[:forenames] = record[:forenames][0...-1]
        else
          messageb = "ERROR: line #{num} Forenames #{record[:forenames]} is #{messagea}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      end
      success, messagea = FreecenValidations.fixed_name_question?(record[:name_flag])
      unless success
        result = false
        messageb = "ERROR: line #{num} Uncertainty #{record[:name_flag]} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messageb
      end
      success, messagea = FreecenValidations.fixed_relationship?(record[:relationship])
      unless success
        result = false
        messageb = "ERROR: line #{num} Relationship #{record[:relationship]} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messageb
      end
      success, messagea = FreecenValidations.fixed_marital_status?(record[:marital_status])
      unless success
        result = false
        messageb = "ERROR: line #{num} Marital status #{record[:marital_status]} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messageb
      end
      success, messagea = FreecenValidations.fixed_sex?(record[:sex])
      unless success
        result = false
        messageb = "ERROR: line #{num} Sex #{record[:sex]} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messageb
      end
      success, messagea = FreecenValidations.fixed_age?(record[:age], record[:marital_status], record[:sex])
      unless success
        result = false
        messageb = "ERROR: line #{num} Age #{record[:age]} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messageb
      end
      success, messagea = FreecenValidations.fixed_uncertainty_status?(record[:individual_flag])
      unless success
        result = false
        messageb = "ERROR: line #{num} Query #{record[:individual_flag]} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messageb
      end
      success, messagea = FreecenValidations.fixed_occupation?(record[:occupation], record[:age])
      unless success
        result = false
        if messagea == '?'
          messageb = "Warning: line #{num} Occupation #{record[:occupation]} has trailing ?. Removed and flag set.<br>"
          message = message + messageb
          record[:warning_messages] = record[:warning_messages] + messageb
          record[:occupation_flag] = 'x'
          record[:occupation] = record[:occupation][0...-1]
        else
          messageb = "ERROR: line #{num} Occupation #{record[:occupation]} is #{messagea}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      end
      success, messagea = FreecenValidations.fixed_occupation_category?(record[:occupation_category])
      unless success
        result = false
        messageb = "ERROR: line #{num} Occupation category #{record[:occupation_category]} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messageb
      end
      success, messagea = FreecenValidations.fixed_uncertainty_occupation?(record[:occupation_flag])
      unless success
        result = false
        messageb = "ERROR: line #{num} Occupation uncertainty #{record[:occupation_flag]} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messageb
      end
      success, messagea = FreecenValidations.fixed_verbatim_birth_county?(record[:verbatim_birth_county])
      unless success
        result = false
        messageb = "ERROR: line #{num} Verbatim Birth County #{record[:verbatim_birth_county]} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messageb
      end
      success, messagea = FreecenValidations.fixed_verbatim_birth_place?(record[:verbatim_birth_place])
      unless success
        result = false
        messageb = "ERROR: line #{num} Verbatim Birth Place #{record[:verbatim_birth_place]} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messageb
      end
      success, messagea = FreecenValidations.fixed_uncertainy_birth?(record[:uncertainy_birth])
      unless success
        result = false
        messageb = "ERROR: line #{num} Birth uncertainty #{record[:uncertainy_birth]} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messageb
      end
      success, messagea = FreecenValidations.fixed_disability?(record[:disability])
      unless success
        result = false
        messageb = "ERROR: line #{num} Disability #{record[:disability]} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messageb
      end
      success, messagea = FreecenValidations.fixed_language?(record[:language])
      unless success
        result = false
        messageb = "ERROR: line #{num} Language #{record[:language]} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messageb
      end
      success, messagea = FreecenValidations.fixed_notes?(record[:notes])
      unless success
        result = false
        messageb = "ERROR: line #{num} Notes #{record[:notes]} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messageb
      end
      if ['1901', '1911'].include?(record[:year])
        success, messagea = FreecenValidations.at_home?(record[:at_home])
        unless success
          result = false
          messageb = "ERROR: line #{num} At Home #{record[:at_home]} is #{messagea}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
        success, messagea = FreecenValidations.rooms?(record[:rooms], record[:year])
        unless success
          result = false
          messageb = "ERROR: line #{num} Rooms #{record[:rooms]} is #{messagea}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end

        [result, message]
      end
    end
  end

  # ...........................................................................Instance methods

  def acknowledge
    file = freecen_csv_file
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
    update_attributes(:transcribed_by => transcribed_by, :credit => credit)
  end

  def add_digest
    record_digest = cal_digest
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

  def transcribed_by_me?(user)
    if user.person_role == 'transcriber'
      all_assignments = user.assignments
      all_assignments.each do |assignment|
        image = assignment.image_server_images.where(:image_file_name => image_file_name).first
        return true if image.present?
      end
    end
    false
  end

  def prev_next_dwelling_ids
    prev_id = nil
    next_id = nil
    idx = dwelling_number.to_i
    pc_id = freecen_piece_id
    if idx && idx >= 0
      prev_dwel = FreecenDwelling.where(freecen_piece_id: pc_id, dwelling_number: (idx - 1)).first
      prev_id = prev_dwel[:_id] unless prev_dwel.nil?
      next_dwel = FreecenDwelling.where(freecen_piece_id: pc_id, dwelling_number: (idx + 1)).first
      next_id = next_dwel[:_id] unless next_dwel.nil?
    end
    [prev_id, next_id]
  end

  # labels/vals for dwelling page header section (body in freecen_individuals)
  def self.dwelling_display_labels(year, chapman_code)
    #1841 doesn't have ecclesiastical parish or schedule number
    #Scotland doesn't have folio
    if year == '1841'
      if ChapmanCode::CODES['Scotland'].member?(chapman_code)
        return ['Census Year', 'County', 'Place', 'Civil Parish', 'Piece', 'Enumeration District', 'Page', 'House Number', 'House or Street Name', 'Dwelling Number']
      end
      return ['Census Year', 'County', 'Place', 'Civil Parish', 'Piece', 'Enumeration District', 'Folio', 'Page', 'House Number', 'House or Street Name', 'Dwelling Number']

    elsif year == '1901'
      if ChapmanCode::CODES['Scotland'].member?(chapman_code)
        return ['Census Year', 'County', 'Place', 'Civil Parish', 'Ecclesiastical Parish', 'Piece', 'Enumeration District', 'Page', 'Schedule', 'House Number', 'House or Street Name', 'Dwelling Number', 'Rooms']
      end

      ['Census Year', 'County', 'Place', 'Civil Parish', 'Ecclesiastical Parish', 'Piece', 'Enumeration District', 'Folio', 'Page', 'Schedule', 'House Number', 'House or Street Name', 'Dwelling Number', 'Rooms']
    else
      if ChapmanCode::CODES['Scotland'].member?(chapman_code)
        return ['Census Year', 'County', 'Place', 'Civil Parish', 'Ecclesiastical Parish', 'Piece', 'Enumeration District', 'Page', 'Schedule', 'House Number', 'House or Street Name', 'Dwelling Number']
      end

      ['Census Year', 'County', 'Place', 'Civil Parish', 'Ecclesiastical Parish', 'Piece', 'Enumeration District', 'Folio', 'Page', 'Schedule', 'House Number', 'House or Street Name', 'Dwelling Number']
    end
  end

  def dwelling_display_values(year, chapman_code)
    #1841 doesn't have ecclesiastical parish or schedule number
    #Scotland doesn't have folio
    freecen_piece = freecen_csv_file.freecen_piece
    district_name = freecen_piece.district_name.titleize if freecen_piece.district_name.present?
    ecclesiastical = ecclesiastical_parish.titleize if ecclesiastical_parish.present?
    civil = civil_parish.titleize if civil_parish.present?
    address = house_or_street_name.titleize if house_or_street_name.present?
    disp_county = '' + ChapmanCode.name_from_code(chapman_code) + ' (' + chapman_code + ')' unless chapman_code.nil?
    if year == '1841'
      if ChapmanCode::CODES['Scotland'].member?(chapman_code)
        return [freecen_piece.year, disp_county, district_name, civil, freecen_piece.piece_number.to_s, enumeration_district, page_number,
                house_number, address, dwelling_number]
      end

      return [freecen_piece.year, disp_county, district_name, civil, freecen_piece.piece_number.to_s, enumeration_district, folio_number,
              page_number, house_number, address, dwelling_number]
    elsif year == '1901'
      if ChapmanCode::CODES['Scotland'].member?(chapman_code)
        return [freecen_piece.year, disp_county, district_name, civil, ecclesiastical, freecen_piece.piece_number.to_s,
                enumeration_district, folio_number, page_number, schedule_number, house_number, address, dwelling_number, rooms]
      end
      [freecen_piece.year, disp_county, district_name, civil, ecclesiastical, freecen_piece.piece_number.to_s, enumeration_district,
       folio_number, page_number, schedule_number, house_number, address, dwelling_number, rooms]
    else
      if ChapmanCode::CODES['Scotland'].member?(chapman_code)
        return [freecen_piece.year, disp_county, district_name, civil, ecclesiastical, freecen_piece.piece_number.to_s, enumeration_district,
                folio_number, page_number, schedule_number, house_number, address, dwelling_number]
      end
      [freecen_piece.year, disp_county, district_name, civil, ecclesiastical, freecen_piece.piece_number.to_s, enumeration_district, folio_number,
       page_number, schedule_number, house_number, address, dwelling_number]

    end
  end

  def self.management_display_labels
    #1841 doesn't have ecclesiastical parish or schedule number
    #Scotland doesn't have folio

    ['Transition', 'Alt. Birth County', 'Alt. Birth Place', 'Location', 'Address', 'Name', 'Individual', 'Occupation', 'Birth Place', 'Deleted']
  end

  def management_display_values
    #1841 doesn't have ecclesiastical parish or schedule number
    #Scotland doesn't have folio
    birth = verbatim_birth_place.titleize if verbatim_birth_place.present?
    [data_transition, birth_county, birth_birth, locaton_flag, address_flag, name_flag, individual_flag, occupation_flag, birth_place_flag, deleted_flag]
  end

  def self.error_display_labels
    #1841 doesn't have ecclesiastical parish or schedule number
    #Scotland doesn't have folio

    ['ErrorsMessages', 'Warning Messages', 'Info Messages']
  end

  def error_display_values
    #1841 doesn't have ecclesiastical parish or schedule number
    #Scotland doesn't have folio

    [error_messages, warning_messages, info_messages]
  end

  def self.individual_display_labels(year, chapman_code)
    if year == '1841'
      return ['Sequence', 'Surname', 'Forenames', 'Sex', 'Age', 'Occupation', 'Birth County', 'Notes']
    elsif year == '1891'
      # only Wales 1891 has language field
      if ChapmanCode::CODES['Wales'].values.member?(chapman_code) || ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        return ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation', 'Occ Category', 'Birth County', 'Birth Place', 'Disability', 'Language', 'Notes']
      end
      return ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation', 'Occ Category', 'Birth County', 'Birth Place', 'Disability', 'Notes']
    elsif year == '1901'
      if ChapmanCode::CODES['Wales'].values.member?(chapman_code) || ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        return ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation', 'Occ Category', 'Birth County', 'Birth Place', 'Disability', 'Language', 'At Home', 'Notes']
      end
      return ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation', 'Occ Category', 'Birth County', 'Birth Place', 'Disability', 'At Home', 'Notes']
    end
    #return standard fields for 1851 - 1881
    ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation', 'Occ Category', 'Birth County', 'Birth Place', 'Disability', 'Notes']
  end

  def individual_display_values(year, chapman_code)
    disp_age = age
    if age_unit.present? && age_unit != 'y'
      disp_age = age + age_unit
    end
    disp_occupation = occupation.titleize if occupation.present?
    sur = surname.upcase if surname.present?
    fore = forenames.titleize if forenames.present?
    relation = relationship.titleize if relationship.present?
    marital = marital_status.upcase if marital_status.present?
    birth = birth_place.titleize if birth_place.present?
    note = notes.titleize if notes.present?
    sx = sex.upcase if sex.present?
    if year == '1841'
      return [sequence_in_household, sur, fore, sx, disp_age, disp_occupation, birth_county, notes]
    elsif year == '1891'
      # only Wales 1891 has language field
      if ChapmanCode::CODES['Wales'].values.member?(chapman_code) || ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        return [sequence_in_household, sur, fore, relation, marital, sx, disp_age, disp_occupation, occupation_category, birth_county, birth,
                disability, language, note]
      end
      return [sequence_in_household, sur, fore, relation, marital, sx, disp_age, disp_occupation, occupation_category, birth_county, birth,
              disability, note]
    elsif year == '1901'
      if ChapmanCode::CODES['Wales'].values.member?(chapman_code) || ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        return [sequence_in_household, sur, fore, relation, marital, sx, disp_age, disp_occupation, occupation_category, birth_county, birth,
                disability, language, at_home, note]
      end
      return [sequence_in_household, sur, fore, relation, marital, sx, disp_age, disp_occupation, occupation_category, birth_county, birth,
              disability, at_home, note]
    end
    # standard fields for 1851 - 1881
    [sequence_in_household, sur, fore, relation, marital, sx, disp_age, disp_occupation, occupation_category, birth_county, birth, disability,
     note]
  end

  def next_and_previous_entries
    file_id = freecen_csv_file.id
    next_entry = record_number + 1
    previous_entry = record_number - 1
    next_entry = FreecenCsvEntry.find_by(record_number: next_entry, freecen_csv_file_id: file_id)
    previous_entry = FreecenCsvEntry.find_by(record_number: previous_entry, freecen_csv_file_id: file_id)
    [next_entry, previous_entry]
  end
end
