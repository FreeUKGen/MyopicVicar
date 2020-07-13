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

  belongs_to :freecen_csv_file, index: true, optional: true

  has_one :search_record, dependent: :restrict_with_error

  before_destroy do |entry|
    file = entry.freecen_csv_file
    if file.processed
      SearchRecord.collection.delete_many(freecen_csv_entry_id: entry._id)
    end
  end

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
      civil_parish = record[:civil_parish]
      num = record[:record_number]
      info_messages = record[:messages]
      new_civil_parish = civil_parish
      message = ''
      success, messagea = FreecenValidations.valid_location?(civil_parish)

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
          record[:error_messages] = record[:error_messages] + messageb
          new_civil_parish = previous_civil_parish
          return [messageb, new_civil_parish]
        elsif messagea == 'INVALID_TEXT'
          messagea = "ERROR: line #{num} Civil Parish has invalid text #{civil_parish}.<br>"
          record[:error_messages] = record[:error_messages] + messagea
          new_civil_parish = previous_civil_parish
          return [messagea, new_civil_parish]
        end
      end

      valid = false

      record[:piece].freecen2_civil_parishes.each do |subplace|
        valid = true if subplace[:name].to_s.downcase == record[:civil_parish].to_s.downcase
        break if valid
      end
      unless valid
        message += "ERROR: line #{num} Civil Parish #{record[:civil_parish]} is not in the list of Civil Parishes.<br>"
        record[:error_messages] += message
      end

      if previous_civil_parish == ''
        messagea = "Info: line #{num} New Civil Parish #{record[:civil_parish]}.<br>" if info_messages
      elsif previous_civil_parish == record[:civil_parish]
        messagea = "Info: line #{num} Civil Parish has remained the same #{record[:civil_parish]}.<br>" if info_messages
      elsif info_messages
        messagea = "Info: line #{num} Civil Parish has changed to #{record[:civil_parish]}.<br>"
      end
      record[:info_messages] += messagea if info_messages
      message += messagea if messagea.present?
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
          record[:error_messages] = record[:error_messages] + messageb
          return [messageb, new_enumeration_district]
        end
      end

      parts = ''
      parts = enumeration_district.split('#') if enumeration_district.present?
      # p parts
      special = parts.length > 0 ? parts[1] : nil
      if previous_enumeration_district == ''
        message = "Info: line #{num} New Enumeration District #{enumeration_district}.<br>" if info_messages
        record[:info_messages] = record[:info_messages] + message if info_messages
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
      success, messagea = FreecenValidations.valid_location?(ecclesiastical_parish)
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
      elsif ecclesiastical_parish.blank?
      elsif previous_ecclesiastical_parish == ecclesiastical_parish
      else
        messagea = "Info: line #{num} Ecclesiastical Parish changed to #{ecclesiastical_parish}.<br>" if info_messages
        record[:info_messages] += message if info_messages
        new_ecclesiastical_parish = ecclesiastical_parish
      end
      message += messagea if messagea.present?
      [message, new_ecclesiastical_parish]
    end

    def validate_where_census_taken(record, previous_where_census_taken)
      where_census_taken = record[:where_census_taken]
      num = record[:record_number]
      new_where_census_taken = previous_where_census_taken
      info_messages = record[:messages]
      message = ''
      success, messagea = FreecenValidations.valid_location?(where_census_taken)
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
        new_where_census_taken = where_census_taken
      elsif where_census_taken.blank?
      elsif previous_where_census_taken == where_census_taken
      else
        message = "Info: line #{num} Where Census Taken changed to #{where_census_taken}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        new_where_census_taken = where_census_taken
      end
      message += messagea if messagea.present?
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
        new_ward = ward
      elsif ward.blank?
      elsif previous_ward == ward
      else
        messagea = "Info: line #{num} Municipal Borough changed to #{ward}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        new_ward = ward
      end
      message += messagea if messagea.present?
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
        new_parliamentary_constituency = parliamentary_constituency
      elsif parliamentary_constituency.blank?
      elsif previous_parliamentary_constituency == parliamentary_constituency
      else
        messagea = "Info: line #{num} Parliamentary Constituency changed to #{parliamentary_constituency}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        new_parliamentary_constituency = parliamentary_constituency
      end
      message += messagea if messagea.present?
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
        new_poor_law_union = poor_law_union
      elsif poor_law_union.blank?
      elsif previous_poor_law_union == poor_law_union
      else
        messagea = "Info: line #{num} Poor Law Union changed to #{poor_law_union}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        new_poor_law_union = poor_law_union
      end
      message += messagea if messagea.present?
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
        new_police_district = police_district
      elsif police_district.blank?
      elsif previous_police_district == police_district
      else
        messagea = "Info: line #{num} Police District changed to #{police_district}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        new_police_district = police_district
      end
      message += messagea if messagea.present?
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
        new_sanitary_district = sanitary_district
      elsif sanitary_district.blank?
      elsif previous_sanitary_district == sanitary_district
      else
        messagea = "Info: line #{num} Sanitary District changed to #{sanitary_district}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        new_sanitary_district = sanitary_district
      end
      message += messagea if messagea.present?
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
        new_special_water_district = special_water_district
      elsif special_water_district.blank?
      elsif previous_special_water_district == special_water_district
      else
        messagea = "Info: line #{num} Special Water District changed to #{special_water_district}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        new_special_water_district = special_water_district
      end
      message += messagea if messagea.present?
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
        new_scavenging_district = scavenging_district
      elsif scavenging_district.blank?
      elsif previous_scavenging_district == scavenging_district
      else
        messagea = "Info: line #{num} Scavenging District changed to #{scavenging_district}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        new_scavenging_district = scavenging_district
      end
      message += messagea if messagea.present?
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
        new_special_lighting_district = special_lighting_district
      elsif special_lighting_district.blank?
      elsif previous_special_lighting_district == special_lighting_district
      else
        messagea = "Info: line #{num} Special Lighting District changed to #{special_lighting_district}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        new_special_lighting_district = special_lighting_district
      end
      message += messagea if messagea.present?
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
        new_school_board = school_board
      elsif school_board.blank?
      elsif previous_school_board == school_board
      else
        messagea = "Info: line #{num} School Board changed to #{school_board}.<br>" if info_messages
        record[:info_messages] += messagea if info_messages
        new_school_board = school_board
      end
      message += messagea if messagea.present?
      [message, new_school_board]
    end

    def validate_location_flag(record)
      flag = record[:location_flag]
      num = record[:record_number]
      success, messagea = FreecenValidations.location_flag?(flag)
      unless success
        messageb = "ERROR: line #{num} Location Flag #{flag} is #{messagea}.<br>"
        record[:error_messages] = record[:error_messages] + messageb
        return [messageb]
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
        record[:error_messages] = record[:error_messages] + messagea
        return [messagea, new_folio_number, new_folio_suffix]
      end

      if previous_folio_number == 0
        message = "Info: line #{num} Initial Folio number set to #{folio_number}.<br>" if info_messages
        record[:info_messages] = record[:info_messages] + message if info_messages
        new_folio_number = folio_number.to_i
        new_folio_suffix = folio_suffix
      elsif  folio_number.blank? && ['Folio', 'Page'].include?(transition)
        message = ''
      elsif  folio_number.blank? && year == '1841' && page_number.to_i.even?
        message = "Warning: line #{num} New Folio number is blank.<br>"
        record[:warning_messages] = record[:warning_messages] + message
      elsif folio_number.blank? && year != '1841' && page_number.to_i.odd?
        message = "Warning: line #{num} New Folio number is blank.<br>"
        record[:warning_messages] = record[:warning_messages] + message
      elsif folio_number.blank?
      elsif previous_folio_number.present? && (folio_number.to_i > (previous_folio_number.to_i + 1)) && ['Folio', 'Page'].include?(transition)
        message = "Warning: line #{num} New Folio number increment larger than 1 #{folio_number}.<br>"
        record[:warning_messages] = record[:warning_messages] + message
        new_folio_number = folio_number.to_i
        new_folio_suffix = folio_suffix
      elsif (folio_number.to_i == previous_folio_number.to_i) && ['Folio', 'Page'].include?(transition)
        message = "Warning: line #{num} New Folio number is the same as the previous number #{folio_number}.<br>"
        record[:warning_messages] = record[:warning_messages] + message
      elsif previous_folio_number.present? && (folio_number.to_i < previous_folio_number.to_i) && ['Folio', 'Page'].include?(transition)
        message = "Warning: line #{num} New Folio number is less than the previous number #{folio_number}.<br>"
        record[:warning_messages] = record[:warning_messages] + message
        new_folio_number = folio_number.to_i
        new_folio_suffix = folio_suffix
      else
        message = "Info: line #{num} New Folio number #{folio_number}.<br>" if info_messages
        record[:info_messages] = record[:info_messages] + message if info_messages
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
        record[:error_messages] = record[:error_messages] + messagea
        return [messagea, new_page_number]
      end

      if previous_page_number == 0
        message = "Info: line #{num} Initial Page number set to #{page_number}.<br>" if info_messages
        record[:info_messages] = record[:info_messages] + message if info_messages
        new_page_number = page_number.to_i
      elsif  page_number.blank? && Freecen::LOCATION_PAGE.include?(transition)
        message = ''
      elsif  page_number.blank?
        message = "Warning: line #{num} New Page number is blank.<br>"
        record[:warning_messages] = record[:warning_messages] + message
      elsif (page_number.to_i > previous_page_number + 1) && Freecen::LOCATION_PAGE.include?(transition)
        message = "Warning: line #{num} New Page number increment larger than 1 #{page_number}.<br>"
        record[:warning_messages] = record[:warning_messages] + message
        new_page_number = page_number.to_i
      elsif (page_number.to_i == previous_page_number) && Freecen::LOCATION_PAGE.include?(transition)
        message = "Warning: line #{num} New Page number is the same as the previous number #{page_number}.<br>"
        record[:warning_messages] = record[:warning_messages] + message
      elsif page_number.to_i < previous_page_number && page_number.to_i != 1 && Freecen::LOCATION_PAGE.include?(transition)
        message = "Warning: line #{num} New Page number is less than the previous number #{page_number}.<br>"
        record[:warning_messages] = record[:warning_messages] + message
        new_page_number = page_number.to_i
      elsif page_number.to_i < previous_page_number && page_number.to_i == 1
        message = "Info: line #{num} reset Page number to 1.<br>" if info_messages
        record[:info_messages] = record[:info_messages] + message if info_messages
        new_page_number = 1
      else
        message = "Info: line #{num} New Page number #{page_number}.<br>" if info_messages
        record[:info_messages] = record[:info_messages] + message if info_messages
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
          record[:info_messages] = record[:info_messages] + message if info_messages
        elsif messagea == 'blank' && record[:house_or_street_name] == '-' && house_number.blank?
          message = "Info: line #{num} Schedule number retained at #{new_schedule_number}.<br>" if info_messages
          record[:info_messages] = record[:info_messages] + message if info_messages
        elsif messagea == 'blank' && record[:year] == '1841'

        elsif messagea == 'blank'
          messagea = "ERROR: line #{num} Schedule number is blank and not a page transition.<br>"
          message = message + messagea
          record[:error_messages] = record[:error_messages] + messagea
        else
          messagea = "ERROR: line #{num} Schedule number #{record[:schedule_number]} is #{messagea}.<br>"
          message = message + messagea
          record[:error_messages] = record[:error_messages] + messagea
        end
      elsif (schedule_number.to_i > (previous_schedule_number.to_i + 1)) && previous_schedule_number.to_i != 0
        message = "Warning: line #{num} Schedule number #{record[:schedule_number]} increments more than 1 .<br>"
        record[:warning_messages] = record[:warning_messages] + message
      elsif (schedule_number.to_i < previous_schedule_number.to_i) && schedule_number.to_i != 0
        message = "Warning: line #{num} Schedule number #{record[:schedule_number]} is less than the previous one .<br>"
        record[:warning_messages] = record[:warning_messages] + message
      end

      success, messagea = FreecenValidations.house_number?(house_number)
      if !success
        messageb = "ERROR: line #{num} House number #{house_number} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messagea
      end
      success, messagea = FreecenValidations.house_address?(record[:house_or_street_name])
      unless success
        if messagea == '?'
          messagea = "Warning: line #{num} House address #{record[:house_or_street_name]}  has trailing ?. Removed and address_flag set.<br>"
          message = message + messagea
          record[:warning_messages] = record[:warning_messages] + messagea
          record[:address_flag] = 'x'
          record[:house_or_street_name] = record[:house_or_street_name][0...-1].strip
        elsif messagea == 'blank'
        else
          messageb = "ERROR: line #{num} House address #{record[:house_or_street_name]} is #{messagea}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      end

      success, messagea = FreecenValidations.address_flag?(record[:address_flag])
      if !success
        messageb = "ERROR: line #{num} Address flag #{record[:address_flag]} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messagea
      end

      success, messagea = FreecenValidations.uninhabited_flag?(uninhabited_flag)
      unless success
        messageb = "ERROR: line #{num} Uninhabited Flag #{uninhabited_flag} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messageb
      else
        if %w[u v].include?(uninhabited_flag) && schedule_number.blank?
          messageb = "Warning: line #{num} has special #{uninhabited_flag} but no schedule number.<br>"
          message = message + messageb
          record[:warning_messages] = record[:warning_messages] + messageb
        end
        if uninhabited_flag == 'x'
          record[:address_flag] = 'x'
          record[:uninhabited_flag] = ''
          messageb = "Info: line #{num} uninhabited_flag if x is moved to loaction_flag.<br>"  if info_messages
          message = message + messageb  if info_messages
          record[:info_messages] = record[:info_messages] + messageb  if info_messages
        end
      end

      unless %w[b n u v].include?(uninhabited_flag)
        if record[:walls].present?
          if %w[1901 1911].include?(record[:year])
            success, messagea = FreecenValidations.walls?(record[:walls])
            unless success
              messageb = "ERROR: line #{num} Number of walls #{record[:walls]} is #{messagea}.<br>"
              message = message + messageb
              record[:error_messages] = record[:error_messages] + messageb
            end
          else
            messageb = "ERROR: line #{num} Number of walls #{record[:walls]} should not be included for #{record[:year]}.<br>"
            message = message + messageb
            record[:error_messages] = record[:error_messages] + messageb
          end
        end

        if record[:roof_type].present?
          if %w[1901 1911].include?(record[:year])
            success, messagea = FreecenValidations.roof_type?(record[:roof_type])
            unless success
              messageb = "ERROR: line #{num} Roof type #{record[:roof_type]} is #{messagea}.<br>"
              message = message + messageb
              record[:error_messages] = record[:error_messages] + messageb
            end
          else
            messageb = "ERROR: line #{num} Roof type #{record[:roof_type]} should not be included for #{record[:year]}.<br>"
            message = message + messageb
            record[:error_messages] = record[:error_messages] + messageb
          end
        end

        if record[:rooms].present?
          if %w[1901 1911].include?(record[:year])
            success, messagea = FreecenValidations.rooms?(record[:rooms], record[:year])
            unless success
              messageb = "ERROR: line #{num} Rooms #{record[:rooms]} is #{messagea}.<br>"
              message = message + messageb
              record[:error_messages] = record[:error_messages] + messageb
            else
              if record[:year] == '1901' && record[:rooms].to_i >= 5
                messageb = "Warning: line #{num} Rooms #{record[:rooms]} is greater then 5.<br>"
                message = message + messageb
                record[:waring_messages] = record[:warning_messages] + messageb
              elsif record[:year] == '1911' && record[:rooms].to_i > 20
                messageb = "Warning: line #{num} Rooms #{record[:rooms]} is greater then 20.<br>"
                message = message + messageb
                record[:waring_messages] = record[:warning_messages] + messageb
              end
            end
          else
            messageb = "ERROR: line #{num} Rooms #{record[:rooms]}} should not be included for #{record[:year]}.<br>"
            message = message + messageb
            record[:error_messages] = record[:error_messages] + messageb
          end
        end

        if record[:rooms_with_windows].present?
          if %w[1861 1871 1881 1891 1901 1911].include?(record[:year])
            success, messagea = FreecenValidations.rooms_with_windows?(record[:rooms_with_windows])
            unless success
              messageb = "ERROR: line #{num} Rooms with windows #{record[:rooms_with_windows]} is #{messagea}.<br>"
              message = message + messageb
              record[:error_messages] = record[:error_messages] + messageb
            end
          else
            messageb = "ERROR: line #{num} Rooms with windows #{record[:rooms_with_windows]} should not be included for #{record[:year]}.<br>"
            message = message + messageb
            record[:error_messages] = record[:error_messages] + messageb
          end
        end

        if record[:class_of_house].present?
          if %w[1901 1911].include?(record[:year])
            success, messagea = FreecenValidations.class_of_house?(record[:class_of_house])
            unless success
              messageb = "ERROR: line #{num} Class of house #{record[:class_of_house]} is #{messagea}.<br>"
              message = message + messageb
              record[:error_messages] = record[:error_messages] + messageb
            end
          else
            messageb = "ERROR: line #{num} Class of house #{record[:class_of_house]}  should not be included for #{record[:year]}.<br>"
            message = message + messageb
            record[:error_messages] = record[:error_messages] + messageb
          end
        end
      end
      [message, new_schedule_number, new_schedule_suffix]
    end

    def validate_individual(record)
      # p 'validate_individual'
      num = record[:record_number]
      return [true, ''] if %w[b n u v].include?(record[:uninhabited_flag])

      message = ''
      success, messagea = FreecenValidations.surname?(record[:surname])
      unless success
        if messagea == '?'
          messageb = "Warning: line #{num} Surname  #{record[:surname]} has trailing ?. Removed and flag set.<br>"
          record[:warning_messages] = record[:warning_messages] + messageb
          record[:name_flag] = 'x'
          record[:surname] = record[:surname][0...-1].strip
        else
          messageb = "ERROR: line #{num} Surname #{record[:surname]} is #{messagea}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      end

      success, messagea = FreecenValidations.forenames?(record[:forenames])
      unless success
        if messagea == '?'
          messageb = "Warning: line #{num} Forenames  #{record[:forenames]} has trailing ?. Removed and flag set.<br>"
          message = message + messageb
          record[:warning_messages] = record[:warning_messages] + messageb
          record[:name_flag] = 'x'
          record[:forenames] = record[:forenames][0...-1].strip
        else
          messageb = "ERROR: line #{num} Forenames #{record[:forenames]} is #{messagea}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      end

      success, messagea = FreecenValidations.name_question?(record[:name_flag])
      unless success
        messageb = "ERROR: line #{num} Name Uncertainty #{record[:name_flag]} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messageb
      end

      unless record[:year] == '1841'
        success, messagea = FreecenValidations.relationship?(record[:relationship])
        unless success
          messageb = "ERROR: line #{num} Relationship #{record[:relationship]} is #{messagea}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
        if record[:relationship].present? && record[:relationship].casecmp('head').zero? && record[:sequence_in_household].to_i != 1
          messageb = "Warning: line #{num} Relationship #{record[:relationship]} is #{record[:sequence_in_household]} in household sequence.<br>"
          message = message + messageb
          record[:warning_messages] = record[:warning_messages] + messageb
        end
      end

      unless record[:year] == '1841'
        success, messagea = FreecenValidations.marital_status?(record[:marital_status])
        unless success
          messageb = "ERROR: line #{num} Marital status #{record[:marital_status]} is #{messagea}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      end

      success, messagea = FreecenValidations.sex?(record[:sex])
      unless success
        messageb = "ERROR: line #{num} Sex #{record[:sex]} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messageb
      end

      success, messagea = FreecenValidations.age?(record[:age], record[:marital_status], record[:sex])
      unless success
        messageb = "ERROR: line #{num} Age #{record[:age]} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messageb
      end

      if record[:school_children].present?
        if %w[1861 1871].include?(record[:year])
          success, messagea = FreecenValidations.school_children?(record[:aschool_childrene])
          unless success
            messageb = "ERROR: line #{num}  is #{messagea}.<br>"
            message = message + messageb
            record[:error_messages] = record[:error_messages] + messageb
          end
        else
          messageb = "ERROR: line #{num} Number of school children #{record[:school_children]} should not be included for #{record[:year]}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      end

      if record[:years_married].present?
        if %w[1911].include?(record[:year])
          success, messagea = FreecenValidations.years_married?(record[:years_married])
          unless success
            messageb = "ERROR: line #{num} Years married #{record[:years_married]} is #{messagea}.<br>"
            message = message + messageb
            record[:error_messages] = record[:error_messages] + messageb
          end
        else
          messageb = "ERROR: line #{num} Years married #{record[:years_married]} should not be included for #{record[:year]}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      end

      if record[:children_born_alive].present?
        if %w[1911].include?(record[:year])
          success, messagea = FreecenValidations.children_born_alive?(record[:children_born_alive])
          unless success
            messageb = "ERROR: line #{num} Number of children born alive #{record[:children_born_alive]} is #{messagea}.<br>"
            message = message + messageb
            record[:error_messages] = record[:error_messages] + messageb
          end
        else
          messageb = "ERROR: line #{num} Number of children born alive #{record[:children_born_alive]} should not be included for #{record[:year]}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      end

      if record[:children_living].present?
        if %w[1911].include?(record[:year])
          success, messagea = FreecenValidations.children_living?(record[:children_living])
          unless success
            messageb = "ERROR: line #{num} Number of children living #{record[:children_living]} is #{messagea}.<br>"
            message = message + messageb
            record[:error_messages] = record[:error_messages] + messageb
          end
        else
          messageb = "ERROR: line #{num} Number of children living #{record[:children_living]} should not be included for #{record[:year]}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      end

      if record[:children_deceased].present?
        if %w[1911].include?(record[:year])
          success, messagea = FreecenValidations.children_deceased?(record[:children_deceased])
          unless success
            messageb = "ERROR: line #{num} Number of children deceased #{record[:children_deceased]} is #{messagea}.<br>"
            message = message + messageb
            record[:error_messages] = record[:error_messages] + messageb
          end
        else
          messageb = "ERROR: line #{num} Number of children deceased #{record[:children_deceased]} should not be included for #{record[:year]}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      end

      if record[:religion].present?
        if %w[1901 1911].include?(record[:year])
          success, messagea = FreecenValidations.religion?(record[:religion])
          unless success
            messageb = "ERROR: line #{num} Religion #{record[:religion]} is #{messagea}.<br>"
            message = message + messageb
            record[:error_messages] = record[:error_messages] + messageb
          end
        else
          messageb = "ERROR: line #{num} Religion #{record[:religion]} should not be included for #{record[:year]}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      end

      if record[:read_write].present?
        if %w[1901 1911].include?(record[:year])
          success, messagea = FreecenValidations.read_write?(record[:read_write])
          unless success
            messageb = "ERROR: line #{num} Ability to read and write #{record[:read_write]} is #{messagea}.<br>"
            message = message + messageb
            record[:error_messages] = record[:error_messages] + messageb
          end
        else
          messageb = "ERROR: line #{num} Ability to read and write #{record[:read_write]} should not be included for #{record[:year]}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      end

      success, messagea = FreecenValidations.uncertainty_status?(record[:individual_flag])
      unless success
        messageb = "ERROR: line #{num} Individual Flag #{record[:individual_flag]} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messageb
      end

      success, messagea = FreecenValidations.occupation?(record[:occupation], record[:age])
      unless success
        if messagea == '?'
          messageb = "Warning: line #{num} Occupation #{record[:occupation]} has trailing ?. Removed and flag set.<br>"
          message = message + messageb
          record[:warning_messages] = record[:warning_messages] + messageb
          record[:occupation_flag] = 'x'
          record[:occupation] = record[:occupation][0...-1].strip
        elsif messagea == 'unusual use of Scholar'
          messageb = "Warning: line #{num} Occupation #{record[:occupation]} is #{messagea}.<br>"
          message = message + messageb
          record[:warning_messages] = record[:warning_messages] + messageb
        else
          messageb = "ERROR: line #{num} Occupation #{record[:occupation]} is #{messagea}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      end

      if record[:industry].present?
        if %w[1911].include?(record[:year])
          success, messagea = FreecenValidations.industry?(record[:industry])
          unless success
            messageb = "ERROR: line #{num} Industry #{record[:industry]} is #{messagea}.<br>"
            message = message + messageb
            record[:error_messages] = record[:error_messages] + messageb
          end
        else
          messageb = "ERROR: line #{num} Industry #{record[:industry]} should not be included for #{record[:year]}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      end

      if record[:occupation_category].present?
        if %w[1891 1901 1911].include?(record[:year])
          success, messagea = FreecenValidations.occupation_category?(record[:occupation_category])
          unless success
            messageb = "ERROR: line #{num} Occupation category #{record[:occupation_category]} is #{messagea}.<br>"
            message = message + messageb
            record[:error_messages] = record[:error_messages] + messageb
          end
        else
          messageb = "ERROR: line #{num} Occupation category #{record[:occupation_category]} should not be included for #{record[:year]}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      end

      if record[:at_home].present?
        if %w[1901 1911].include?(record[:year])
          success, messagea = FreecenValidations.at_home?(record[:at_home])
          unless success
            messageb = "ERROR: line #{num} Working at home #{record[:at_home]} is #{messagea}.<br>"
            message = message + messageb
            record[:error_messages] = record[:error_messages] + messageb
          end
        else
          messageb = "ERROR: line #{num} Working at home #{record[:at_home]} should not be included for #{record[:year]}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      end

      success, messagea = FreecenValidations.uncertainty_occupation?(record[:occupation_flag])
      unless success
        messageb = "ERROR: line #{num} Occupation Flag #{record[:occupation_flag]} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messageb
      end

      success, messagea = FreecenValidations.verbatim_birth_county?(record[:verbatim_birth_county])
      unless success
        messageb = "ERROR: line #{num} Verbatim Birth County #{record[:verbatim_birth_county]} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messageb
      end


      if record[:year] == '1841'
        if record[:verbatim_birth_place].present?
          messageb = "ERROR: line #{num} Verbatim Birth Place #{record[:verbatim_birth_place]} should not be included for #{record[:year]}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      else
        success, messagea = FreecenValidations.verbatim_birth_place?(record[:verbatim_birth_place])
        unless success
          messageb = "ERROR: line #{num} Verbatim Birth Place #{record[:verbatim_birth_place]} is #{messagea}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      end

      if record[:nationality].present?
        unless %w[1841].include?(record[:year])
          success, messagea = FreecenValidations.nationality?(record[:nationality])
          unless success
            messageb = "ERROR: line #{num} Nationality #{record[:nationality]} is #{messagea}.<br>"
            message = message + messageb
            record[:error_messages] = record[:error_messages] + messageb
          end
        else
          messageb = "ERROR: line #{num} Nationality #{record[:nationality]} should not be included for #{record[:year]}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      end

      success, messagea = FreecenValidations.verbatim_birth_county?(record[:birth_county])
      unless success || messagea == 'blank'
        messageb = "ERROR: line #{num} Birth County #{record[:birth_county]} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messageb
      end

      if record[:year] == '1841'
        if record[:birth_place].present?
          messageb = "ERROR: line #{num} Birth Place #{record[:birth_place]} should not be included for #{record[:year]}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      else
        success, messagea = FreecenValidations.birth_place?(record[:birth_place])
        unless success || messagea == 'blank'
          messageb = "ERROR: line #{num} Birth Place #{record[:birth_place]} is #{messagea}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end

      end

      if record[:father_place_of_birth].present?
        if record[:year] == '1911'
          success, messagea = FreecenValidations.father_place_of_birth?(record[:father_place_of_birth])
          unless success
            messageb = "ERROR: line #{num} Father's place of birth #{record[:father_place_of_birth]} is #{messagea}.<br>"
            message = message + messageb
            record[:error_messages] = record[:error_messages] + messageb
          end
        else
          messageb = "ERROR: line #{num} Father's place of birth #{record[:father_place_of_birth]} should not be included for #{record[:year]}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      end

      success, messagea = FreecenValidations.uncertainy_birth?(record[:uncertainy_birth])
      unless success
        messageb = "ERROR: line #{num} Birth uncertainty #{record[:uncertainy_birth]} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messageb
      end

      if record[:year] == '1841'
        if record[:disability].present?
          messageb = "ERROR: line #{num} Disability #{record[:disability]} should not be included for #{record[:year]}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      else
        success, messagea = FreecenValidations.disability?(record[:disability])
        unless success
          messageb = "ERROR: line #{num} Disability #{record[:disability]} is #{messagea}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      end

      if record[:disability_notes].present?
        if record[:year] == '1911'
          success, messagea = FreecenValidations.disability_notes?(record[:disability_notes])
          unless success
            messageb = "ERROR: line #{num} Disability Notes #{record[:disability_notes]} is #{messagea}.<br>"
            message = message + messageb
            record[:error_messages] = record[:error_messages] + messageb
          end
        else
          messageb = "ERROR: line #{num} Disability Notes #{record[:disability_notes]} should not be included for #{record[:year]}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      end

      if record[:language].present?
        if %w[1881 1891 1901 1911].include?(record[:year])
          success, messagea = FreecenValidations.language?(record[:language])
          unless success
            messageb = "ERROR: line #{num} Language #{record[:language]} is #{messagea}.<br>"
            message = message + messageb
            record[:error_messages] = record[:error_messages] + messageb
          end
        else
          messageb = "Warning: line #{num} Language #{record[:language]} should not be included for #{record[:year]}.<br>"
          message = message + messageb
          record[:error_messages] = record[:error_messages] + messageb
        end
      end

      success, messagea = FreecenValidations.notes?(record[:notes])
      unless success
        messageb = "ERROR: line #{num} Notes #{record[:notes]} is #{messagea}.<br>"
        message = message + messageb
        record[:error_messages] = record[:error_messages] + messageb
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
    pc_id = freecen2_piece_id
    if idx && idx >= 0
      prev_dwel = FreecenDwelling.where(freecen2_piece_id: pc_id, dwelling_number: (idx - 1)).first
      prev_id = prev_dwel[:_id] unless prev_dwel.nil?
      next_dwel = FreecenDwelling.where(freecen2_piece_id: pc_id, dwelling_number: (idx + 1)).first
      next_id = next_dwel[:_id] unless next_dwel.nil?
    end
    [prev_id, next_id]
  end

  # labels/vals for dwelling page header section (body in freecen_individuals)
  def self.census_display_labels(year, chapman_code)
    # 1841 doesn't have ecclesiastical parish or schedule number
    # Scotland doesn't have folio
    case year
    when '1841'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Quaord Sacra', 'Census Place', 'Piece', 'Enumeration District', 'Ward', 'Constituency', 'Folio', 'Page']
      else
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Where Census Taken', 'Piece',  'Constituency', 'Folio', 'Page']
      end
    when '1851'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Where Census Taken', 'Piece',  'Ward', 'Constituency','Folio', 'Page']
      else
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Ecclesiastical Parish', 'Census Place', 'Piece', 'Constituency', 'Folio', 'Page']
      end
    when '1861'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Quaord Sacra', 'Where Census Taken', 'Piece', 'Ward', 'Constituency', 'Page']
      else
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Ecclesiastical Parish', 'Where Census Taken', 'Piece', 'Ward', 'Constituency', 'Folio', 'Page']
      end
    when '1871'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Quaord Sacra', 'Where Census Taken', 'Piece', 'Ward', 'Constituency', 'Police District', 'Page']
      else
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Ecclesiastical Parish', 'Where Census Taken', 'Piece', 'Ward', 'Constituency', 'Folio', 'Page']
      end
    when '1881'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Quaord Sacra', 'Where Census Taken', 'Piece', 'Ward', 'Constituency', 'Police District', 'School Board', 'Folio', 'Page']
      else
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Ecclesiastical Parish', 'Where Census Taken', 'Piece',  'Ward', 'Constituency', 'Sanitary District', 'Folio', 'Page']
      end
    when '1891'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Quaord Sacra', 'Where Census Taken', 'Piece', 'Ward', 'Constituency', 'Police District', 'School Board', 'Folio', 'Page']
      else
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Ecclesiastical Parish', 'Where Census Taken', 'Piece',  'Ward', 'Constituency', 'Sanitary District', 'Folio', 'Page']
      end
    when '1901'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Quaord Sacra', 'Where Census Taken', 'Piece', 'Ward', 'Constituency', 'Police District',  'School Board', 'Folio', 'Page']
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Where Census Taken', 'Piece', 'Ward', 'Constituency', 'Poor Law Union', 'Police District', 'Page']
      else
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Ecclesiastical Parish', 'Where Census Taken', 'Piece', 'Ward', 'Constituency', 'Folio', 'Page']
      end
    when '1911'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Quaord Sacra', 'Where Census Taken', 'Piece', 'Ward', 'Constituency', 'Sanitary District', 'Scavenging District', 'Special Lighting District', 'School Board', 'Page']
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Where Census Taken', 'Piece', 'Ward', 'Constituency', 'Poor Law Union', 'Police District', 'Page']
      else
        ['Census Year', 'County', 'Census District', 'Enumeration District', 'Civil Parish', 'Ecclesiastical Parish', 'Where Census Taken', 'Piece', 'Ward', 'Constituency', 'Folio', 'Page']
      end
    end
  end

  def census_display_values(year, chapman_code)
    #1841 doesn't have ecclesiastical parish or schedule number
    #Scotland doesn't have folio
    freecen2_piece = freecen_csv_file.freecen2_piece
    district_name = freecen2_piece.district_name.titleize if freecen2_piece.district_name.present?
    ecclesiastical = ecclesiastical_parish.titleize if ecclesiastical_parish.present?
    civil = civil_parish.titleize if civil_parish.present?
    address = house_or_street_name.titleize if house_or_street_name.present?
    disp_county = '' + ChapmanCode.name_from_code(chapman_code) + ' (' + chapman_code + ')' unless chapman_code.nil?
    taken = where_census_taken.titleize if where_census_taken.present?
    case year
    when '1841'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [freecen2_piece.year, disp_county, district_name, civil, enumeration_district, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency, folio_number, page_number]
      else
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, taken, freecen2_piece.number.to_s,
         parliamentary_constituency, folio_number, page_number]
      end
    when '1851'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency, folio_number, page_number]
      else
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         parliamentary_constituency, folio_number, page_number]
      end
    when '1861'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency, folio_number, page_number]
      else
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency, folio_number, page_number]
      end
    when '1871'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency, police_district, folio_number, page_number]
      else
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency, folio_number, page_number]
      end
    when '1881'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency, police_district, school_board, folio_number, page_number]
      else
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency, sanitary_district, folio_number, page_number]
      end
    when '1891'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency, police_district, school_board, folio_number, page_number]
      else
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency, sanitary_district, folio_number, page_number]
      end
    when '1901'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency, police_district, school_board, folio_number, page_number]
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency, poor_law_union, police_district, folio_number, page_number]
      else
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency, folio_number, page_number]
      end
    when '1911'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency, sanitary_district, scavenging_district, special_lighting_district, school_board, folio_number, page_number]
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency, poor_law_union, police_district, folio_number, page_number]
      else
        [freecen2_piece.year, disp_county, district_name, enumeration_district, civil, ecclesiastical, taken, freecen2_piece.number.to_s,
         ward, parliamentary_constituency, folio_number, page_number]
      end
    end
  end

  def self.dwelling_display_labels(year, chapman_code)
    case year
    when '1841'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['House Number', 'House or Street Name', 'Dwelling Number (Comp)']
      else
        ['House Number', 'House or Street Name', 'Dwelling Number (Comp)']
      end
    when '1851'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Schedule', 'House Number', 'House or Street Name', 'Dwelling Number (Comp)']
      else
        ['Schedule', 'House Number', 'House or Street Name', 'Dwelling Number (Comp)']
      end
    when '1861'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Schedule', 'House Number', 'House or Street Name', 'Rooms with Windows', 'Dwelling Number (Comp)']
      else
        ['Schedule', 'House Number', 'House or Street Name', 'Dwelling Number (Comp)']
      end
    when '1871'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Schedule', 'House Number', 'House or Street Name', 'Rooms with Windows', 'Dwelling Number (Comp)']
      else
        ['Schedule', 'House Number', 'House or Street Name', 'Dwelling Number (Comp)']
      end
    when '1881'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Schedule', 'House Number', 'House or Street Name', 'Rooms with Windows', 'Dwelling Number (Comp)']
      else
        ['Schedule', 'House Number', 'House or Street Name', 'Dwelling Number (Comp)']
      end
    when '1891'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Schedule', 'House Number', 'House or Street Name', 'Rooms with Windows', 'Dwelling Number (Comp)']
      else
        ['Schedule', 'House Number', 'House or Street Name', 'Dwelling Number (Comp)']
      end
    when '1901'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Schedule', 'House Number', 'House or Street Name', 'Rooms with Windows', 'Dwelling Number (Comp)']
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        ['Schedule', 'House Number', 'House or Street Name', 'Walls', 'Roof Type', 'Rooms', 'Rooms with Windows', 'Class of House', 'Dwelling Number (Comp)']
      else
        ['Schedule', 'House Number', 'House or Street Name', 'Rooms', 'Dwelling Number (Comp)']
      end
    when '1911'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Schedule', 'House Number', 'House or Street Name', 'Rooms with Windows', 'Dwelling Number (Comp)']
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        ['Schedule', 'House Number', 'House or Street Name', 'Walls', 'Roof Type', 'Rooms', 'Rooms with Windows', 'Class of House', 'Dwelling Number (Comp)']
      else
        ['Schedule', 'House Number', 'House or Street Name', 'Rooms', 'Dwelling Number (Comp)']
      end
    end
  end

  def dwelling_display_values(year, chapman_code)
    address = house_or_street_name.titleize if house_or_street_name.present?
    case year
    when '1841'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [house_number, address, dwelling_number]
      else
        [house_number, address, dwelling_number]
      end
    when '1851'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [schedule_number, house_number, address, dwelling_number]
      else
        [schedule_number, house_number, address, dwelling_number]
      end
    when '1861'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [schedule_number, house_number, address, rooms_with_windows, dwelling_number]
      else
        [schedule_number, house_number, address, dwelling_number]
      end
    when '1871'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [schedule_number, house_number, address, rooms_with_windows, dwelling_number]
      else
        [schedule_number, house_number, address, dwelling_number]
      end
    when '1881'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [schedule_number, house_number, address, rooms_with_windows, dwelling_number]
      else
        [schedule_number, house_number, address, dwelling_number]
      end
    when '1891'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [schedule_number, house_number, address, rooms_with_windows, dwelling_number]
      else
        [schedule_number, house_number, address, dwelling_number]
      end
    when '1901'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [schedule_number, house_number, address, rooms_with_windows, dwelling_number]
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        [schedule_number, house_number, address, walls, roof_type, rooms, rooms_with_windows, class_of_house, dwelling_number]
      else
        [schedule_number, house_number, address, rooms, dwelling_number]
      end
    when '1911'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [schedule_number, house_number, address, rooms_with_windows, dwelling_number]
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        [schedule_number, house_number, address, walls, roof_type, rooms, rooms_with_windows, class_of_house, dwelling_number]
      else
        [schedule_number, house_number, address, rooms, dwelling_number]
      end
    end
  end


  def self.management_display_labels
    ['Transition', 'Location Flag', 'Address Flag', 'Name Flag', 'Individual Flag', 'Occupation Flag', 'Birth Place Flag', 'Deleted Flag']
  end

  def management_display_values
    [data_transition, location_flag, address_flag, name_flag, individual_flag, occupation_flag, birth_place_flag, deleted_flag]
  end

  def self.error_display_labels
    ['Errors Messages', 'Warning Messages', 'Info Messages']
  end

  def error_display_values
    error_message = error_messages.gsub(/\<br\>/, '').gsub(/ERROR:/i, '').titleize if error_messages.present?
    warning_message = warning_messages.gsub(/\<br\>/, '').gsub(/Warning:/i, '').titleize if warning_messages.present?
    info_message = info_messages.gsub(/\<br\>/, '').gsub(/Info:/i, '').titleize if info_messages.present?
    [error_message, warning_message, info_message]
  end

  def self.individual_display_labels(year, chapman_code)
    case year
    when '1841'
      ['Sequence (Comp)', 'Surname', 'Forenames', 'Sex', 'Age', 'Occupation', 'Verbatim Birth County', 'Notes']
    when '1851'
      ['Sequence (Comp)', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation']
    when '1861'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Sequence (Comp)', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'School Children' 'Occupation']
      else
        ['Sequence (Comp)', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation']
      end
    when '1871'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Sequence (Comp)', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'School Children' 'Occupation']
      else
        ['Sequence (Comp)', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation']
      end
    when '1881'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Sequence (Comp)', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'School Children' 'Occupation']
      else
        ['Sequence (Comp)', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation']
      end
    when '1891'
      # only Wales 1891 has language field
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Sequence (Comp)', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation', 'Occ Category']
      elsif ChapmanCode::CODES['Wales'].values.member?(chapman_code)
        ['Sequence (Comp)', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation', 'Occ Category']
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        ['Sequence (Comp)', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation', 'Occ Category']
      else
        ['Sequence (Comp)', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation', 'Occ Category']
      end
    when '1901'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Sequence (Comp)', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation', 'Occ Category', 'At Home']
      elsif ChapmanCode::CODES['Wales'].values.member?(chapman_code)
        ['Sequence (Comp)', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation', 'Occ Category', 'At Home']
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        ['Sequence (Comp)', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Religion', 'Read and Write', 'Occupation', 'Occ Category']
      else
        ['Sequence (Comp)', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Occupation', 'Occ Category', 'At Home']
      end
    when '1911'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Sequence (Comp)', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Years Married', 'Children Born Alive', 'Children Living', 'Occupation', 'Occ Category', 'Industry', 'At Home']
      elsif ChapmanCode::CODES['Wales'].values.member?(chapman_code) || chapman_code == 'IOM'
        ['Sequence (Comp)', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Years Married', 'Children Born Alive', 'Children Living', 'Children Deceased', 'Occupation', 'Occ Category', 'Industry', 'At Home']
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        ['Sequence (Comp)', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Years Married', 'Children Born Alive', 'Children Living', 'Religion', 'Read and Write', 'Occupation', 'Occ Category']
      elsif  %w[CHI ALD GSY JSY].include?(chapman_code)
        ['Sequence (Comp)', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Years Married', 'Children Born Alive', 'Children Living', 'Children Deceased', 'Occupation', 'Occ Category', 'Industry', 'At Home']
      else
        ['Sequence (Comp)', 'Surname', 'Forenames', 'Relationship', 'Marital Status', 'Sex', 'Age', 'Years Married', 'Children Born Alive', 'Children Living', 'Children Deceased', 'Occupation', 'Occ Category', 'Industry', 'At Home']
      end
    end
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
    verbatim_county = verbatim_birth_county.upcase if verbatim_birth_county.present?
    note = notes.gsub(/\<br\>/, '').titleize if notes.present?
    sx = sex.upcase if sex.present?
    case year
    when '1841'
      [sequence_in_household, sur, fore, sx, disp_age, disp_occupation, verbatim_county, note]
    when '1851'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, school_children, disp_occupation]
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
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, disp_occupation, occupation_category]
      else
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, disp_occupation, occupation_category]
      end
    when '1901'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, disp_occupation, occupation_category, at_home]
      elsif ChapmanCode::CODES['Wales'].values.member?(chapman_code)
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, disp_occupation, occupation_category, at_home]
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, religion, read_and_write, disp_occupation, occupation_category]
      else
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, disp_occupation, occupation_category, at_home]
      end
    when '1911'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, years_married, children_born_alive, children_living, disp_occupation, occupation_category, industry, at_home]
      elsif ChapmanCode::CODES['Wales'].values.member?(chapman_code) || chapman_code == 'IOM'
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, years_married, children_born_alive, children_living, disp_occupation, occupation_category, industry, at_home]
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, years_married, children_born_alive, children_living, religion, read_and_write, disp_occupation, occupation_category]
      elsif  %w[CHI ALD GSY JSY].include?(chapman_code)
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, years_married, children_born_alive, children_living, children_deceased, disp_occupation, occupation_category, industry, at_home]
      else
        [sequence_in_household, sur, fore, relation, marital, sx, disp_age, years_married, children_born_alive, children_living, children_deceased, disp_occupation, occupation_category, industry, at_home]
      end
    end
  end

  def self.part2_individual_display_labels(year, chapman_code)
    case year
    when '1851'
      ['Nationality', 'Verbatim Birth County', 'Verbatim Birth Place', 'Alt. Birth County', 'Alt. Birth Place', 'Disability', 'Notes']
    when '1861'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Verbatim Birth County', 'Verbatim Birth Place', 'Alt. Birth County', 'Alt. Birth Place',  'Disability', 'Notes']
      else
        ['Nationality', 'Verbatim Birth County', 'Verbatim Birth Place', 'Alt. Birth County', 'Alt. Birth Place', 'Disability', 'Notes']
      end
    when '1871'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Verbatim Birth County', 'Verbatim Birth Place', 'Alt. Birth County', 'Alt. Birth Place', 'Disability', 'Notes']
      else
        ['Nationality', 'Verbatim Birth County', 'Verbatim Birth Place', 'Alt. Birth County', 'Alt. Birth Place', 'Disability', 'Notes']
      end
    when '1881'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Verbatim Birth County', 'Verbatim Birth Place', 'Alt. Birth County', 'Alt. Birth Place', 'Disability', 'Notes']
      else
        ['Nationality', 'Verbatim Birth County', 'Verbatim Birth Place', 'Alt. Birth County', 'Alt. Birth Place', 'Disability', 'Notes']
      end
    when '1891'
      # only Wales 1891 has language field
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Verbatim Birth County', 'Verbatim Birth Place', 'Alt. Birth County', 'Alt. Birth Place', 'Disability', 'Language', 'Notes']
      elsif ChapmanCode::CODES['Wales'].values.member?(chapman_code)
        ['Nationality', 'Verbatim Birth County', 'Verbatim Birth Place', 'Alt. Birth County', 'Alt. Birth Place', 'Disability', 'Notes']
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        ['Verbatim Birth County', 'Verbatim Birth Place', 'Alt. Birth County', 'Alt. Birth Place', 'Disability', 'Notes']
      else
        ['Nationality', 'Verbatim Birth County', 'Verbatim Birth Place', 'Alt. Birth County', 'Alt. Birth Place', 'Disability', 'Notes']
      end
    when '1901'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Verbatim Birth County', 'Verbatim Birth Place', 'Alt. Birth County', 'Alt. Birth Place', 'Disability', 'Language', 'Notes']
      elsif ChapmanCode::CODES['Wales'].values.member?(chapman_code)
        ['Nationality', 'Verbatim Birth County', 'Verbatim Birth Place', 'Alt. Birth County', 'Alt. Birth Place', 'Disability', 'Language', 'Notes']
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        ['Verbatim Birth County', 'Verbatim Birth Place', 'Alt. Birth County', 'Alt. Birth Place', 'Disability', 'Notes']
      else
        ['Nationality', 'Verbatim Birth County', 'Verbatim Birth Place', 'Alt. Birth County', 'Alt. Birth Place', 'Disability', 'Notes']
      end
    when '1911'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        ['Nationality', 'Verbatim Birth County', 'Verbatim Birth Place', 'Alt. Birth County', 'Alt. Birth Place', 'Disability', 'Language', 'Notes']
      elsif ChapmanCode::CODES['Wales'].values.member?(chapman_code) || chapman_code == 'IOM'
        ['Verbatim Birth County', 'Verbatim Birth Place', 'Disability', 'Alt. Birth County', 'Alt. Birth Place', 'Disability Notes', 'Language', 'Notes']
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        ['Nationality', 'Verbatim Birth County', 'Verbatim Birth Place', 'Alt. Birth County', 'Alt. Birth Place', 'Disability', 'Notes']
      elsif %w[CHI ALD GSY JSY].include?(chapman_code)
        ['Nationality', 'Verbatim Birth County', 'Verbatim Birth Place', 'Alt. Birth County', 'Alt. Birth Place', "Father's Place of Birth", 'Disability', 'Notes']
      else
        ['Nationality', 'Verbatim Birth County', 'Verbatim Birth Place', 'Alt. Birth County', 'Alt. Birth Place', 'Disability', 'Disability Notes', 'Notes']
      end
    end
  end

  def part2_individual_display_values(year, chapman_code)
    birth = verbatim_birth_place.titleize if verbatim_birth_place.present?
    selected_birth = birth_place.titleize if birth_place.present?
    verbatim_county = verbatim_birth_county.upcase if verbatim_birth_county.present?
    note = notes.gsub(/\<br\>/, '').titleize if notes.present?
    case year
    when '1851'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [verbatim_county, birth, birth_county, selected_birth, disability, note]
      else
        [nationality, verbatim_county, birth, birth_county, selected_birth, disability, note]
      end
    when '1861'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [verbatim_county, birth, birth_county, selected_birth, disability, note]
      else
        [nationality, verbatim_county, birth, birth_county, selected_birth, disability, note]
      end
    when '1871'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [verbatim_county, birth, birth_county, selected_birth, disability, note]
      else
        [nationality, verbatim_county, birth, birth_county, selected_birth, disability, note]
      end
    when '1881'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [verbatim_county, birth, birth_county, selected_birth, disability, note]
      else
        [nationality, verbatim_county, birth, birth_county, selected_birth, disability, note]
      end

    when '1891'
      # only Wales 1891 has language field
      if ChapmanCode::CODES['Wales'].values.member?(chapman_code) || ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [verbatim_county, birth, birth_county, selected_birth, disability, language, note]
      else
        [nationality, verbatim_county, birth, birth_county, selected_birth, disability, note]
      end
    when '1901'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [verbatim_county, birth, birth_county, selected_birth, disability, language, note]
      elsif ChapmanCode::CODES['Wales'].values.member?(chapman_code)
        [nationality, verbatim_county, birth, birth_county, selected_birth, disability, language, note]
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        [verbatim_county, birth, birth_county, selected_birth, disability, language, note]
      else
        [nationality, verbatim_county, birth, birth_county, selected_birth, disability, note]
      end
    when '1911'
      if ChapmanCode::CODES['Scotland'].values.member?(chapman_code)
        [nationality, verbatim_county, birth, birth_county, selected_birth, disability, language, note]
      elsif ChapmanCode::CODES['Wales'].values.member?(chapman_code) || chapman_code == 'IOM'
        [nationality, verbatim_county, birth, birth_county, selected_birth, disability, diability_notes, language, note]
      elsif ChapmanCode::CODES['Ireland'].values.member?(chapman_code)
        [verbatim_county, birth, birth_county, selected_birth, disability, language, note]
      elsif %w[CHI ALD GSY JSY].include?(chapman_code)
        [nationality, verbatim_county, birth, birth_county, selected_birth, father_place_of_birth, disability, disability_notes, language, note]
      else
        [nationality, verbatim_county, birth, birth_county, selected_birth, disability, disability_notes, note]
      end
    end
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
