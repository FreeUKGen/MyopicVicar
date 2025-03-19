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
  require 'age_parser'

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
  field :class_of_house, type: String
  field :data_transition, type: String
  field :deleted_flag, type: String
  field :individual_flag, type: String
  field :disability, type: String
  field :disability_notes, type: String
  field :dwelling_number, type: Integer # derived
  field :ecclesiastical_parish, type: String
  field :enumeration_district, type: String
  field :error_messages, type: String
  field :father_place_of_birth, type: String
  field :flag, type: Boolean, default: false
  field :flexible, type: Boolean, default: false
  field :folio_number, type: String
  field :forenames, type: String
  field :house_number, type: String
  field :house_or_street_name, type: String
  field :individual_number, type: Integer
  field :info_messages, type: String
  field :industry, type: String
  field :language, type: String
  field :location_flag, type: String
  field :marital_status, type: String
  field :name_flag, type: String
  field :nationality, type: String
  field :notes, type: String
  field :occupation, type: String
  field :occupation_category, type: String
  field :occupation_flag, type: String
  field :page_number, type: String
  field :parliamentary_constituency, type: String
  field :piece_number, type: String
  field :police_district, type: String
  field :poor_law_union, type: String
  field :read_write, type: String
  field :record_number, type: Integer
  field :relationship, type: String
  field :religion, type: String
  field :roof_type, type: String
  field :rooms, type: String
  field :rooms_with_windows, type: String
  field :sanitary_district, type: String
  field :scavenging_district, type: String
  field :schedule_number, type: String
  field :school_board, type: String
  field :school_children, type: Integer
  field :sequence_in_household, type: Integer # derived
  field :sex, type: String
  field :special_lighting_district, type: String
  field :special_water_district, type: String
  field :surname, type: String
  field :surname_maiden, type: String
  field :uninhabited_flag, type: String
  field :verbatim_birth_county, type: String
  field :verbatim_birth_place, type: String
  field :walls, type: Integer
  field :ward, type: String
  field :warning_messages, type: String
  field :where_census_taken, type: String
  field :year, type: String
  field :years_married, type: String
  field :record_valid, type: String, default: 'false'

  belongs_to :freecen_csv_file, index: true, optional: true
  belongs_to :freecen2_civil_parish, index: true, optional: true

  has_one :search_record, dependent: :restrict_with_error

  delegate :validation, :chapman_code, to: :freecen_csv_file, prefix: :file, allow_nil: true

  before_destroy do |entry|
    SearchRecord.collection.delete_many(freecen_csv_entry_id: entry._id) if entry.present?
  end

  before_save :adjust_case

  after_save :check_valid

  index({ freecen_csv_file_id: 1, year: 1 }, { name: 'freecen_csv_file_id_year' })
  index({ freecen_csv_file_id: 1, file_line_number: 1 })
  index({ freecen_csv_file_id: 1, record_digest: 1 })

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

    def myupcase(value)
      value.strip.upcase if value.present?
    end

    def mystrip(value)
      value.strip if value.present?
    end

    def mytitlieze(value)
      value = value.present? && !value.chars.include?('-') ? value.strip.downcase.titleize : value
      value
    end

    def propagation_scope(entry, chapman_code)
      if  entry.verbatim_birth_county == chapman_code ||
          %w[OVF ENG SCT IRL WLS CHI].include?(entry.verbatim_birth_county) ||
          (chapman_code == 'HAM' && %w[HAM IOW].include?(entry.verbatim_birth_county)) ||
          (chapman_code == 'YKS' && %w[YKS ERY WRY NRY].include?(entry.verbatim_birth_county))
        scope = 'Collection'
      else
        scope = 'File'
      end
      scope
    end

    def update_parameters(params, entry)
      #clean up old null entries
      params = params.delete_if { |k, v| v == '' }
      params
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
      civil_parish = record[:civil_parish]
      num = record[:record_number]
      info_messages = record[:messages]
      new_civil_parish = civil_parish
      message = ''
      success, messagea = FreecenValidations.valid_parish?(civil_parish)

      unless success
        if messagea == '?'
          messagea = "Warning: line #{num} Civil Parish #{civil_parish}  has trailing ?. Removed and location_flag set.<br>"
          record[:warning_messages] += messagea
          record[:location_flag] = 'x'
          record[:civil_parish] = record[:civil_parish][0...-1].strip
          new_civil_parish = record[:civil_parish]
          message += messagea
        elsif messagea == 'blank'
          messageb = "ERROR: line #{num} Civil Parish is blank.<br> "
          record[:error_messages] += messageb
          new_civil_parish = previous_civil_parish
          return [messageb, new_civil_parish]
        elsif messagea == 'invalid text'
          messagea = "ERROR: line #{num} Civil Parish #{civil_parish} has invalid text.<br>"
          record[:error_messages] += messagea
          new_civil_parish = 'invalid'
          record[:civil_parish] = record[:civil_parish].gsub('.', 'invalid')
          return [messagea, new_civil_parish]
        end
      end

      valid = false

      record[:piece].freecen2_civil_parishes.each do |subplace|
        valid = true if subplace[:name].to_s.downcase == record[:civil_parish].to_s.downcase
        break if valid
      end
      unless valid
        messagea += "ERROR: line #{num} Civil Parish #{record[:civil_parish]} is not in the list of Civil Parishes.<br>"
        record[:error_messages] += messagea
        message += messagea
      end

      freecen2_civil_parish = Freecen2CivilParish.find_by(standard_name: Freecen2Place.standard_place(record[:civil_parish]), year: record[:year], chapman_code: record[:piece].chapman_code)
      if freecen2_civil_parish.present? && freecen2_civil_parish.freecen2_place_id.blank?
        messagea += "Warning: line #{num} Civil Parish #{record[:civil_parish]} does not link to a place.<br>"
        record[:warning_messages] += messagea
        message += messagea
      end

      if previous_civil_parish == ''
        messagea = "Info: line #{num} New Civil Parish #{record[:civil_parish]}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        message += messagea if messagea.present?
      elsif previous_civil_parish == record[:civil_parish]
        messagea = "Info: line #{num} Civil Parish has remained the same #{record[:civil_parish]}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        message += messagea if messagea.present?
      elsif info_messages
        messagea = "Info: line #{num} Civil Parish has changed to #{record[:civil_parish]}.<br>"
        record[:info_messages] += messagea if info_messages
        message += messagea if messagea.present?
      end

      [message, new_civil_parish]
    end

    def validate_enumeration_district(record, previous_enumeration_district)
      # p 'validate_enumeration_district'
      # p previous_enumeration_district

      enumeration_district = record[:enumeration_district]
      # p enumeration_district
      num = record[:record_number]
      info_messages = record[:messages]
      new_enumeration_district = previous_enumeration_district

      success, messagea = FreecenValidations.enumeration_district?(enumeration_district)
      unless success
        if messagea == '?'
          messagea = "Warning: line #{num} Enumeration District #{enumeration_district}  has trailing ?. Removed and location_flag set.<br>"
          record[:warning_messages] += messagea
          record[:location_flag] = 'x'
          record[:enumeration_district] = record[:enumeration_district][0...-1]
          enumeration_district = record[:enumeration_district]
          message += messagea
        else
          new_enumeration_district = previous_enumeration_district
          messageb = "ERROR: line #{num} Enumeration District #{enumeration_district} is #{messagea}.<br>"
          record[:error_messages] += messageb
          return [messageb, new_enumeration_district]
        end
      end

      parts = ''
      parts = enumeration_district.split('#') if enumeration_district.present?
      # p parts
      special = parts.length > 0 ? parts[1] : nil
      if previous_enumeration_district == ''
        message = "Info: line #{num} New Enumeration District #{enumeration_district}.<br>" if info_messages
        record[:info_messages] += message if info_messages
        new_enumeration_district = enumeration_district
      elsif previous_enumeration_district == enumeration_district
      else
        message = "Info: line #{num} Enumeration District changed to #{enumeration_district}.<br>" if special.blank? && enumeration_district.present? && info_messages
        record[:info_messages] += message if special.blank? && enumeration_district.present? && info_messages
        message = "Info: line #{num} Enumeration District changed to blank.<br>" if special.blank? && enumeration_district.blank? && info_messages
        record[:info_messages] += message if special.blank? && enumeration_district.blank?  && info_messages
        message = "Info: line #{num} Enumeration District changed to #{Freecen::SpecialEnumerationDistricts::CODES[special.to_i]}.<br>" if special.present? && info_messages
        record[:info_messages] += message if special.present? && info_messages
        new_enumeration_district = enumeration_district
      end
      [message, new_enumeration_district]
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

    def validate_ecclesiastical_parish(record, previous_ecclesiastical_parish)
      ecclesiastical_parish = record[:ecclesiastical_parish]
      num = record[:record_number]
      new_ecclesiastical_parish = previous_ecclesiastical_parish
      info_messages = record[:messages]
      message = ''
      success, messagea = FreecenValidations.valid_parish?(ecclesiastical_parish)
      unless success
        if messagea == '?'
          messagea = "Warning: line #{num} Ecclesiastical Parish #{ecclesiastical_parish}  has trailing ?. Removed and location_flag set.<br>"
          record[:warning_messages] += messagea
          record[:location_flag] = 'x'
          record[:ecclesiastical_parish] = record[:ecclesiastical_parish][0...-1].strip
          ecclesiastical_parish = record[:ecclesiastical_parish]
          message += messagea
        else
          messageb = "ERROR: line #{num} Ecclesiastical Parish #{ecclesiastical_parish} is #{messagea}.<br>"
          record[:error_messages] += messageb
          return [messageb, new_ecclesiastical_parish]
        end
      end
      if previous_ecclesiastical_parish == ''
        messagea = "Info: line #{num} New Ecclesiastical Parish #{ecclesiastical_parish}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        new_ecclesiastical_parish = ecclesiastical_parish
        message += messagea if info_messages
      elsif ecclesiastical_parish.blank?
      elsif previous_ecclesiastical_parish == ecclesiastical_parish
      else
        messagea = "Info: line #{num} Ecclesiastical Parish changed to #{ecclesiastical_parish}.<br>" if info_messages
        record[:info_messages] += message if info_messages
        message += messagea if info_messages
        new_ecclesiastical_parish = ecclesiastical_parish
      end

      [message, new_ecclesiastical_parish]
    end

    def validate_where_census_taken(record, previous_where_census_taken)
      where_census_taken = record[:where_census_taken]
      num = record[:record_number]
      new_where_census_taken = previous_where_census_taken
      info_messages = record[:messages]
      message = ''
      success, messagea = FreecenValidations.tight_location?(where_census_taken)
      unless success
        if messagea == '?'
          messagea = "Warning: line #{num} Where Census Taken #{where_census_taken}  has trailing ?. Removed and location_flag set.<br>"
          record[:warning_messages] += messagea
          record[:location_flag] = 'x'
          record[:where_census_taken] = record[:where_census_taken][0...-1].strip
          where_census_taken = record[:where_census_taken]
          message += messagea
        else
          messageb = "ERROR: line #{num} Where Census Taken #{where_census_taken} is #{messagea}.<br>"
          record[:error_messages] += messageb
          return [messageb, new_where_census_taken]
        end
      end
      if previous_where_census_taken == ''
        messagea = "Info: line #{num} New Where Census Taken #{where_census_taken}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        message += messagea if info_messages
        new_where_census_taken = where_census_taken
      elsif where_census_taken.blank?
      elsif previous_where_census_taken == where_census_taken
      else
        message = "Info: line #{num} Where Census Taken changed to #{where_census_taken}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        message += messagea if info_messages
        new_where_census_taken = where_census_taken
      end
      [message, new_where_census_taken]
    end

    def validate_ward(record, previous_ward)
      ward = record[:ward]
      num = record[:record_number]
      new_ward = previous_ward
      info_messages = record[:messages]
      message = ''
      success, messagea = FreecenValidations.valid_location?(ward)
      unless success
        if messagea == '?'
          messagea = "Warning: line #{num} Ward #{ward}  has trailing ?. Removed and location_flag set.<br>"
          record[:warning_messages] += messagea
          record[:location_flag] = 'x'
          record[:ward] = record[:ward][0...-1].strip
          ward = record[:ward]
          message += messagea
        else
          messageb = "ERROR: line #{num} Ward #{ward} is #{messagea}.<br>"
          record[:error_messages] += messageb
          return [messageb, new_ward]
        end
      end
      if previous_ward == ''
        messagea = "Info: line #{num} New Ward #{ward}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        message += messagea if info_messages
        new_ward = ward
      elsif ward.blank?
      elsif previous_ward == ward
      else
        messagea = "Info: line #{num} Ward changed to #{ward}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        message += messagea if info_messages
        new_ward = ward
      end
      [message, new_ward]
    end

    def validate_parliamentary_constituency(record, previous_parliamentary_constituency)
      parliamentary_constituency = record[:parliamentary_constituency]
      num = record[:record_number]
      new_parliamentary_constituency = previous_parliamentary_constituency
      info_messages = record[:messages]
      message = ''
      success, messagea = FreecenValidations.valid_location?(parliamentary_constituency)
      unless success
        if messagea == '?'
          messagea = "Warning: line #{num} Parliamentary Constituency #{parliamentary_constituency}  has trailing ?. Removed and location_flag set.<br>"
          record[:warning_messages] += messagea
          record[:location_flag] = 'x'
          record[:parliamentary_constituency] = record[:parliamentary_constituency][0...-1].strip
          parliamentary_constituency = record[:parliamentary_constituency]
          message += messagea
        else
          messageb = "ERROR: line #{num} Parliamentary Constituency #{parliamentary_constituency} is #{messagea}.<br>"
          record[:error_messages] += messageb
          return [messageb, new_parliamentary_constituency]
        end
      end
      if previous_parliamentary_constituency == ''
        messagea = "Info: line #{num} New Parliamentary Constituency #{parliamentary_constituency}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        message += messagea if info_messages
        new_parliamentary_constituency = parliamentary_constituency
      elsif parliamentary_constituency.blank?
      elsif previous_parliamentary_constituency == parliamentary_constituency
      else
        messagea = "Info: line #{num} Parliamentary Constituency changed to #{parliamentary_constituency}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        message += messagea if info_messages
        new_parliamentary_constituency = parliamentary_constituency
      end
      [message, new_parliamentary_constituency]
    end

    def validate_poor_law_union(record, previous_poor_law_union)
      poor_law_union = record[:poor_law_union]
      num = record[:record_number]
      new_poor_law_union = previous_poor_law_union
      info_messages = record[:messages]
      message = ''
      success, messagea = FreecenValidations.valid_location?(poor_law_union)
      unless success
        if messagea == '?'
          messagea = "Warning: line #{num} Poor Law Union #{poor_law_union}  has trailing ?. Removed and location_flag set.<br>"
          record[:warning_messages] += messagea
          record[:location_flag] = 'x'
          record[:poor_law_union] = record[:poor_law_union][0...-1].strip
          new_poor_law_union = record[:poor_law_union]
          message += messagea
        else
          messageb = "ERROR: line #{num} Poor Law Union #{poor_law_union} is #{messagea}.<br>"
          record[:error_messages] += messageb
          return [messageb, new_poor_law_union]
        end
      end
      if previous_poor_law_union == ''
        messagea = "Info: line #{num} New Poor Law Union #{poor_law_union}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        message += messagea if info_messages
        new_poor_law_union = poor_law_union
      elsif poor_law_union.blank?
      elsif previous_poor_law_union == poor_law_union
      else
        messagea = "Info: line #{num} Poor Law Union changed to #{poor_law_union}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        message += messagea if info_messages
        new_poor_law_union = poor_law_union
      end
      [message, new_poor_law_union]
    end

    def validate_police_district(record, previous_police_district)
      police_district = record[:police_district]
      num = record[:record_number]
      new_police_district = previous_police_district
      info_messages = record[:messages]
      message = ''
      success, messagea = FreecenValidations.valid_location?(police_district)
      unless success
        if messagea == '?'
          messagea = "Warning: line #{num} Police District #{police_district}  has trailing ?. Removed and location_flag set.<br>"
          record[:warning_messages] += messagea
          record[:location_flag] = 'x'
          record[:police_district] = record[:police_district][0...-1].strip
          new_police_district = record[:police_district]
          message += messagea
        else
          messageb = "ERROR: line #{num} Police District #{police_district} is #{messagea}.<br>"
          record[:error_messages] += messageb
          return [messageb, new_police_district]
        end
      end
      if previous_police_district == ''
        messagea = "Info: line #{num} New Police District #{police_district}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        message += messagea if info_messages
        new_police_district = police_district
      elsif police_district.blank?
      elsif previous_police_district == police_district
      else
        messagea = "Info: line #{num} Police District changed to #{police_district}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        message += messagea if info_messages
        new_police_district = police_district
      end
      [message, new_police_district]
    end

    def validate_sanitary_district(record, previous_sanitary_district)
      sanitary_district = record[:sanitary_district]
      num = record[:record_number]
      new_sanitary_district = previous_sanitary_district
      info_messages = record[:messages]
      message = ''
      success, messagea = FreecenValidations.valid_location?(sanitary_district)
      unless success
        if messagea == '?'
          messagea = "Warning: line #{num} Sanitary District #{sanitary_district}  has trailing ?. Removed and location_flag set.<br>"
          record[:warning_messages] += messagea
          record[:location_flag] = 'x'
          record[:sanitary_district] = record[:sanitary_district][0...-1].strip
          sanitary_district = record[:sanitary_district]
          message += messagea
        else
          messageb = "ERROR: line #{num} Sanitary District #{sanitary_district} is #{messagea}.<br>"
          record[:error_messages] += messageb
          return [messageb, new_sanitary_district]
        end
      end
      if previous_sanitary_district == ''
        messagea = "Info: line #{num} New Sanitary District #{sanitary_district}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        message += messagea if info_messages
        new_sanitary_district = sanitary_district
      elsif sanitary_district.blank?
      elsif previous_sanitary_district == sanitary_district
      else
        messagea = "Info: line #{num} Sanitary District changed to #{sanitary_district}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        message += messagea if info_messages
        new_sanitary_district = sanitary_district
      end
      [message, new_sanitary_district]
    end

    def validate_special_water_district(record, previous_special_water_district)
      special_water_district = record[:special_water_district]
      num = record[:record_number]
      new_special_water_district = previous_special_water_district
      info_messages = record[:messages]
      message = ''
      success, messagea = FreecenValidations.valid_location?(special_water_district)
      unless success
        if messagea == '?'
          messagea = "Warning: line #{num} Special Water District #{special_water_district}  has trailing ?. Removed and location_flag set.<br>"
          record[:warning_messages] += messagea
          record[:location_flag] = 'x'
          record[:special_water_district] = record[:special_water_district][0...-1].strip
          special_water_district = record[:special_water_district]
          message += messagea
        else
          messageb = "ERROR: line #{num} Special Water District #{special_water_district} is #{messagea}.<br>"
          record[:error_messages] += messageb
          return [messageb, new_special_water_district]
        end
      end
      if previous_special_water_district == ''
        messagea = "Info: line #{num} New Special Water District #{special_water_district}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        message += messagea if info_messages
        new_special_water_district = special_water_district
      elsif special_water_district.blank?
      elsif previous_special_water_district == special_water_district
      else
        messagea = "Info: line #{num} Special Water District changed to #{special_water_district}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        message += messagea if info_messages
        new_special_water_district = special_water_district
      end
      [message, new_special_water_district]
    end

    def validate_scavenging_district(record, previous_scavenging_district)
      scavenging_district = record[:scavenging_district]
      num = record[:record_number]
      new_scavenging_district = previous_scavenging_district
      info_messages = record[:messages]
      message = ''
      success, messagea = FreecenValidations.valid_location?(scavenging_district)
      unless success
        if messagea == '?'
          messagea = "Warning: line #{num} Scavenging District #{scavenging_district}  has trailing ?. Removed and location_flag set.<br>"
          record[:warning_messages] += messagea
          record[:location_flag] = 'x'
          record[:scavenging_district] = record[:scavenging_district][0...-1].strip
          scavenging_district = record[:scavenging_district]
          message += messagea
        else
          messageb = "ERROR: line #{num} Scavenging District #{scavenging_district} is #{messagea}.<br>"
          record[:error_messages] += messageb
          return [messageb, new_scavenging_district]
        end
      end
      if previous_scavenging_district == ''
        messagea = "Info: line #{num} New Scavenging District #{scavenging_district}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        message += messagea if info_messages
        new_scavenging_district = scavenging_district
      elsif scavenging_district.blank?
      elsif previous_scavenging_district == scavenging_district
      else
        messagea = "Info: line #{num} Scavenging District changed to #{scavenging_district}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        message += messagea if info_messages
        new_scavenging_district = scavenging_district
      end
      [message, new_scavenging_district]
    end

    def validate_special_lighting_district(record, previous_special_lighting_district)
      special_lighting_district = record[:special_lighting_district]
      num = record[:record_number]
      new_special_lighting_district = previous_special_lighting_district
      info_messages = record[:messages]
      message = ''
      success, messagea = FreecenValidations.valid_location?(special_lighting_district)
      unless success
        if messagea == '?'
          messagea = "Warning: line #{num} Special Lighting District #{special_lighting_district}  has trailing ?. Removed and location_flag set.<br>"
          record[:warning_messages] += messagea
          record[:location_flag] = 'x'
          record[:special_lighting_district] = record[:special_lighting_district][0...-1].strip
          special_lighting_district = record[:special_lighting_district]
          message += messagea
        else
          messageb = "ERROR: line #{num} Special Lighting District #{special_lighting_district} is #{messagea}.<br>"
          record[:error_messages] += messageb
          return [messageb, new_special_lighting_district]
        end
      end
      if previous_special_lighting_district == ''
        messagea = "Info: line #{num} New Special Lighting District #{special_lighting_district}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        message += messagea if info_messages
        new_special_lighting_district = special_lighting_district
      elsif special_lighting_district.blank?
      elsif previous_special_lighting_district == special_lighting_district
      else
        messagea = "Info: line #{num} Special Lighting District changed to #{special_lighting_district}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        message += messagea if info_messages
        new_special_lighting_district = special_lighting_district
      end
      [message, new_special_lighting_district]
    end

    def validate_school_board(record, previous_school_board)
      school_board = record[:school_board]
      num = record[:record_number]
      new_school_board = previous_school_board
      info_messages = record[:messages]
      message = ''
      success, messagea = FreecenValidations.valid_location?(school_board)
      unless success
        if messagea == '?'
          messagea = "Warning: line #{num} School Board #{school_board}  has trailing ?. Removed and location_flag set.<br>"
          record[:warning_messages] += messagea
          record[:location_flag] = 'x'
          record[:school_board] = record[:school_board][0...-1].strip
          school_board = record[:school_board]
          message += messagea
        else
          messageb = "ERROR: line #{num} School Board #{school_board} is #{messagea}.<br>"
          record[:error_messages] += messageb
          return [messageb, new_school_board]
        end
      end
      if previous_school_board == ''
        messagea = "Info: line #{num} New School Board #{school_board}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        message += messagea if info_messages
        new_school_board = school_board
      elsif school_board.blank?
      elsif previous_school_board == school_board
      else
        messagea = "Info: line #{num} School Board changed to #{school_board}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        message += messagea if info_messages
        new_school_board = school_board
      end
      [message, new_school_board]
    end

    def validate_location_flag(record)
      flag = record[:location_flag]
      num = record[:record_number]
      info_messages = record[:messages]
      message = ''
      success, messagea = FreecenValidations.location_flag?(flag)
      if !success
        messageb = "ERROR: line #{num} Location Flag #{flag} is #{messagea}.<br>"
        record[:error_messages] += messageb
        return [messageb]
      elsif flag.present?
        messagea = "Warning: line #{num} Location Flag is #{flag}.<br>"
        record[:warning_messages] += messagea
        message += messagea
      end
    end

    def validate_folio(record, previous_folio_number, previous_folio_suffix)
      # p 'validate_folio'
      folio_number, folio_suffix = suffix_extract(record[:folio_number])
      num = record[:record_number]
      page_number = record[:page_number]
      transition = record[:data_transition]
      info_messages = record[:messages]
      year = record[:year]
      new_folio_number = previous_folio_number
      new_folio_suffix = previous_folio_suffix
      success, messagea = FreecenValidations.folio_number?(record[:folio_number])

      unless success
        messagea = "ERROR: line #{num} Folio number #{record[:folio_number]} is #{messagea}.<br>"
        record[:error_messages] += messagea
        return [messagea, new_folio_number, new_folio_suffix]
      end

      if previous_folio_number == 0
        message = "Info: line #{num} Initial Folio number set to #{folio_number}.<br>" if info_messages
        record[:info_messages] += message if info_messages
        new_folio_number = folio_number.to_i
        new_folio_suffix = folio_suffix
      elsif  folio_number.blank? && ['Folio', 'Page'].include?(transition)
        message = ''
      elsif  folio_number.blank? && year == '1841' && page_number.to_i.even?
        if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
          message = "Warning: line #{num} New Folio number is blank.<br>"
          record[:warning_messages] += message
        end
      elsif folio_number.blank? && year != '1841' && page_number.to_i.odd?
        if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
          message = "Warning: line #{num} New Folio number is blank.<br>"
          record[:warning_messages] += message
        end
      elsif folio_number.blank?
      elsif previous_folio_number.present? && (folio_number.to_i > (previous_folio_number.to_i + 1))
        if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
          message = "Warning: line #{num} New Folio number increment larger than 1 #{folio_number}.<br>"
          record[:warning_messages] += message
        end
        new_folio_number = folio_number.to_i
        new_folio_suffix = folio_suffix
      elsif (folio_number.to_i == previous_folio_number.to_i)
        if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
          message = "Warning: line #{num} New Folio number is the same as the previous number #{folio_number}.<br>"
          record[:warning_messages] += message
        end
      elsif previous_folio_number.present? && (folio_number.to_i < previous_folio_number.to_i)
        if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
          message = "Warning: line #{num} New Folio number is less than the previous number #{folio_number}.<br>"
          record[:warning_messages] += message
        end
        new_folio_number = folio_number.to_i
        new_folio_suffix = folio_suffix
      else
        message = "Info: line #{num} New Folio number #{folio_number}.<br>" if info_messages
        record[:info_messages] += message if info_messages
        new_folio_number = folio_number
        new_folio_suffix = folio_suffix
      end
      [message, new_folio_number, new_folio_suffix]
    end

    def validate_page(record, previous_page_number)
      # p 'validate_page'
      page_number = record[:page_number]
      num = record[:record_number]
      transition = record[:data_transition]
      info_messages = record[:messages]
      # p previous_page_number
      # p page_number
      new_page_number = previous_page_number
      success, messagea = FreecenValidations.page_number?(page_number)
      unless success
        new_page_number = previous_page_number
        messagea = "ERROR: line #{num} Page number #{page_number} is #{messagea}.<br>"
        record[:error_messages] += messagea
        return [messagea, new_page_number]
      end



      if previous_page_number == 0 && page_number.blank?
        messagea = "ERROR: line #{num} Page number #{page_number} is #{messagea}.<br>"
        record[:error_messages] += messagea
        return [messagea, new_page_number]
      elsif previous_page_number == 0
        message = "Info: line #{num} Initial Page number set to #{page_number}.<br>" if info_messages
        record[:info_messages] += message if info_messages
        new_page_number = page_number.to_i
      elsif  page_number.blank? && Freecen::LOCATION_PAGE.include?(transition)
        message = ''
      elsif  page_number.blank?
        if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
          message = "Warning: line #{num} New Page number is blank.<br>"
        end
        record[:warning_messages] += message
      elsif (page_number.to_i > previous_page_number + 1) && Freecen::LOCATION_PAGE.include?(transition)
        if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
          message = "Warning: line #{num} New Page number increment larger than 1 #{page_number}.<br>"
          record[:warning_messages] += message
        end
        new_page_number = page_number.to_i
      elsif (page_number.to_i == previous_page_number) && Freecen::LOCATION_PAGE.include?(transition)
        if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
          message = "Warning: line #{num} New Page number is the same as the previous number #{page_number}.<br>"
          record[:warning_messages] += message
        end
      elsif page_number.to_i < previous_page_number && page_number.to_i != 1 && Freecen::LOCATION_PAGE.include?(transition)
        if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
          message = "Warning: line #{num} New Page number is less than the previous number #{page_number}.<br>"
          record[:warning_messages] += message
        end
        new_page_number = page_number.to_i
      elsif page_number.to_i < previous_page_number && page_number.to_i == 1
        message = "Info: line #{num} reset Page number to 1.<br>" if info_messages
        record[:info_messages] += message if info_messages
        new_page_number = 1
      else
        message = "Info: line #{num} New Page number #{page_number}.<br>" if info_messages
        record[:info_messages] += message if info_messages
        new_page_number = page_number.to_i
      end
      [message, new_page_number.to_i]
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
      num = record[:record_number]
      info_messages = record[:messages]
      new_schedule_number = schedule_number
      new_schedule_suffix = schedule_suffix
      message = ''
      success, messagea = FreecenValidations.schedule_number?(record[:schedule_number])
      if !success
        new_schedule_number = previous_schedule_number
        new_schedule_suffix = previous_schedule_suffix
        if messagea == 'blank' && Freecen::LOCATION_PAGE.include?(transition) && house_number.blank?
          message = "Info: line #{num} Schedule number retained at #{new_schedule_number}.<br>" if info_messages
          record[:info_messages] += message if info_messages
        elsif messagea == 'blank' && record[:house_or_street_name] == '-' && house_number.blank?
          message = "Info: line #{num} Schedule number retained at #{new_schedule_number}.<br>" if info_messages
          record[:info_messages] += message if info_messages
        elsif messagea == 'blank' && record[:house_or_street_name].present?
          messagea = "ERROR: line #{num} Schedule number is blank and there is an address.<br>"
          message += messagea
          record[:error_messages] += messagea
        elsif messagea == 'blank' && record[:year] == '1841'

        elsif messagea == 'blank' && record[:uninhabited_flag] == 'x'

        elsif messagea == 'blank'
          messagea = "ERROR: line #{num} Schedule number is blank and not a page transition.<br>"
          message += messagea
          record[:error_messages] += messagea
        else
          messagea = "ERROR: line #{num} Schedule number #{record[:schedule_number]} is #{messagea}.<br>"
          message += messagea
          record[:error_messages] += messagea
        end
      elsif schedule_number.to_i > 0 && record[:year] == '1841'
        message = "Error: line #{num} Schedule number #{record[:schedule_number]} present for 1841 census.<br>"
        record[:error_messages] += message
      elsif (schedule_number.to_i > (previous_schedule_number.to_i + 1)) && previous_schedule_number.to_i != 0
        if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
          message = "Warning: line #{num} Schedule number #{record[:schedule_number]} increments more than 1 .<br>"
          record[:warning_messages] += message
        end
      elsif (schedule_number.to_i < previous_schedule_number.to_i) && schedule_number.to_i != 0
        if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
          message = "Warning: line #{num} Schedule number #{record[:schedule_number]} is less than the previous one .<br>"
          record[:warning_messages] += message
        end
      end

      success, messagea = FreecenValidations.house_number?(house_number)
      unless success
        messageb = "ERROR: line #{num} House number #{house_number} is #{messagea}.<br>"
        message += messageb
        record[:error_messages] += messageb
      end

      success, messagea = FreecenValidations.text?(record[:house_or_street_name])
      unless success
        if messagea == '?'
          messagea = "Warning: line #{num} House address #{record[:house_or_street_name]}  has trailing ?. Removed and address_flag set.<br>"
          message += messagea
          record[:warning_messages] += messagea
          record[:address_flag] = 'x'
          record[:house_or_street_name] = record[:house_or_street_name][0...-1].strip
        elsif messagea == 'blank'
        else
          messageb = "ERROR: line #{num} House address #{record[:house_or_street_name]} is #{messagea}.<br>"
          message += messageb
          record[:error_messages] += messageb
        end
      end

      success, messagea = FreecenValidations.address_flag?(record[:address_flag])
      if !success
        messageb = "ERROR: line #{num} Address flag #{record[:address_flag]} is #{messagea}.<br>"
        message += messageb
        record[:error_messages] += messageb
      elsif record[:address_flag].present?
        messagea = "Warning: line #{num} Address Flag is #{record[:address_flag]}.<br>"
        record[:warning_messages] += messagea
        message += messagea
      end

      success, messagea = FreecenValidations.uninhabited_flag?(uninhabited_flag)
      unless success
        messageb = "ERROR: line #{num} Uninhabited Flag #{uninhabited_flag} is #{messagea}.<br>"
        message += messageb
        record[:error_messages] += messageb
      else
        if %w[u b n v].include?(uninhabited_flag) && schedule_number.blank?
          messageb = "ERROR: line #{num} has special #{uninhabited_flag} but no schedule number.<br>"
          message += messageb
          record[:error_messages] += messageb
        end
        if uninhabited_flag == 'x'
          record[:address_flag] = 'x'
          record[:uninhabited_flag] = ''
          messageb = "Warning: line #{num} uninhabited_flag of x is moved to address flag.<br>"
          message += messageb
          record[:warning_messages] += messageb
        end
      end

      unless %w[b n u v].include?(uninhabited_flag)
        if record[:walls].present?
          if %w[1901 1911].include?(record[:year])
            success, messagea = FreecenValidations.walls?(record[:walls])
            unless success
              messageb = "ERROR: line #{num} Number of walls #{record[:walls]} is #{messagea}.<br>"
              message += messageb
              record[:error_messages] += messageb
            end
          else
            messageb = "ERROR: line #{num} Number of walls #{record[:walls]} should not be included for #{record[:year]}.<br>"
            message += messageb
            record[:error_messages] += messageb
          end
        end

        if record[:roof_type].present?
          if %w[1901 1911].include?(record[:year])
            success, messagea = FreecenValidations.roof_type?(record[:roof_type])
            unless success
              messageb = "ERROR: line #{num} Roof type #{record[:roof_type]} is #{messagea}.<br>"
              message += messageb
              record[:error_messages] += messageb
            end
          else
            messageb = "ERROR: line #{num} Roof type #{record[:roof_type]} should not be included for #{record[:year]}.<br>"
            message += messageb
            record[:error_messages] += messageb
          end
        end

        if record[:rooms].present?
          if %w[1891 1901 1911].include?(record[:year])
            success, messagea = FreecenValidations.rooms?(record[:rooms], record[:year])
            unless success
              messageb = "ERROR: line #{num} Rooms #{record[:rooms]} is #{messagea}.<br>"
              message += messageb
              record[:error_messages] += messageb
            else
              if %w[1891 1901].include?(record[:year]) && record[:rooms].to_i > 5
                messageb = "Warning: line #{num} Rooms #{record[:rooms]} is greater than 5.<br>"
                message += messageb   if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
                record[:warning_messages] += messageb  if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
              elsif record[:year] == '1911' && record[:rooms].to_i > 20
                messageb = "Warning: line #{num} Rooms #{record[:rooms]} is greater than 20.<br>"
                message += messageb   if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
                record[:warning_messages] += messageb  if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
              end
            end
          else
            messageb = "ERROR: line #{num} Rooms #{record[:rooms]}} should not be included for #{record[:year]}.<br>"
            message += messageb
            record[:error_messages] += messageb
          end
        end

        if record[:rooms_with_windows].present?
          if %w[1861 1871 1881 1891 1901 1911].include?(record[:year])
            success, messagea = FreecenValidations.rooms_with_windows?(record[:rooms_with_windows])
            unless success
              messageb = "ERROR: line #{num} Rooms with windows #{record[:rooms_with_windows]} is #{messagea}.<br>"
              message += messageb
              record[:error_messages] += messageb
            end
          else
            messageb = "ERROR: line #{num} Rooms with windows #{record[:rooms_with_windows]} should not be included for #{record[:year]}.<br>"
            message += messageb
            record[:error_messages] += messageb
          end
        end

        if record[:class_of_house].present?
          if %w[1901 1911].include?(record[:year])
            success, messagea = FreecenValidations.class_of_house?(record[:class_of_house])
            unless success
              messageb = "ERROR: line #{num} Class of house #{record[:class_of_house]} is #{messagea}.<br>"
              message += messageb
              record[:error_messages] += messageb
            end
          else
            messageb = "ERROR: line #{num} Class of house #{record[:class_of_house]}  should not be included for #{record[:year]}.<br>"
            message += messageb
            record[:error_messages] += messageb
          end
        end
      end
      [message, new_schedule_number, new_schedule_suffix]
    end

    def validate_individual(record)
      # p 'validate_individual'
      num = record[:record_number]
      info_messages = record[:messages]
      return [true, ''] if %w[b n u v].include?(record[:uninhabited_flag])

      message = ''
      success, messagea = FreecenValidations.surname?(record[:surname])
      if success
        if record[:surname].present? && record[:surname].strip == '-'
          messageb = "Warning: line #{num} has single - Hyphen in Surname.<br>"
          message += messageb if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
          record[:warning_messages] += messageb if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
        end

      else
        if messagea == '?'
          messageb = "Warning: line #{num} Surname  #{record[:surname]} has trailing ?. Removed and flag set.<br>"
          message += messageb
          record[:warning_messages] += messageb
          record[:name_flag] = 'x'
          record[:surname] = record[:surname][0...-1].strip
        else
          messageb = "ERROR: line #{num} Surname #{record[:surname]} is #{messagea}.<br>"
          message += messageb
          record[:error_messages] += messageb
        end
      end

      success, messagea = FreecenValidations.forenames?(record[:forenames])
      if success
        if record[:forenames].present? && record[:forenames].strip == '-'
          messageb = "Warning: line #{num} has single - Hyphen in Forename.<br>"
          message += messageb if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
          record[:warning_messages] += messageb if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
        end
      else
        if messagea == '?'
          messageb = "Warning: line #{num} Forenames  #{record[:forenames]} has trailing ?. Removed and flag set.<br>"
          message += messageb
          record[:warning_messages] += messageb
          record[:name_flag] = 'x'
          record[:forenames] = record[:forenames][0...-1].strip
        else
          messageb = "ERROR: line #{num} Forenames #{record[:forenames]} is #{messagea}.<br>"
          message += messageb
          record[:error_messages] += messageb
        end
      end

      success, messagea = FreecenValidations.name_question?(record[:name_flag])
      if !success
        messageb = "ERROR: line #{num} Name Flag #{record[:name_flag]} is #{messagea}.<br>"
        message += messageb
        record[:error_messages] += messageb
      elsif record[:name_flag].present?
        messagea = "Warning: line #{num} Name Flag is #{record[:name_flag]}.<br>"
        record[:warning_messages] += messagea
        message += messagea
      end

      unless record[:year] == '1841'
        success, messagea = FreecenValidations.relationship?(record[:relationship])
        unless success
          if messagea == '?'
            messageb = "Warning: line #{num} Relationship  #{record[:relationship]} has trailing ?. Removed and flag set.<br>"
            message += messageb
            record[:warning_messages] += messageb
            record[:individual_flag] = 'x'
            record[:relationship] = record[:relationship][0...-1].strip
          else
            messageb = "ERROR: line #{num} Relationship #{record[:relationship]} is #{messagea}.<br>"
            message += messageb
            record[:error_messages] += messageb
          end

        end
        if record[:relationship].present? && record[:relationship].casecmp('head').zero? && record[:sequence_in_household].to_i != 1
          messageb = "Warning: line #{num} Relationship #{record[:relationship]} is #{record[:sequence_in_household]} in household sequence.<br>"
          message += messageb  if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
          record[:warning_messages] += messageb  if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
        end
      end

      unless record[:year] == '1841'
        success, messagea = FreecenValidations.marital_status?(record[:marital_status])
        unless success
          if messagea == '?'
            messageb = "Warning: line #{num} Marital Status  #{record[:marital_status]} has trailing ?. Removed and flag set.<br>"
            message += messageb
            record[:warning_messages] += messageb
            record[:individual_flag] = 'x'
            record[:marital_status] = record[:marital_status][0...-1].strip
          else
            messageb = "ERROR: line #{num} Marital status #{record[:marital_status]} is #{messagea}.<br>"
            message += messageb
            record[:error_messages] += messageb
          end
        end
      end

      success, messagea = FreecenValidations.sex?(record[:sex])
      unless success
        if messagea == '?'
          messageb = "Warning: line #{num} Sex  #{record[:sex]} has trailing ?. Removed and flag set.<br>"
          message += messageb
          record[:warning_messages] += messageb
          record[:individual_flag] = 'x'
          record[:sex] = record[:sex][0...-1].strip
        else
          messageb = "ERROR: line #{num} Sex #{record[:sex]} is #{messagea}.<br>"
          message += messageb
          record[:error_messages] += messageb
        end
      end

      success, messagea = FreecenValidations.age?(record[:age], record[:marital_status], record[:sex])
      unless success
        if messagea == '?'
          messageb = "Warning: line #{num} Age  #{record[:age]} has trailing ?. Removed and flag set.<br>"
          message += messageb
          record[:warning_messages] += messageb
          record[:individual_flag] = 'x'
          record[:age] = record[:age][0...-1].strip
          success, messagea = FreecenValidations.age?(record[:age], record[:marital_status], record[:sex])
          unless success
            messageb = "ERROR: line #{num} Age #{record[:age]} is #{messagea}.<br>"
            message += messageb
            record[:error_messages] += messageb
          end
        elsif messagea == 'Unusual Age 999'
          messageb = "Warning: line #{num} Age #{record[:age]} looks unusual.<br>"
          message += messageb  if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
          record[:warning_messages] += messageb  if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
        else
          messageb = "ERROR: line #{num} Age #{record[:age]} is #{messagea}.<br>"
          message += messageb
          record[:error_messages] += messageb
        end
      end

      if record[:school_children].present?
        if %w[1861 1871].include?(record[:year])
          success, messagea = FreecenValidations.school_children?(record[:school_children])
          unless success
            if messagea == 'invalid number'
              messageb = "ERROR: line #{num} Number of school children #{record[:school_children]} is #{messagea}.<br>"
              message += messageb
              record[:error_messages] += messageb
            else
              messageb = "Warning: line #{num} Number of school children #{record[:school_children]} is #{messagea}.<br>"
              message += messageb  if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
              record[:warning_messages] += messageb  if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
            end
          end
        else
          messageb = "ERROR: line #{num} Number of school children #{record[:school_children]} should not be included for #{record[:year]}.<br>"
          message += messageb
          record[:error_messages] += messageb
        end
      end

      if record[:years_married].present?
        if %w[1911].include?(record[:year])
          success, messagea = FreecenValidations.years_married?(record[:years_married])
          unless success
            if messagea == '?'
              messageb = "Warning: line #{num} Years Married #{record[:years_married]} has trailing ?. Removed and flag set.<br>"
              message += messageb
              record[:warning_messages] += messageb
              record[:individual_flag] = 'x'
              record[:years_married] = record[:years_married][0...-1].strip
              success, messagea = FreecenValidations.years_married?(record[:age], record[:years_married])
              unless success
                messageb = "ERROR: line #{num} Years Married  #{record[:years_married]} is #{messagea}.<br>"
                message += messageb
                record[:error_messages] += messageb
              end
            else
              messageb = "ERROR: line #{num} Years Married  #{record[:years_married]} is #{messagea}.<br>"
              message += messageb
              record[:error_messages] += messageb
            end
          end
        else
          messageb = "ERROR: line #{num} Years married #{record[:years_married]} should not be included for #{record[:year]}.<br>"
          message += messageb
          record[:error_messages] += messageb
        end
      end

      if record[:children_living].present?
        if %w[1911].include?(record[:year])
          success, messagea = FreecenValidations.children_living?(record[:children_living])
          unless success
            if messagea == 'invalid number'
              messageb = "ERROR: line #{num} Number of children living #{record[:children_living]} is #{messagea}.<br>"
              message += messageb
              record[:error_messages] += messageb
            else
              messageb = "Warning: line #{num} Number of children living #{record[:children_living]} is #{messagea}.<br>"
              message += messageb  if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
              record[:warning_messages] += messageb  if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
            end
          end
        else
          messageb = "ERROR: line #{num} Number of children living #{record[:children_living]} should not be included for #{record[:year]}.<br>"
          message += messageb
          record[:error_messages] += messageb
        end
      end

      if record[:children_deceased].present?
        if %w[1911].include?(record[:year])
          success, messagea = FreecenValidations.children_deceased?(record[:children_deceased])
          unless success
            if messagea == 'invalid number'
              messageb = "ERROR: line #{num} Number of children deceased #{record[:children_deceased]} is #{messagea}.<br>"
              message += messageb
              record[:error_messages] += messageb
            else
              messageb = "Warning: line #{num} Number of children deceased #{record[:children_deceased]} is #{messagea}.<br>"
              message += messageb  if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
              record[:warning_messages] += messageb  if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
            end
          end
        else
          messageb = "ERROR: line #{num} Number of children deceased #{record[:children_deceased]} should not be included for #{record[:year]}.<br>"
          message += messageb
          record[:error_messages] += messageb
        end
      end

      if record[:children_born_alive].present?
        if %w[1911].include?(record[:year])
          success, messagea = FreecenValidations.children_born_alive?(record[:children_born_alive])
          unless success
            if messagea == 'invalid number'
              messageb = "ERROR: line #{num} Number of children born alive #{record[:children_born_alive]} is #{messagea}.<br>"
              message += messageb
              record[:error_messages] += messageb
            else
              messageb = "Warning: line #{num} Number of children born alive #{record[:children_born_alive]} is #{messagea}.<br>"
              message += messageb  if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
              record[:warning_messages] += messageb  if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
            end
          end
        else
          messageb = "ERROR: line #{num} Number of children born alive #{record[:children_born_alive]} should not be included for #{record[:year]}.<br>"
          message += messageb
          record[:error_messages] += messageb
        end
      end

      if record[:religion].present?
        if %w[1901 1911].include?(record[:year])
          success, messagea = FreecenValidations.religion?(record[:religion])
          unless success
            messageb = "ERROR: line #{num} Religion #{record[:religion]} is #{messagea}.<br>"
            message += messageb
            record[:error_messages] += messageb
          end
        else
          messageb = "ERROR: line #{num} Religion #{record[:religion]} should not be included for #{record[:year]}.<br>"
          message += messageb
          record[:error_messages] += messageb
        end
      end

      if record[:read_write].present?
        if %w[1901 1911].include?(record[:year])
          success, messagea = FreecenValidations.read_write?(record[:read_write])
          unless success
            messageb = "ERROR: line #{num} Ability to read and write #{record[:read_write]} is #{messagea}.<br>"
            message += messageb
            record[:error_messages] += messageb
          end
        else
          messageb = "ERROR: line #{num} Ability to read and write #{record[:read_write]} should not be included for #{record[:year]}.<br>"
          message += messageb
          record[:error_messages] += messageb
        end
      end

      success, messagea = FreecenValidations.uncertainty_status?(record[:individual_flag])
      if !success
        messageb = "ERROR: line #{num} Individual Flag #{record[:individual_flag]} is #{messagea}.<br>"
        message += messageb
        record[:error_messages] += messageb
      elsif record[:individual_flag].present?
        messagea = "Warning: line #{num} Individual Flag is #{record[:individual_flag]}.<br>"
        record[:warning_messages] += messagea
        message += messagea
      end

      success, messagea = FreecenValidations.occupation?(record[:occupation], record[:age])
      unless success
        if messagea == '?'
          messageb = "Warning: line #{num} Occupation #{record[:occupation]} has trailing ?. Removed and flag set.<br>"
          message += messageb
          record[:warning_messages] += messageb
          record[:occupation_flag] = 'x'
          record[:occupation] = record[:occupation][0...-1].strip
        elsif messagea == 'unusual use of Scholar'
          messageb = "Warning: line #{num} Occupation #{record[:occupation]} is #{messagea}. Aged #{record[:age]}.<br>"
          message += messageb  if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
          record[:warning_messages] += messageb  if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
        else
          messageb = "ERROR: line #{num} Occupation #{record[:occupation]} is #{messagea}.<br>"
          message += messageb
          record[:error_messages] += messageb
        end
      end

      if record[:industry].present?
        if %w[1911].include?(record[:year])
          success, messagea = FreecenValidations.industry?(record[:industry])
          unless success
            if messagea == '?'
              messageb = "Warning: line #{num} Industry  #{record[:sex]} has trailing ?. Removed and flag set.<br>"
              message += messageb
              record[:warning_messages] += messageb
              record[:occupation_flag] = 'x'
              record[:industry] = record[:industry][0...-1].strip
            else
              messageb = "ERROR: line #{num} Industry #{record[:industry]} is #{messagea}.<br>"
              message += messageb
              record[:error_messages] += messageb
            end
          end
        else
          messageb = "ERROR: line #{num} Industry #{record[:industry]} should not be included for #{record[:year]}.<br>"
          message += messageb
          record[:error_messages] += messageb
        end
      end

      if record[:occupation_category].present?
        if %w[1891 1901 1911].include?(record[:year])
          record[:occupation_category] = record[:occupation_category].upcase if record[:occupation_category].present?
          success, messagea = FreecenValidations.occupation_category?(record[:occupation_category])

          unless success
            messageb = "ERROR: line #{num} Occupation category #{record[:occupation_category]} is #{messagea}.<br>"
            message += messageb
            record[:error_messages] += messageb
          end
        else
          messageb = "ERROR: line #{num} Occupation category #{record[:occupation_category]} should not be included for #{record[:year]}.<br>"
          message += messageb
          record[:error_messages] += messageb
        end
      end

      if record[:at_home].present?
        if %w[1901 1911].include?(record[:year])
          success, messagea = FreecenValidations.at_home?(record[:at_home])
          unless success
            messageb = "ERROR: line #{num} Working at home #{record[:at_home]} is #{messagea}.<br>"
            message += messageb
            record[:error_messages] += messageb
          end
        else
          messageb = "ERROR: line #{num} Working at home #{record[:at_home]} should not be included for #{record[:year]}.<br>"
          message += messageb
          record[:error_messages] += messageb
        end
      end

      success, messagea = FreecenValidations.uncertainty_occupation?(record[:occupation_flag])
      if !success
        messageb = "ERROR: line #{num} Occupation Flag #{record[:occupation_flag]} is #{messagea}.<br>"
        message += messageb
        record[:error_messages] += messageb
      elsif record[:occupation_flag].present?
        messagea = "Warning: line #{num} Occupation Flag is #{record[:occupation_flag]}.<br>"
        record[:warning_messages] += messagea
        message += messagea
      end
      record[:verbatim_birth_county] = record[:verbatim_birth_county].upcase if record[:verbatim_birth_county].present?
      success, messagea = FreecenValidations.verbatim_birth_county?(record[:verbatim_birth_county])
      valid_verbatim_chapman_code = true
      unless success
        messageb = "ERROR: line #{num} Verbatim Birth County #{record[:verbatim_birth_county]} is #{messagea}.<br>"
        valid_verbatim_chapman_code = false
        message += messageb
        record[:error_messages] += messageb
      end
      if record[:verbatim_birth_county] == 'OUC' && record[:year] != '1841'
        messageb = "ERROR: line #{num} Verbatim Birth County #{record[:verbatim_birth_county]} is only used in 1841.<br>"
        valid_verbatim_chapman_code = false
        message += messageb
        record[:error_messages] += messageb
      end

      if record[:year] == '1841'
        if record[:verbatim_birth_place].present? && record[:verbatim_birth_place] != '-'
          messageb = "ERROR: line #{num} Verbatim Birth Place #{record[:verbatim_birth_place]} should not be included for #{record[:year]}.<br>"
          message += messageb
          record[:error_messages] += messageb
        end
      else
        success, messagea = FreecenValidations.verbatim_birth_place?(record[:verbatim_birth_place])
        unless success
          if messagea == '?'
            messageb = "Warning: line #{num} Verbatim Birth Place  #{record[:verbatim_birth_place]} has trailing ?. Removed and flag set.<br>"
            message += messageb
            record[:warning_messages] += messageb
            record[:uncertainy_birth] = 'x'
            record[:verbatim_birth_place] = record[:verbatim_birth_place][0...-1].strip
          else
            messageb = "ERROR: line #{num} Verbatim Birth Place #{record[:verbatim_birth_place]} is #{messagea}.<br>"
            message += messageb
            record[:error_messages] += messageb
          end
        end

        # db.freecen2_places.find({"alternate_freecen2_place_names.alternate_name" : {$eq: "Brompton"}})
        # db.freecen2_places.find({chapman_code: "SOM", "alternate_freecen2_place_names.alternate_name" : {$eq: "Brompton"}})
        place_valid = false
        if record[:verbatim_birth_place] == '-' && valid_verbatim_chapman_code
          place_valid = true
        elsif record[:verbatim_birth_county].present? && valid_verbatim_chapman_code && record[:verbatim_birth_place].present?
          place_valid = Freecen2Place.valid_place_name?(record[:verbatim_birth_county], record[:verbatim_birth_place])
        end
        unless place_valid
          messageb = "Warning: line #{num} Verbatim Place of Birth #{record[:verbatim_birth_place]} in #{record[:verbatim_birth_county]} was not found so requires validation.<br>"
          if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
            message += messageb
            record[:warning_messages] += messageb
          end
        end
      end
      if record[:nationality].present?
        unless %w[1841].include?(record[:year])
          success, messagea = FreecenValidations.nationality?(record[:nationality])
          unless success
            if messagea == '?'
              messageb = "Warning: line #{num} Nationality #{record[:nationality]} has trailing ?. Removed and flag set.<br>"
              message += messageb
              record[:warning_messages] += messageb
              record[:uncertainy_birth] = 'x'
              record[:nationality] = record[:nationality][0...-1].strip
            else
              messageb = "ERROR: line #{num} Nationality #{record[:nationality]} is #{messagea}.<br>"
              message += messageb
              record[:error_messages] += messageb
            end
          end
        else
          messageb = "ERROR: line #{num} Nationality #{record[:nationality]} should not be included for #{record[:year]}.<br>"
          message += messageb
          record[:error_messages] += messageb
        end
      end

      record[:birth_county] = record[:birth_county].upcase if record[:birth_county].present?
      success, messagea = FreecenValidations.verbatim_birth_county?(record[:birth_county])
      valid_alternate_chapman_code = true
      unless success || messagea == 'blank'
        messageb = "ERROR: line #{num} Alt. Birth County #{record[:birth_county]} is #{messagea}.<br>"
        valid_alternate_chapman_code = false
        message += messageb
        record[:error_messages] += messageb
      end
      if record[:birth_county] == 'OUC' && record[:year] != '1841'
        messageb = "ERROR: line #{num} Alt. Birth County #{record[:birth_county]} is only used in 1841.<br>"
        valid_alternate_chapman_code = false
        message += messageb
        record[:error_messages] += messageb
      end

      if record[:year] == '1841'
        if record[:birth_place].present?
          messageb = "ERROR: line #{num} Alt.Birth Place #{record[:birth_place]} should not be included for #{record[:year]}.<br>"
          message += messageb
          record[:error_messages] += messageb
        end
      else
        success, messagea = FreecenValidations.verbatim_birth_place?(record[:birth_place])
        unless success || messagea == 'blank'
          if messagea == '?'
            messageb = "Warning: line #{num} Alt. Birth Place  #{record[:birth_place]} has trailing ?. Removed and flag set.<br>"
            message += messageb
            record[:warning_messages] += messageb
            record[:uncertainy_birth] = 'x'
            record[:birth_place] = record[:birth_place][0...-1].strip
          else
            messageb = "ERROR: line #{num} Alt. Birth Place #{record[:birth_place]} is #{messagea}.<br>"
            message += messageb
            record[:error_messages] += messageb
          end
        end

        # db.freecen2_places.find({"alternate_freecen2_place_names.alternate_name" : {$eq: "Brompton"}})
        # db.freecen2_places.find({chapman_code: "SOM", "alternate_freecen2_place_names.alternate_name" : {$eq: "Brompton"}})
        place_valid = false
        if record[:birth_place] == '-' && record[:birth_county].present? && valid_alternate_chapman_code
          place_valid = true
        elsif record[:birth_county].present? && valid_alternate_chapman_code && record[:birth_place].present?
          place_valid = Freecen2Place.valid_place_name?(record[:birth_county], record[:birth_place])
        end

        if (record[:birth_county].present? && valid_alternate_chapman_code && record[:birth_place].blank?) || (record[:birth_county].blank? && record[:birth_place].present?)
          messageb = "ERROR: line #{num} only one of Alt. Birth County #{record[:birth_county]} and Alt. Birth Place #{record[:birth_place]} is set.<br>"
          message += messageb
          record[:error_messages] += messageb
        end

        if record[:birth_county].present? && valid_alternate_chapman_code && record[:birth_place].present? && place_valid
          messageb = "Warning: line #{num} Alt. Birth Place #{record[:birth_place]} in #{record[:birth_county]} found but MAY require validation.<br>"
          message += messageb   if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
          record[:warning_messages] += messageb  if (record[:record_valid].blank? || record[:record_valid].casecmp?('false'))
        end

        if record[:birth_county].present? && valid_alternate_chapman_code && record[:birth_place].present? && !place_valid
          messageb = "Warning: line #{num} Alt. Birth Place #{record[:birth_place]} in #{record[:birth_county]} not found so requires validation.<br>"
          message += messageb  if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
          record[:warning_messages] += messageb if (record[:record_valid].blank? || record[:record_valid].casecmp?('false'))
        end
      end

      if record[:father_place_of_birth].present?
        if record[:year] == '1911'
          success, messagea = FreecenValidations.verbatim_birth_place?(record[:father_place_of_birth])
          unless success
            if messagea == '?'
              messageb = "Warning: line #{num} Father's place of birth #{record[:father_place_of_birth]} has trailing ?. Removed and flag set.<br>"
              message += messageb
              record[:warning_messages] += messageb
              record[:uncertainy_birth] = 'x'
              record[:father_place_of_birth] = record[:father_place_of_birth][0...-1].strip
            else
              messageb = "ERROR: line #{num} Father's place of birth #{record[:father_place_of_birth]} is #{messagea}.<br>"
              message += messageb
              record[:error_messages] += messageb
            end
          end
        else
          messageb = "ERROR: line #{num} Father's place of birth #{record[:father_place_of_birth]} should not be included for #{record[:year]}.<br>"
          message += messageb
          record[:error_messages] += messageb
        end
      end

      success, messagea = FreecenValidations.uncertainy_birth?(record[:birth_place_flag])
      if !success
        messageb = "ERROR: line #{num} Birth Place Flag #{record[:birth_place_flag]} is #{messagea}.<br>"
        message += messageb
        record[:error_messages] += messageb
      elsif record[:birth_place_flag].present?
        messagea = "Warning: line #{num} Birth Place Flag is #{record[:birth_place_flag]}.<br>"
        record[:warning_messages] += messagea
        message += messagea
      end

      if record[:year] == '1841'
        if record[:disability].present?
          messageb = "ERROR: line #{num} Disability #{record[:disability]} should not be included for #{record[:year]}.<br>"
          message += messageb
          record[:error_messages] += messageb
        end
      else
        success, messagea = FreecenValidations.disability?(record[:disability])

        unless success
          if messagea == '?'
            messageb = "Warning: line #{num} Disability #{record[:disability]} has trailing ?. Comment added to Notes.<br>"
            message += messageb
            record[:warning_messages] += messageb
            record[:notes] = record[:notes].present? ? record[:notes] + ' Disability ?' : 'Disability ?'
            record[:disability] = record[:disability][0...-1].strip
          else
            messageb = "ERROR: line #{num} Disability #{record[:disability]} is #{messagea}.<br>"
            message += messageb
            record[:error_messages] += messageb
          end
        end
      end

      if record[:disability_notes].present?
        if record[:year] == '1911'
          success, messagea = FreecenValidations.disability_notes?(record[:disability_notes])
          unless success
            if messagea == '?'
              messageb = "Warning: line #{num} Disability Notes #{record[:disability]} has trailing ?. Comment added to Notes.<br>"
              message += messageb
              record[:warning_messages] += messageb
              record[:notes] = record[:notes].present? ? record[:notes] + ' Disability Notes?' : 'Disability Notes?'
              record[:disability_notes] = record[:disability_notes][0...-1].strip
            else
              messageb = "ERROR: line #{num} Disability Notes #{record[:disability_notes]} is #{messagea}.<br>"
              message += messageb
              record[:error_messages] += messageb
            end
          end
        else
          messageb = "ERROR: line #{num} Disability Notes #{record[:disability_notes]} should not be included for #{record[:year]}.<br>"
          message += messageb
          record[:error_messages] += messageb
        end
      end

      if record[:language].present?
        if %w[1881 1891 1901 1911].include?(record[:year])
          success, messagea = FreecenValidations.language?(record[:language])
          unless success
            messageb = "ERROR: line #{num} Language #{record[:language]} is #{messagea}.<br>"
            message += messageb
            record[:error_messages] += messageb
          end
        else
          messageb = "Warning: line #{num} Language #{record[:language]} should not be included for #{record[:year]}.<br>"
          message += messageb
          record[:error_messages] += messageb
        end
      end
      [message]
    end

    def validate_notes(record)
      num = record[:record_number]
      success, messagea = FreecenValidations.notes?(record[:notes])
      message = ''
      if !success
        messageb = "ERROR: line #{num} Notes #{record[:notes]} is #{messagea}.<br>"
        message += messageb
        record[:error_messages] += messageb
      elsif record[:notes].present?
        messagea = "Warning: line #{num} Notes contains information #{record[:notes]}.<br>"
        record[:warning_messages] += messagea  if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
        message += messagea if record[:record_valid].blank? || record[:record_valid].casecmp?('false')
      end
      [message]
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

  def add_address(freecen_csv_file_id, dwelling)
    first_individual = FreecenCsvEntry.find_by(freecen_csv_file_id: freecen_csv_file_id, dwelling_number: dwelling)
    if first_individual.present?
      self.folio_number = first_individual.folio_number
      self.page_number = first_individual.page_number
      self.dwelling_number = first_individual.dwelling_number
      self.schedule_number = first_individual.schedule_number
      self.house_number = first_individual.house_number
      self.house_or_street_name = first_individual.house_or_street_name
      self.walls = first_individual.walls
      self.roof_type = first_individual.roof_type
      self.rooms = first_individual.rooms
      self.rooms_with_windows = first_individual.rooms_with_windows
      self.class_of_house = first_individual.class_of_house
    end
  end

  def add_digest
    record_digest = cal_digest
  end

  def adjust_parameters(param)
    param[:year] = get_year(param, year)
    param[:processed_date] = Time.now
    param
  end

  def are_there_messages
    errors = error_messages.present? ? true : false
    warnings = warning_messages.present? ? true : false
    [warnings, errors]
  end

  def check_valid
    new_record_valid = error_messages.present? || warning_messages.present? ? 'false' : 'true'
    update_attributes(record_valid: new_record_valid) unless new_record_valid == record_valid
  end

  def display_fields(search_record)
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
    pc_id = freecen2_piece_id
    if idx && idx >= 0
      prev_dwel = FreecenDwelling.where(freecen2_piece_id: pc_id, dwelling_number: (idx - 1)).first
      prev_id = prev_dwel[:_id] unless prev_dwel.nil?
      next_dwel = FreecenDwelling.where(freecen2_piece_id: pc_id, dwelling_number: (idx + 1)).first
      next_id = next_dwel[:_id] unless next_dwel.nil?
    end
    [prev_id, next_id]
  end

  def propagate?(parameters)
    return false if freecen_csv_file.incorporated

    return false unless freecen_csv_file.validation

    return true if parameters[:birth_county].present? && parameters[:birth_county] != birth_county

    return true if parameters[:birth_place].present? && parameters[:birth_place] != birth_place

    return true if birth_county != verbatim_birth_county || birth_place != verbatim_birth_place

    false
  end

  def propagate_note?(parameters)
    return false if freecen_csv_file.incorporated

    return false unless freecen_csv_file.validation

    return true if parameters[:notes].present? && parameters[:notes] != notes

    return true if notes.present?

    false
  end

  def propagate_alternate(scope, userid)
    message = ''
    @warnings_adjustment = 0
    success = true
    if scope == 'ED'
      FreecenCsvEntry.where(freecen_csv_file_id: freecen_csv_file_id, enumeration_district: enumeration_district, verbatim_birth_county: verbatim_birth_county, verbatim_birth_place: verbatim_birth_place).no_timeout.each do |entry|
        next if entry.id == _id

        adjustment, updated_warnings = remove_pob_warning_messages(entry.warning_messages)
        updated_record_valid = updated_warnings.present? || entry.error_messages.present? ? 'false' : 'true'
        @warnings_adjustment += adjustment
        entry.update_attributes(birth_county: birth_county, birth_place: birth_place, warning_messages: updated_warnings, record_valid: updated_record_valid)
      end
    else
      FreecenCsvEntry.where(freecen_csv_file_id: freecen_csv_file_id, verbatim_birth_county: verbatim_birth_county, verbatim_birth_place: verbatim_birth_place).no_timeout.each do |entry|
        next if entry.id == _id

        adjustment, updated_warnings = remove_pob_warning_messages(entry.warning_messages)
        updated_record_valid = updated_warnings.present? || entry.error_messages.present? ? 'false' : 'true'
        @warnings_adjustment += adjustment
        entry.update_attributes(birth_county: birth_county, birth_place: birth_place, warning_messages: updated_warnings, record_valid: updated_record_valid)
      end
    end
    if scope == 'All'
      propagate_pob, propagate_notes = propagation_flags('Alternative')
      ok = FreecenPobPropagation.create_new_propagation('ALL', 'ALL', verbatim_birth_county, verbatim_birth_place, birth_county, birth_place, notes, propagate_pob, propagate_notes, userid)
      message = ok ? '' : 'Propagation successful for File but please note Propagation record for Collection already exists.'
    end
    [@warnings_adjustment, success, message]
  end

  def propagate_note(scope, userid)
    message = ''
    success = true
    @warnings_adjustment = 0
    need_review_message = 'Warning: Notes field has been adjusted and needs review.<br>'
    if scope == 'ED'
      FreecenCsvEntry.where(freecen_csv_file_id: freecen_csv_file_id, enumeration_district: enumeration_district, verbatim_birth_county: verbatim_birth_county, verbatim_birth_place: verbatim_birth_place).no_timeout.each do |entry|
        next if entry.id == _id

        warning_message = entry.warning_messages + need_review_message
        add_notes = entry.notes.present? ? entry.notes + ' ' + notes : notes
        @warnings_adjustment += 1 if entry.warning_messages.blank?
        entry.update_attributes(notes: add_notes, warning_messages: warning_message)
      end
    else
      FreecenCsvEntry.where(freecen_csv_file_id: freecen_csv_file_id, verbatim_birth_county: verbatim_birth_county, verbatim_birth_place: verbatim_birth_place).no_timeout.each do |entry|
        next if entry.id == _id

        warning_message = entry.warning_messages + need_review_message
        add_notes = entry.notes.present? ? entry.notes + ' ' + notes : notes
        @warnings_adjustment += 1 if entry.warning_messages.blank?
        entry.update_attributes(notes: add_notes, warning_messages: warning_message)
      end
    end
    if scope == 'All'
      propagate_pob, propagate_notes = propagation_flags('Notes')
      ok = FreecenPobPropagation.create_new_propagation('ALL', 'ALL', verbatim_birth_county, verbatim_birth_place, birth_county, birth_place, notes, propagate_pob, propagate_notes, userid)
      message = ok ? '' : 'Propagation successful for File but please note Propagation record for Collection already exists.'
    end
    [@warnings_adjustment, success, message]
  end

  def propagate_both(scope, userid)
    message = ''
    @warnings_adjustment = 0
    success = true
    notes_need_review_message = 'Warning: Notes field has been adjusted and needs review.<br>'
    if scope == 'ED'
      FreecenCsvEntry.where(freecen_csv_file_id: freecen_csv_file_id, enumeration_district: enumeration_district, verbatim_birth_county: verbatim_birth_county, verbatim_birth_place: verbatim_birth_place).no_timeout.each do |entry|
        next if entry.id == _id

        _adjustment, updated_warnings = remove_pob_warning_messages(entry.warning_messages)
        new_warning_message = updated_warnings + notes_need_review_message
        add_notes = entry.notes.present? ? entry.notes + ' ' + notes : notes
        @warnings_adjustment += 1 if entry.warning_messages.blank?
        entry.update_attributes( birth_county: birth_county, birth_place: birth_place, notes: add_notes, warning_messages: new_warning_message)
      end
    else
      FreecenCsvEntry.where(freecen_csv_file_id: freecen_csv_file_id, verbatim_birth_county: verbatim_birth_county, verbatim_birth_place: verbatim_birth_place).no_timeout.each do |entry|
        next if entry.id == _id

        _adjustment, updated_warnings = remove_pob_warning_messages(entry.warning_messages)
        new_warning_message = updated_warnings + notes_need_review_message
        add_notes = entry.notes.present? ? entry.notes + ' ' + notes : notes
        @warnings_adjustment += 1 if entry.warning_messages.blank?
        entry.update_attributes( birth_county: birth_county, birth_place: birth_place, notes: add_notes, warning_messages: new_warning_message)
      end
    end
    if scope == 'All'
      propagate_pob, propagate_notes = propagation_flags('Both')
      ok = FreecenPobPropagation.create_new_propagation('ALL', 'ALL', verbatim_birth_county, verbatim_birth_place, birth_county, birth_place, notes, propagate_pob, propagate_notes, userid)
      message = ok ? '' : 'Propagation successful for File but Propagation record for Whole Collection not created as it already exists.'
    end
    [@warnings_adjustment, success, message]
  end

  def propagate_pob(fields, scope, userid)
    warnings_adjust = 0
    success = false
    case fields
    when 'Alternative'
      warnings_adjust, success, message = propagate_alternate(scope, userid)
    when 'Notes'
      warnings_adjust, success, message = propagate_note(scope, userid)
    when 'Both'
      warnings_adjust, success, message = propagate_both(scope, userid)
    else
      message = 'Invalid Propagation Field selection - please report to System Administrator'
    end
    [warnings_adjust, success, message]
  end

  def propagation_flags(propagation_fields)
    propagate_pob = %w[Alternative Both].include?(propagation_fields) ? true : false
    propagate_notes = %w[Notes Both].include?(propagation_fields) ? true : false
    [propagate_pob, propagate_notes]
  end

  def remove_pob_warning_messages(warnings)
    adjust_warnings = false
    warnings_adjustment = 0
    updated_warnings = ''
    warning_message_parts = warnings.split('<br>')
    warning_message_parts.each do |part|
      if part.include?('Warning:') && (part.include?('Birth') || part.include?('Alternate'))
        adjust_warnings = true
      else
        updated_warnings += part
      end
    end
    warnings_adjustment = -1 if adjust_warnings && updated_warnings.blank?
    [warnings_adjustment, updated_warnings]
  end

  def were_pob_notes_propagated(warnings)
    pob_propagated = false
    notes_propagated = false
    warning_message_parts = warnings.split('<br>')
    warning_message_parts.each do |part|
      if part.include?('Warning:') && part.include?('adjusted')
        pob_propagated = true if part.include?('Alternate')
        notes_propagated = true if part.include?('Notes')
      end
    end
    [pob_propagated, notes_propagated]
  end

  # labels/vals for dwelling page header section (body in freecen_individuals)
  def self.census_display_labels(year, chapman_code)
    # 1841 doesn't have ecclesiastical parish or schedule number
    # Scotland doesn't have folio
    case year
    when '1841'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Ecclesiastical Parish', 'Census Place', 'Piece', 'Constituency']
        # ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Quaord Sacra', 'Census Place', 'Piece', 'Enumeration District', 'Ward', 'Constituency'] #927
      else
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Where Census Taken', 'Piece',  'Constituency']
      end
    when '1851'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Ecclesiastical Parish', 'Census Place', 'Piece', 'Constituency']
        # ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Where Census Taken', 'Piece',  'Ward', 'Constituency'] #927
      else
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Ecclesiastical Parish', 'Census Place', 'Piece', 'Constituency']
      end
    when '1861'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Quaord Sacra', 'Where Census Taken', 'Piece', 'Ward', 'Constituency']
      else
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Ecclesiastical Parish', 'Where Census Taken', 'Piece', 'Ward', 'Constituency']
      end
    when '1871'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Quaord Sacra', 'Where Census Taken', 'Piece', 'Ward', 'Constituency', 'Police District']
      else
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Ecclesiastical Parish', 'Where Census Taken', 'Piece', 'Ward', 'Constituency']
      end
    when '1881'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Quaord Sacra', 'Where Census Taken', 'Piece', 'Ward', 'Constituency', 'Police District', 'School Board']
      else
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Ecclesiastical Parish', 'Where Census Taken', 'Piece', 'Ward', 'Constituency', 'Sanitary District']
      end
    when '1891'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Quaord Sacra', 'Where Census Taken', 'Piece', 'Ward', 'Constituency', 'Police District', 'School Board']
      else
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Ecclesiastical Parish', 'Where Census Taken', 'Piece', 'Ward', 'Constituency', 'Sanitary District']
      end
    when '1901'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Quaord Sacra', 'Where Census Taken', 'Piece', 'Ward', 'Constituency', 'Police District',  'School Board']
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Where Census Taken', 'Piece', 'Ward', 'Constituency', 'Poor Law Union', 'Police District']
      else
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Ecclesiastical Parish', 'Where Census Taken', 'Piece', 'Ward', 'Constituency']
      end
    when '1911'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Quaord Sacra', 'Where Census Taken', 'Piece', 'Ward', 'Constituency', 'Sanitary District', 'Scavenging District', 'Special Lighting District', 'School Board']
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Where Census Taken', 'Piece', 'Ward', 'Constituency', 'Poor Law Union', 'Police District']
      else
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Ecclesiastical Parish', 'Where Census Taken', 'Piece', 'Ward', 'Constituency']
      end
    end
  end

  def census_display_values(year, chapman_code)
    #1841 doesn't have ecclesiastical parish or schedule number
    #Scotland doesn't have folio
    freecen2_piece = freecen_csv_file.freecen2_piece
    district_name = freecen2_piece.district_name
    ecclesiastical = ecclesiastical_parish
    civil = civil_parish
    address = house_or_street_name
    disp_county = '' + ChapmanCode.name_from_code(chapman_code) + ' (' + chapman_code + ')' unless chapman_code.nil?
    taken = where_census_taken
    case year
    when '1841'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         parliamentary_constituency]
        # [freecen2_piece.year, disp_county, district_name, civil, enumeration_district, ecclesiastical, taken, freecen2_piece.number.to_s, #927
        #  ward, parliamentary_constituency] #927
      else
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, taken, freecen2_piece.number.to_s,
         parliamentary_constituency]
      end
    when '1851'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         parliamentary_constituency]
        # [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s, #927
        # ward, parliamentary_constituency] #927
      else
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         parliamentary_constituency]
      end
    when '1861'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency]
      else
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency]
      end
    when '1871'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency, police_district]
      else
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency]
      end
    when '1881'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency, police_district, school_board]
      else
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency, sanitary_district]
      end
    when '1891'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency, police_district, school_board]
      else
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency, sanitary_district]
      end
    when '1901'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency, police_district, school_board]
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency, poor_law_union, police_district]
      else
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency]
      end
    when '1911'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency, sanitary_district, scavenging_district, special_lighting_district, school_board]
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency, poor_law_union, police_district]
      else
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency]
      end
    end
  end

  def self.dwelling_display_labels(year, chapman_code)
    case year
    when '1841'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Folio', 'Page', 'Dwelling Number', 'Schedule', 'House Number', 'House or Street Name']
      else
        ['Folio', 'Page', 'Dwelling Number', 'House Number', 'House or Street Name']
      end
    when '1851'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Folio', 'Page', 'Dwelling Number', 'Schedule', 'House Number', 'House or Street Name']
      else
        ['Folio', 'Page', 'Dwelling Number', 'Schedule', 'House Number', 'House or Street Name']
      end
    when '1861'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Page', 'Dwelling Number', 'Schedule', 'House Number', 'House or Street Name', 'Rooms with Windows']
      else
        ['Folio', 'Page', 'Dwelling Number', 'Schedule', 'House Number', 'House or Street Name']
      end
    when '1871'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Page', 'Dwelling Number', 'Schedule', 'House Number', 'House or Street Name', 'Rooms with Windows']
      else
        ['Folio', 'Page', 'Dwelling Number', 'Schedule', 'House Number', 'House or Street Name']
      end
    when '1881'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Folio', 'Page', 'Dwelling Number', 'Schedule', 'House Number', 'House or Street Name', 'Rooms with Windows']
      else
        ['Folio', 'Page', 'Dwelling Number', 'Schedule', 'House Number', 'House or Street Name']
      end
    when '1891'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Folio', 'Page', 'Dwelling Number', 'Schedule', 'House Number', 'House or Street Name', 'Rooms with Windows']
      else
        ['Folio', 'Page', 'Dwelling Number', 'Schedule', 'House Number', 'House or Street Name', 'Rooms']
      end
    when '1901'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Folio', 'Page', 'Dwelling Number', 'Schedule', 'House Number', 'House or Street Name', 'Rooms with Windows']
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        ['Page', 'Dwelling Number', 'Schedule', 'House Number', 'House or Street Name', 'Walls', 'Roof Type', 'Rooms', 'Rooms with Windows', 'Class of House']
      else
        ['Folio', 'Page', 'Dwelling Number', 'Schedule', 'House Number', 'House or Street Name', 'Rooms']
      end
    when '1911'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Folio', 'Page', 'Dwelling Number', 'Schedule', 'House Number', 'House or Street Name', 'Rooms with Windows']
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        ['Page', 'Dwelling Number', 'Schedule', 'House Number', 'House or Street Name', 'Walls', 'Roof Type', 'Rooms', 'Rooms with Windows', 'Class of House']
      else
        ['Folio', 'Page', 'Dwelling Number', 'Schedule', 'House Number', 'House or Street Name', 'Rooms']
      end
    end
  end

  def dwelling_display_values(year, chapman_code)
    address = house_or_street_name
    case year
    when '1841'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [folio_number, page_number, dwelling_number, schedule_number, house_number, address]
        # [folio_number, page_number, dwelling_number, house_number, address] #927
      else
        [folio_number, page_number, dwelling_number, house_number, address]
      end
    when '1851'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [folio_number, page_number, dwelling_number, schedule_number, house_number, address]
      else
        [folio_number, page_number, dwelling_number, schedule_number, house_number, address]
      end
    when '1861'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [page_number, dwelling_number, schedule_number, house_number, address, rooms_with_windows]
      else
        [folio_number, page_number, dwelling_number, schedule_number, house_number, address]
      end
    when '1871'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [page_number, dwelling_number, schedule_number, house_number, address, rooms_with_windows]
      else
        [folio_number, page_number, dwelling_number, schedule_number, house_number, address]
      end
    when '1881'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [folio_number, page_number, dwelling_number, schedule_number, house_number, address, rooms_with_windows]
      else
        [folio_number, page_number, dwelling_number, schedule_number, house_number, address]
      end
    when '1891'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [folio_number, page_number, dwelling_number, schedule_number, house_number, address, rooms_with_windows]
      else
        [folio_number, page_number, dwelling_number, schedule_number, house_number, address, rooms]
      end
    when '1901'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [folio_number, page_number, dwelling_number, schedule_number, house_number, address, rooms_with_windows]
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        [page_number, dwelling_number, schedule_number, house_number, address, walls, roof_type, rooms, rooms_with_windows, class_of_house]
      else
        [folio_number, page_number, dwelling_number, schedule_number, house_number, address, rooms]
      end
    when '1911'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [folio_number, page_number, dwelling_number, schedule_number, house_number, address, rooms_with_windows]
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        [page_number, dwelling_number, schedule_number, house_number, address, walls, roof_type, rooms, rooms_with_windows, class_of_house]
      else
        [folio_number, page_number, dwelling_number, schedule_number, house_number, address, rooms]
      end
    end
  end

  def adjust_case
    # Note this code is replicated in freecen_csv_processor so if changes are made here they need also to be made there
    self.surname = FreecenCsvEntry.myupcase(surname)
    self.forenames = FreecenCsvEntry.mytitlieze(forenames)
    self.birth_place = FreecenCsvEntry.mytitlieze(birth_place)
    self.verbatim_birth_place = FreecenCsvEntry.mytitlieze(verbatim_birth_place)
    self.civil_parish = FreecenCsvEntry.mytitlieze(civil_parish)
    self.disability = FreecenCsvEntry.mytitlieze(disability)
    self.ecclesiastical_parish = FreecenCsvEntry.mytitlieze(ecclesiastical_parish)
    self.father_place_of_birth = FreecenCsvEntry.mytitlieze(father_place_of_birth)
    self.house_or_street_name = FreecenCsvEntry.mytitlieze(house_or_street_name)
    self.nationality = nationality.strip.capitalize if nationality.present?
    self.occupation = FreecenCsvEntry.mytitlieze(occupation)
    self.occupation_category = FreecenCsvEntry.myupcase(occupation_category)
    self.at_home = FreecenCsvEntry.myupcase(at_home)
    self.marital_status = FreecenCsvEntry.myupcase(marital_status)
    self.parliamentary_constituency = FreecenCsvEntry.mytitlieze(parliamentary_constituency)
    self.police_district = FreecenCsvEntry.mytitlieze(police_district)
    self.poor_law_union = FreecenCsvEntry.mytitlieze(poor_law_union)
    self.read_write = FreecenCsvEntry.mytitlieze(read_write)
    self.relationship = FreecenCsvEntry.mytitlieze(relationship)
    self.religion = FreecenCsvEntry.mytitlieze(religion)
    self.roof_type = roof_type.strip.capitalize if roof_type.present?
    self.sanitary_district = FreecenCsvEntry.mytitlieze(sanitary_district)
    self.scavenging_district = FreecenCsvEntry.mytitlieze(scavenging_district)
    self.school_board = FreecenCsvEntry.mytitlieze(school_board)
    self.sex = FreecenCsvEntry.myupcase(sex)
    self.special_lighting_district = FreecenCsvEntry.mytitlieze(special_lighting_district)
    self.special_water_district = FreecenCsvEntry.mytitlieze(special_water_district)
    self.ward = FreecenCsvEntry.mytitlieze(ward)
    self.where_census_taken = FreecenCsvEntry.mytitlieze(where_census_taken)
    self.record_valid = record_valid.downcase if record_valid.present?

  end

  def self.management_display_labels
    ['Transition', 'Location Flag', 'Address Flag', 'Name Flag', 'Individual Flag', 'Occupation Flag', 'Birth Place Flag', 'Deleted Flag', 'Record Valid']
  end

  def management_display_values
    [data_transition, location_flag, address_flag, name_flag, individual_flag, occupation_flag, birth_place_flag, deleted_flag, record_valid]
  end

  def self.error_display_labels
    ['Errors Messages', 'Warning Messages', 'Info Messages']
  end

  def error_display_values
    error_message = error_messages.gsub(/\<br\>/, '').gsub(/ERROR:/i, '') if error_messages.present?
    warning_message = warning_messages.gsub(/\<br\>/, '').gsub(/Warning:/i, '') if warning_messages.present?
    info_message = info_messages.gsub(/\<br\>/, '').gsub(/Info:/i, '') if info_messages.present?
    [error_message, warning_message, info_message]
  end

  def self.individual_display_labels(year, chapman_code)
    case year
    when '1841'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation']
      else
        ['Sequence', 'Surname', 'Forenames', 'Sex', 'Age', 'Occupation', 'Birth County', 'Notes']
      end
    when '1851'
      ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation']
    when '1861'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'School Children' 'Occupation']
      else
        ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation']
      end
    when '1871'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'School Children' 'Occupation']
      else
        ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation']
      end
    when '1881'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'School Children' 'Occupation']
      else
        ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation']
      end
    when '1891'
      # only Wales 1891 has language field
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation', 'Occ Category']
      elsif ChapmanCode::CODES['Wales'].values.member?(chapman_code)
        ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation', 'Occ Category']
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation', 'Occ Category']
      else
        ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation', 'Occ Category']
      end
    when '1901'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation', 'Occ Category', 'Works At Home']
      elsif ChapmanCode::CODES['Wales'].values.member?(chapman_code)
        ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation', 'Occ Category', 'Works At Home']
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Religion', 'Read and Write', 'Occupation', 'Occ Category']
      else
        ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation', 'Occ Category', 'Works At Home']
      end
    when '1911'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Years Married', 'Children Born Alive', 'Children Living', 'Occupation', 'Occ Category', 'Industry', 'Works At Home']
      elsif ChapmanCode::CODES['Wales'].values.member?(chapman_code) || chapman_code == 'IOM'
        ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Years Married', 'Children Born Alive', 'Children Living', 'Children Deceased', 'Occupation', 'Occ Category', 'Industry', 'Works At Home']
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Years Married', 'Children Born Alive', 'Children Living', 'Religion', 'Read and Write', 'Occupation', 'Occ Category']
      elsif %w[CHI ALD GSY JSY].include?(chapman_code)
        ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Years Married', 'Children Born Alive', 'Children Living', 'Children Deceased', 'Occupation', 'Occ Category', 'Industry', 'Works At Home']
      else
        ['Sequence', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Years Married', 'Children Born Alive', 'Children Living', 'Children Deceased', 'Occupation', 'Occ Category', 'Industry', 'Works At Home']
      end
    end
  end

  def individual_display_values(year, chapman_code)
    disp_age = age
    if age_unit.present? && age_unit != 'y'
      disp_age = age + age_unit
    end
    disp_occupation = occupation
    sur = surname
    fore = forenames
    relation = relationship
    marital = marital_status
    if year == '1891'
      category = Freecen::OCCUPATIONAL_CATEGORY_1891[occupation_category]
    else
      category = Freecen::OCCUPATIONAL_CATEGORY_1901[occupation_category]
    end
    home = at_home.present? ? 'Yes' : ''
    sx = sex
    note = notes.gsub(/\<br\>/, '') if notes.present?
    verbatim_birth_county_name = ChapmanCode.name_from_code(verbatim_birth_county)
    case year
    when '1841'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, disp_occupation]
      else
        [sequence_in_household, sur, fore, sx, disp_age, disp_occupation, verbatim_birth_county_name, note]
      end
    when '1851'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, disp_occupation]
        # [sequence_in_household, sur, fore, relation, marital, sx, disp_age, school_children, disp_occupation] #927
      else
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, disp_occupation]
      end
    when '1861'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, school_children, disp_occupation]
      else
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, disp_occupation]
      end
    when '1871'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, school_children, disp_occupation]
      else
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, disp_occupation]
      end
    when '1881'
      [sequence_in_household, sur, fore, relation, marital, sx, disp_age, disp_occupation]

    when '1891'
      # only Wales 1891 has language field
      if ChapmanCode::CODES['Wales'].values.member?(chapman_code) || ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, disp_occupation, category]
      else
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, disp_occupation, category]
      end
    when '1901'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, disp_occupation, category, home]
      elsif ChapmanCode::CODES['Wales'].values.member?(chapman_code)
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, disp_occupation, category, home]
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, religion, read_and_write, disp_occupation, category]
      else
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, disp_occupation, category, home]
      end
    when '1911'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, years_married, children_born_alive, children_living, disp_occupation, category, industry, home]
      elsif ChapmanCode::CODES['Wales'].values.member?(chapman_code) || chapman_code == 'IOM'
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, years_married, children_born_alive, children_living, children_deceased, disp_occupation, category, industry, home]
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, years_married, children_born_alive, children_living, religion, read_and_write, disp_occupation, category]
      elsif  %w[CHI ALD GSY JSY].include?(chapman_code)
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, years_married, children_born_alive, children_living, children_deceased, disp_occupation, category, industry, home]
      else
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, years_married, children_born_alive, children_living, children_deceased, disp_occupation, category, industry, home]
      end
    end
  end

  def self.part2_individual_display_labels(year, chapman_code)
    case year
    when '1841' && ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
      ['Birth County', 'Birth Place', 'Disability', 'Notes']
    when '1851'
      ['Nationality', 'Birth County', 'Birth Place', 'Disability', 'Notes']
    when '1861'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Birth County', 'Birth Place', 'Disability', 'Notes']
      else
        ['Nationality', 'Birth County', 'Birth Place', 'Disability', 'Notes']
      end
    when '1871'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Birth County', 'Birth Place', 'Disability', 'Notes']
      else
        ['Nationality', 'Birth County', 'Birth Place', 'Disability', 'Notes']
      end
    when '1881'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Birth County', 'Birth Place', 'Disability', 'Notes']
      else
        ['Nationality', 'Birth County', 'Birth Place', 'Disability', 'Notes']
      end
    when '1891'
      # only Wales 1891 has language field
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Birth County', 'Birth Place', 'Disability', 'Notes']
      elsif ChapmanCode::CODES['Wales'].values.member?(chapman_code)
        ['Nationality', 'Birth County', 'Birth Place', 'Disability', 'Language', 'Notes']
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        ['Birth County', 'Birth Place', 'Disability', 'Notes']
      else
        ['Nationality', 'Birth County', 'Birth Place', 'Disability', 'Notes']
      end
    when '1901'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Birth County', 'Birth Place', 'Disability', 'Language', 'Notes']
      elsif ChapmanCode::CODES['Wales'].values.member?(chapman_code)
        ['Nationality', 'Birth County', 'Birth Place', 'Disability', 'Language', 'Notes']
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        ['Birth County', 'Birth Place', 'Disability', 'Notes']
      else
        ['Nationality', 'Birth County',  'Birth Place', 'Disability', 'Notes']
      end
    when '1911'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Nationality', 'Birth County',  'Birth Place', 'Disability', 'Language', 'Notes']
      elsif ChapmanCode::CODES['Wales'].values.member?(chapman_code) || chapman_code == 'IOM'
        ['Nationality', 'Birth County',  'Birth Place', 'Disability', 'Disability Notes', 'Language', 'Notes']
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        ['Nationality', 'Birth County',  'Birth Place', 'Disability', 'Notes']
      elsif %w[CHI ALD GSY JSY].include?(chapman_code)
        ['Nationality', 'Birth County',  'Birth Place', "Father's Place of Birth", 'Disability', 'Notes']
      else
        ['Nationality', 'Birth County',  'Birth Place', 'Disability', 'Disability Notes', 'Notes']
      end
    end
  end

  def part2_individual_display_values(year, chapman_code)
    birth = birth_place
    birth = birth + ' (or ' + verbatim_birth_place + ')' if birth_place.present? && birth_place != verbatim_birth_place
    birth = verbatim_birth_place if birth_place.blank?
    birth_county_name = ChapmanCode.name_from_code(birth_county)
    verbatim_birth_county_name = ChapmanCode.name_from_code(verbatim_birth_county)
    birth_county_name = birth_county_name + ' (or ' + verbatim_birth_county_name + ')' if birth_county_name.present? && birth_county_name != verbatim_birth_county_name
    birth_county_name = verbatim_birth_county_name if birth_county_name.blank?

    note = notes.gsub(/\<br\>/, '') if notes.present?
    lang = Freecen::LANGUAGE[language.upcase] if language.present?
    case year
    when '1841' && ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
      [birth_county_name, birth, disability, note]
    when '1851'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [nationality, birth_county_name, birth, disability, note]
        # [birth_county_name, birth,  note] #927
      else
        [nationality, birth_county_name, birth, disability, note]
      end
    when '1861'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [birth_county_name, birth, disability, note]
      else
        [nationality, birth_county_name, birth, disability, note]
      end
    when '1871'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [birth_county_name, birth, disability, note]
      else
        [nationality, birth_county_name, birth, disability, note]
      end
    when '1881'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [birth_county_name, birth, disability, note]
      else
        [nationality, birth_county_name, birth, disability, note]
      end
    when '1891'
      # only Wales 1891 has language field
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [birth_county_name, birth, disability, note]
      elsif ChapmanCode::CODES['Wales'].values.member?(chapman_code)
        [nationality, birth_county_name, birth, disability, lang, note]
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        [birth_county_name, birth, disability, note]
      else
        [nationality, birth_county_name, birth, disability, note]
      end
    when '1901'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [birth_county_name, birth, disability, lang, note]
      elsif ChapmanCode::CODES['Wales'].values.member?(chapman_code)
        [nationality, birth_county_name, birth, disability, lang, note]
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        [birth_county_name, birth,  disability, lang, note]
      else
        [nationality, birth_county_name, birth, disability, note]
      end
    when '1911'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [nationality, birth_county_name, birth, disability, lang, note]
      elsif ChapmanCode::CODES['Wales'].values.member?(chapman_code) || chapman_code == 'IOM'
        [nationality, birth_county_name, birth, disability, disability_notes, lang, note]
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        [birth_county_name, birth, disability, lang, note]
      elsif %w[CHI ALD GSY JSY].include?(chapman_code)
        [nationality, birth_county_name, birth, father_place_of_birth, disability, disability_notes, lang, note]
      else
        [nationality, birth_county_name, birth, disability, disability_notes, note]
      end
    end
  end

  def next_and_previous_entries
    file_id = freecen_csv_file.id
    next_entry = record_number + 1
    previous_entry = record_number - 1
    next_entry = FreecenCsvEntry.find_by(freecen_csv_file_id: file_id, record_number: next_entry)
    previous_entry = FreecenCsvEntry.find_by(freecen_csv_file_id: file_id, record_number: previous_entry)
    [next_entry, previous_entry]
  end

  def next_and_previous_list_entries(type)
    list_of_records = freecen_csv_file.index_type(type).pluck(:_id)
    return [nil, nil] if list_of_records.blank?

    current_index = list_of_records.find_index(_id)
    return [nil, nil] if current_index.blank?

    number_records = list_of_records.length
    next_entry = (current_index + 1) <= number_records ? FreecenCsvEntry.find_by(_id: list_of_records[current_index + 1]) : nil
    previous_entry = (current_index - 1) < 0 ? nil : FreecenCsvEntry.find_by(_id: list_of_records[current_index - 1])
    [next_entry, previous_entry]
  end

  def remove_flags
    update_attributes(flag: false, address_flag: '', birth_place_flag: '', individual_flag: '', deleted_flag: '', location_flag: '',
                      name_flag: '', occupation_flag: '')
  end

  def validate_on_line_edit_of_fields(fields)
    success, message = FreecenValidations.text?(fields[:surname])
    if success && fields[:surname].present? && fields[:surname].strip == '-'
      errors.add(:surname, "has single - Hyphen in Surname") unless fields[:record_valid] == 'true'
    elsif !success
      errors.add(:surname, "Invalid; #{message}")
    end

    success, message = FreecenValidations.text?(fields[:forenames])
    if success && fields[:forenames].present? && fields[:forenames].strip == '-'
      errors.add(:forenames, "has single - Hyphen in Forename") unless fields[:record_valid] == 'true'
    elsif !success
      errors.add(:forenames, "Invalid; #{message}")
    end

    success, message = FreecenValidations.name_question?(fields[:name_flag])
    errors.add(:name_flag, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'

    success, message = FreecenValidations.sex?(fields[:sex])
    errors.add(:sex, "Invalid; #{message}")  unless success || fields[:record_valid] == 'true'

    success, message = FreecenValidations.age?(fields[:age], fields[:marital_status], fields[:sex])
    errors.add(:age, "Invalid; #{message}") unless success || fields[:record_valid] == 'true' || (message == 'Unusual Age 999' && freecen_csv_file.validation)

    success, message = FreecenValidations.uncertainty_status?(fields[:individual_flag])
    errors.add(:individual_flag, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'

    success, message = FreecenValidations.occupation?(fields[:occupation], fields[:age])
    errors.add(:occupation, "Invalid; #{message}") unless success || fields[:record_valid] == 'true' || (message == 'unusual use of Scholar' && freecen_csv_file.validation)

    success, message = FreecenValidations.uncertainty_occupation?(fields[:occupation_flag])
    errors.add(:occupation_flag, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'

    success, message = FreecenValidations.uncertainy_birth?(fields[:birth_place_flag])
    errors.add(:birth_place_flag, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'

    success, message = FreecenValidations.notes?(fields[:notes])
    errors.add(:language, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'

    if fields[:relationship].present?
      success, message = FreecenValidations.relationship?(fields[:relationship])
      errors.add(:relationship, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'
    end

    if fields[:marital_status].present?
      success, message = FreecenValidations.marital_status?(fields[:marital_status])
      errors.add(:marital_status, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'
    end
    if fields[:school_children].present?
      success, message = FreecenValidations.school_children?(fields[:school_children])
      errors.add(:school_children, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'
    end

    if fields[:years_married].present?
      success, message = FreecenValidations.years_married?(fields[:years_married])
      errors.add(:years_married, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'
    end

    if fields[:children_living].present?
      success, message = FreecenValidations.children_living?(fields[:children_living])
      errors.add(:children_living, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'
    end

    if fields[:children_deceased].present?
      success, message = FreecenValidations.children_deceased?(fields[:children_deceased])
      errors.add(:children_deceased, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'
    end

    if fields[:children_born_alive].present?
      success, message = FreecenValidations.children_born_alive?(fields[:children_born_alive])
      errors.add(:children_born_alive, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'
    end

    if fields[:religion].present?
      success, message = FreecenValidations.religion?(fields[:religion])
      errors.add(:religion, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'
    end

    if fields[:read_write].present?
      success, message = FreecenValidations.read_write?(fields[:read_write])
      errors.add(:read_write, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'
    end

    if fields[:industry].present?
      success, message = FreecenValidations.industry?(fields[:industry])
      errors.add(:industry, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'
    end

    if fields[:occupation_category].present?
      success, message = FreecenValidations.occupation_category?(fields[:occupation_category])
      errors.add(:occupation_category, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'
    end

    if fields[:at_home].present?
      success, message = FreecenValidations.at_home?(fields[:at_home])
      errors.add(:at_home, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'
    end

    success, message = FreecenValidations.verbatim_birth_county?(fields[:verbatim_birth_county])
    errors.add(:verbatim_birth_county, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'

    @valid_alternate_chapman_code = false
    if fields[:birth_county].present?
      success, message = FreecenValidations.verbatim_birth_county?(fields[:birth_county])
      errors.add(:birth_county, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'
      @valid_alternate_chapman_code = true if success
    end

    success, message = FreecenValidations.verbatim_birth_place?(fields[:verbatim_birth_place]) unless fields[:year] == '1841'
    errors.add(:verbatim_birth_place, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'
    unless file_validation
      place_valid = true
      place_valid = Freecen2Place.chapman_code(fields[:verbatim_birth_county]).place(fields[:verbatim_birth_place]).first if fields[:verbatim_birth_county].present? && fields[:verbatim_birth_place].present? && fields[:verbatim_birth_place] != '-'
      if fields[:warning_messages].blank?
        fields[:warning_messages] = "Warning: line #{fields[:record_number]} Verbatim Place of Birth #{fields[:verbatim_birth_place]} in #{fields[:verbatim_birth_county]} was not found so requires validation.<br>" if place_valid.blank?
      else
        fields[:warning_messages] += "Warning: line #{fields[:record_number]} Verbatim Place of Birth #{fields[:verbatim_birth_place]} in #{fields[:verbatim_birth_county]} was not found so requires validation.<br>" if place_valid.blank?
      end
    end

    if fields[:birth_place].present?
      success, message = FreecenValidations.birth_place?(fields[:birth_place])
      errors.add(:birth_place, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'
      if file_validation
        place_valid = false
        if fields[:birth_place] == '-' && fields[:birth_county].present? && @valid_alternate_chapman_code
          place_valid = true
        elsif fields[:birth_county].present? && @valid_alternate_chapman_code && fields[:birth_place].present?
          place_valid = Freecen2Place.valid_place_name?(fields[:birth_county], fields[:birth_place])
        end
        errors.add(:birth_place, "Alt. Place of Birth #{fields[:birth_place]} not found in #{fields[:birth_county]}") unless place_valid
      else
        if fields[:birth_place] == '-' && fields[:birth_county].present? && @valid_alternate_chapman_code
          place_valid = true
        elsif fields[:birth_county].present? && @valid_alternate_chapman_code && fields[:birth_place].present?
          place_valid = Freecen2Place.valid_place_name?(fields[:birth_county], fields[:birth_place])
        end
        if fields[:warning_messages].blank?
          fields[:warning_messages] = "Warning: line #{fields[:record_number]} ALt. Place of Birth #{fields[:birth_place]} in #{fields[:birth_county]} was not found.<br>" if place_valid.blank?
        else
          fields[:warning_messages] += "Warning: line #{fields[:record_number]} ALt. Place of Birth #{fields[:birth_place]} in #{fields[:birth_county]} was not found.<br>" if place_valid.blank?
        end
      end
    end

    if fields[:nationality].present?
      success, message = FreecenValidations.nationality?(fields[:nationality])
      errors.add(:nationality, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'
    end

    if fields[:father_place_of_birth].present?
      success, message = FreecenValidations.father_place_of_birth?(fields[:father_place_of_birth])
      errors.add(:father_place_of_birth, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'
    end

    if fields[:disability].present?
      success, message = FreecenValidations.disability?(fields[:disability])
      errors.add(:disability, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'
    end

    if fields[:disability_notes].present?
      success, message = FreecenValidations.disability_notes?(fields[:disability_notes])
      errors.add(:disability_notes, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'
    end

    if fields[:language].present?
      success, message = FreecenValidations.language?(fields[:language])
      errors.add(:language, "Invalid; #{message}") unless success || fields[:record_valid] == 'true'
    end
  end

  def translate_date
    myage = age.to_i
    census_year = year
    adjustment = 0 # this is all we need to do for day and week age units
    myage_with_unit = AgeParser.new(age).process_age if age.present?
    myage_unit_included = myage_with_unit.match?(/[A-Za-z]/) if age.present?
    logger.warn("myagggggggggggge = #{myage_unit_included}")
    if myage_unit_included
      myage_unit = myage_with_unit[-1]
      if myage_unit == 'y'
        myage = myage_with_unit.to_i
        adjustment = 0 - myage
      end
      if myage_unit == 'm'
        myage = myage_with_unit.to_i
        if census_year == RecordType::CENSUS_1841
          # Census day: June 6, 1841
          #
          # Ages in the 1841 Census
          #    The census takers were instructed to give the exact ages of children
          # but to round the ages of those older than 15 down to a lower multiple of 5.
          # For example, a 59-year-old person would be listed as 55. Not all census
          # enumerators followed these instructions. Some recorded the exact age;
          # some even rounded the age up to the nearest multiple of 5.
          #
          # Source: http://familysearch.org/learn/wiki/en/England_Census:_Further_Information_and_Description
          adjustment = -1 if myage > 6
        elsif census_year == RecordType::CENSUS_1851
          # Census day: March 30, 1851
          adjustment = -1 if myage > 3
        elsif census_year == RecordType::CENSUS_1861
          # Census day: April 7, 1861
          adjustment = -1 if myage > 4
        elsif census_year == RecordType::CENSUS_1871
          # Census day: April 2, 1871
          adjustment = -1 if myage > 4
        elsif census_year == RecordType::CENSUS_1881
          # Census day: April 3, 1881
          adjustment = -1 if myage > 4
        elsif census_year == RecordType::CENSUS_1891
          # Census day: April 5, 1891
          adjustment = -1 if myage > 4
        end
      end
    else
      adjustment = 0 - myage
    end
    birth_year = census_year.to_i + adjustment
    "#{birth_year}-*-*"
  end

  def translate_date_old
    myage = age.to_i

    census_year = year
    adjustment = 0 # this is all we need to do for day and week age units
    if age_unit == 'y' || age_unit.blank?
      adjustment = 0 - myage
    end
    if age_unit == 'm'
      if census_year == RecordType::CENSUS_1841
        # Census day: June 6, 1841
        #
        # Ages in the 1841 Census
        #    The census takers were instructed to give the exact ages of children
        # but to round the ages of those older than 15 down to a lower multiple of 5.
        # For example, a 59-year-old person would be listed as 55. Not all census
        # enumerators followed these instructions. Some recorded the exact age;
        # some even rounded the age up to the nearest multiple of 5.
        #
        # Source: http://familysearch.org/learn/wiki/en/England_Census:_Further_Information_and_Description
        adjustment = -1 if myage > 6
      elsif census_year == RecordType::CENSUS_1851
        # Census day: March 30, 1851
        adjustment = -1 if myage > 3
      elsif census_year == RecordType::CENSUS_1861
        # Census day: April 7, 1861
        adjustment = -1 if myage > 4
      elsif census_year == RecordType::CENSUS_1871
        # Census day: April 2, 1871
        adjustment = -1 if myage > 4
      elsif census_year == RecordType::CENSUS_1881
        # Census day: April 3, 1881
        adjustment = -1 if myage > 4
      elsif census_year == RecordType::CENSUS_1891
        # Census day: April 5, 1891
        adjustment = -1 if myage > 4
      end
    end
    birth_year = census_year.to_i + adjustment
    "#{birth_year}-*-*"
  end


  def translate_individual(piece, district, chapman_code, place, file_id)
    # create the search record for the person
    transcript_name = { first_name: forenames, last_name: surname, type: 'primary' }
    transcript_date = translate_date

    record = SearchRecord.new(transcript_dates: [transcript_date], transcript_names: [transcript_name], chapman_code: chapman_code,
                              record_type: year, freecen2_civil_parish_id: freecen2_civil_parish_id, freecen2_place_id: place.id,
                              freecen2_piece_id: piece.id, freecen2_district_id: district.id, freecen_csv_entry_id: _id, freecen_csv_file_id: file_id)
    if birth_county.present?
      record.birth_chapman_code = birth_county
    elsif verbatim_birth_county.present?
      record.birth_chapman_code = verbatim_birth_county
    end
    if birth_place.present?
      record.birth_place = birth_place
    elsif verbatim_birth_place.present?
      record.birth_place = verbatim_birth_place
    end
    if record.birth_chapman_code.present? && record.birth_place.present?
      valid_pob, place_id = Freecen2Place.valid_place(record.birth_chapman_code, record.birth_place)
      valid_pob ? record.freecen2_place_of_birth = place_id : record.freecen2_place_of_birth = nil
    end
    record.transform
    record.add_digest
    record.save!
    update_attributes(search_record_id: record.id)
    place.update_data_present(piece)
  end
end
