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
      the_digest = hex_to_base64_digest(md5.hexdigest(string))
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
      logger.warn("FREEREG:LOCATION:VALIDATION invalid freecen_csv_entry id #{freecen_csv_entry} ") unless result
      result
    end


    def validate_header(record, num, flexible)
      overall_success = true
      if flexible
        # new code tests

        message = 'mine'
      else
        message = ''
        if record[:data_transition] = 'Civil Parish'
          success, messagea = FreecenValidations.fixed_valid_civil_parish?(record[:civil_parish])
          unless success
            overall_success = false
            message = message + "Error: Civil Parish on line #{num} has too many characters #{record[:civil_parish]}<br> " if messagea == 'field length'
            message = message + "Error: Civil Parish on line #{num} is blank #{record[:civil_parish]}<br>" if messagea == 'blank'
            message = message + "Error: Civil Parish on line #{num} has invalid text #{record[:civil_parish]}<br>" if messagea == 'VALID_TEXT'
          end
        end
        if ['Enumeration District', 'Civil Parish'].include?(record[:data_transition])
          success, messagea = FreecenValidations.fixed_enumeration_district?(record[:enumeration_district])
          unless success
            overall_success = false
            message = message + "Error: Enumeration District #{record[:civil_parish]} is #{messagea}<br>"
          end
        end
        if ['Enumeration District', 'Civil Parish', 'Folio'].include?(record[:data_transition])
          success, messagea = FreecenValidations.fixed_folio_number?(record[:folio_number])
          unless success
            overall_success = false
            message = message + "Error: Folio number #{record[:folio_number]} is #{messagea}<br>"
          end
        end
        if ['Enumeration District', 'Civil Parish', 'Folio', 'Page'].include?(record[:data_transition])
          success, messagea = FreecenValidations.fixed_page_number?(record[:page_number])
          unless success
            overall_success = false
            message = message + "Error: Page number #{record[:page_number]} is #{messagea}<br>"
          end
        end
        [overall_success, message]
      end

      def validate_dwelling(record, num, flexible)
        p 'validate_dwelling'
        overall_success = true
        if flexible
          # new code tests

          message = 'mine'
        else
          message = ''
          success, messagea = FreecenValidations.fixed_schedule_number?(record[:schedule_number])
          unless success
            overall_success = false
            message = message + "Error: Schedule number #{record[:schedule_number]} is #{messagea}<br>"
          end
          success, messagea = FreecenValidations.fixed_house_number?(record[:house_number])
          unless success
            overall_success = false
            message = message + "Error: House number #{record[:house_number]} is #{messagea}<br>"
          end

          success, messagea = FreecenValidations.fixed_house_address?([:house_address])
          unless success
            overall_success = false
            message = message + "Error: House address #{record[:house_number]} is #{messagea}<br>"
          end
          success, messagea = FreecenValidations.fixed_uncertainy_location?([:uncertainy_location])
          unless success
            overall_success = false
            message = message + "Error: Special use #{record[:uncertainy_location]} is #{messagea}<br>"
          end
        end
        [overall_success, message]
      end

      def validate_individual(record, num, flexible)
        p 'validate_individual'
        overall_success = true
        if flexible
          # new code tests

          message = 'mine'
        else
          message = ''
          success, messagea = FreecenValidations.fixed_surname?(record[:surname])
          unless success
            overall_success = false
            message = message + "Error: Surname #{record[:surname]} is #{messagea}<br>"
          end
          success, messagea = FreecenValidations.fixed_forenames?(record[:forenames])
          unless success
            overall_success = false
            message = message + "Error: Surname #{record[:forenames]} is #{messagea}<br>"
          end
          success, messagea = FreecenValidations.fixed_name_question?(record[:uncertainty_name])
          unless success
            overall_success = false
            message = message + "Error: Forenames #{record[:uncertainty_name]} is #{messagea}<br>"
          end
          success, messagea = FreecenValidations.fixed_relationship?(record[:relationship])
          unless success
            overall_success = false
            message = message + "Error: Relationship #{record[:relationship]} is #{messagea}<br>"
          end
          success, messagea = FreecenValidations.fixed_marital_status?(record[:marital_status])
          unless success
            overall_success = false
            message = message + "Error: Marital status #{record[:marital_status]} is #{messagea}<br>"
          end
          success, messagea = FreecenValidations.fixed_sex?(record[:sex])
          unless success
            overall_success = false
            message = message + "Error: Sex #{record[:sex]} is #{messagea}<br>"
          end
          success, messagea = FreecenValidations.fixed_age?(record[:age], record[:marital_status], record[:sex])
          unless success
            overall_success = false
            message = message + "Error: Age #{record[:age]} is #{messagea}<br>"
          end
          success, messagea = FreecenValidations.fixed_uncertainty_status?(record[:uncertainty_status])
          unless success
            overall_success = false
            message = message + "Error: Query #{record[:uncertainty_status]} is #{messagea}<br>"
          end
          success, messagea = FreecenValidations.fixed_occupation?(record[:occupation], record[:age] )
          unless success
            overall_success = false
            message = message + "Error: Occupation #{record[:occupation]} is #{messagea}<br>"
          end
          success, messagea = FreecenValidations.fixed_occupation_category?(record[:occupation_category])
          unless success
            overall_success = false
            message = message + "Error: Occupation category #{record[:occupation_category]} is #{messagea}<br>"
          end
          success, messagea = FreecenValidations.fixed_uncertainty_occupation?(record[:uncertainty_occupation])
          unless success
            overall_success = false
            message = message + "Error: Occupation uncertainty #{record[:uncertainty_occupation]} is #{messagea}<br>"
          end
          success, messagea = FreecenValidations.fixed_verbatim_birth_county?(record[:verbatim_birth_county])
          unless success
            overall_success = false
            message = message + "Error: Birth County #{record[:verbatim_birth_county]} is #{messagea}<br>"
          end
          success, messagea = FreecenValidations.fixed_verbatim_birth_place?(record[:verbatim_birth_place])
          unless success
            overall_success = false
            message = message + "Error: Birth Place #{record[:verbatim_birth_place]} is #{messagea}<br>"
          end
          success, messagea = FreecenValidations.fixed_uncertainy_birth?(record[:uncertainy_birth])
          unless success
            overall_success = false
            message = message + "Error: Birth uncertainty #{record[:uncertainy_birth]} is #{messagea}<br>"
          end
          success, messagea = FreecenValidations.fixed_disability?(record[:disability])
          unless success
            overall_success = false
            message = message + "Error: Disability #{record[:disability]} is #{messagea}<br>"
          end
          success, messagea = FreecenValidations.fixed_language?(record[:language])
          unless success
            overall_success = false
            message = message + "Error: Language #{record[:language]} is #{messagea}<br>"
          end
          success, messagea = FreecenValidations.fixed_notes?(record[:notes])
          unless success
            overall_success = false
            message = message + "Error: Notes #{record[:notes]} is #{messagea}<br>"
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
          show,transcribed_by = UseridDetail.can_we_acknowledge_the_transcriber(transcriber)
          credit = file.credit_name
        else
          transcribed_by = nil
          credit = nil
        end
        self.update_attributes(:transcribed_by => transcribed_by, :credit => credit)
      end

      def add_additional_location_fields(batch)
        register = batch.register
        church = register.church
        place_object = church.place
        church_name = church.church_name
        place = place_object.place_name
        county = batch.chapman_code # note that the record carries the chapman code in the county field
        [place_object, church, register]
      end

      def add_digest
        self.record_digest = self.cal_digest
      end

      def adjust_parameters(param)
        param[:year] = get_year(param, year)
        param[:processed_date] = Time.now
        param
      end

      def already_has_this_embargo?(rule)
        return false if embargo_records.blank?

        return true if embargo_records.last.already_applied?(rule)

        false
      end



      def captitalize_surnames
        self.bride_father_surname = self.bride_father_surname.upcase if self.bride_father_surname.present?
        self.bride_mother_surname = self.bride_mother_surname.upcase if self.bride_mother_surname.present?
        self.bride_surname = self.bride_surname.upcase if self.bride_surname.present?
        self.burial_person_surname = self.burial_person_surname.upcase if self.burial_person_surname.present?
        self.father_surname = self.father_surname.upcase if self.father_surname.present?
        self.groom_father_surname = self.groom_father_surname.upcase if self.groom_father_surname.present?
        self.groom_mother_surname = self.groom_mother_surname.upcase if self.groom_mother_surname.present?
        self.groom_surname = self.groom_surname.upcase if self.groom_surname.present?
        self.mother_surname = self.mother_surname.upcase if self.mother_surname.present?
        self.relative_surname = self.relative_surname.upcase if self.relative_surname.present?
        self.person_surname = self.person_surname.upcase if self.person_surname.present?
        self.female_relative_surname = self.female_relative_surname.upcase if self.female_relative_surname.present?
      end

      def check_and_correct_county
        search_record = self.search_record
        if search_record.present?
          place_id = search_record.place_id
          place = Place.id(place_id).first
          if self.county.blank?
            self.update_attribute(:county, place.chapman_code) if place.present?
          else
            unless ChapmanCode.value?(self.county)
              self.update_attribute(:county, place.chapman_code) if place.present?
            end
          end
        end
      end

      def check_year
        old_year = self.year
        case self.record_type
        when 'ba'
          new_year = FreeregValidations.year_extract(self.baptism_date)
          new_year = FreeregValidations.year_extract(self.birth_date) if new_year.blank?
          new_year = FreeregValidations.year_extract(self.confirmation_date) if new_year.blank?
          new_year = FreeregValidations.year_extract(self.received_into_church_date) if new_year.blank?
        when 'ma'
          new_year = FreeregValidations.year_extract(self.marriage_date)
          new_year = FreeregValidations.year_extract(self.contract_date) if new_year.blank?
        when 'bu'
          new_year = FreeregValidations.year_extract(self.burial_date)
          new_year = FreeregValidations.year_extract(self.death_date) if new_year.blank?
        end
        return if  old_year == new_year
        return if new_year.blank? && old_year.blank?
        self.update_attribute(:year, new_year)
        return
      end

      def check_register_type
        errors.add(:register_type, "Invalid register type") unless RegisterType::OPTIONS.values.include?(self.register_type)
      end

      def clean_up_ucf_list
        entry = self
        file = entry.freecen_csv_file
        place, _church, _register = file.location_from_file
        search_record = entry.search_record
        file.ucf_list.delete_if { |record| record.to_s == search_record.id.to_s }
        file.ucf_updated = DateTime.now.to_date
        file.save
        if place.present?
          place.ucf_list[file.id.to_s].delete_if { |record| record.to_s == search_record.id.to_s }
          place.save
        end
      end

      def create_baptism_string
        fields = FreeregOptionsConstants::ORIGINAL_BAPTISM_FIELDS + FreeregOptionsConstants::ADDITIONAL_BAPTISM_FIELDS + FreeregOptionsConstants::ORIGINAL_COMMON_FIELDS + FreeregOptionsConstants::ADDITIONAL_COMMON_FIELDS
        my_string = self.create_string(fields)
        return my_string
      end

      def create_burial_string
        fields = FreeregOptionsConstants::ORIGINAL_BURIAL_FIELDS + FreeregOptionsConstants::ADDITIONAL_BURIAL_FIELDS + FreeregOptionsConstants::ORIGINAL_COMMON_FIELDS + FreeregOptionsConstants::ADDITIONAL_COMMON_FIELDS
        my_string = self.create_string(fields)
        return my_string
      end

      def create_marriage_string
        fields = FreeregOptionsConstants::ORIGINAL_MARRIAGE_FIELDS + FreeregOptionsConstants::ADDITIONAL_MARRIAGE_FIELDS + FreeregOptionsConstants::ORIGINAL_COMMON_FIELDS + FreeregOptionsConstants::ADDITIONAL_COMMON_FIELDS
        my_string = self.create_string(fields)
        return my_string
      end

      def create_string(fields)
        my_string = ''
        fields.each do |field|
          if !!self[field.to_sym] == self[field.to_sym]
            self[field.to_sym] ? hold = "true" : hold = "false"
            my_string = my_string +  hold + field.to_s unless self[field.to_sym].blank?
          else
            my_string = my_string + self[field.to_sym].strip + field.to_s unless self[field.to_sym].blank?
          end
        end
        my_string
      end

      def get_location_ids
        file = self.freecen_csv_file
        if file.present?
          extended_def = file.def
          register = file.register
          if register.present?
            church = register.church
            if church.present?
              place = church.place
              if place.present?
                place_id = place.id
                church_id = church.id
                register_id = register.id
              end
            end
          end
        end
        return place_id, church_id, register_id,extended_def
      end

      def get_record_type
        return record_type if RecordType.all_types.include?(record_type)

        return search_record.record_type if search_record.present? && RecordType.all_types.include?(search_record.record_type)

        logger.warn "#{MyopicVicar::Application.config.freexxx_display_name} get_record_type missing"
        logger.warn inspect
        crash
      end

      def date_beyond_cutoff?(date_string, cutoff)
        current_year = Time.now.year
        return (current_year - cutoff) < extract_year(date_string)
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

      def embargoed?
        case self.record_type
        when RecordType::BAPTISM
          date_beyond_cutoff?(self.baptism_date, 100)
        when RecordType::MARRIAGE
          date_beyond_cutoff?(self.marriage_date, 75)
        when RecordType::BURIAL
          date_beyond_cutoff?(self.burial_date, 5)
        else
          false
        end
      end

      def enough_name_fields?
        process = false
        case self.record_type
        when "ba"
          process = true if self.person_forename.present? || self.father_forename.present? || self.mother_forename.present? ||
            self.father_surname.present? || self.mother_surname.present?
        when "bu"
          process = true if self.burial_person_forename.present? || self.male_relative_forename.present? || self.female_relative_forename.present? ||
            self.relative_surname.present? || self.burial_person_surname.present?
        when "ma"
          process = true if self.groom_forename.present? || self.groom_surname.present? || self.bride_forename.present? ||
            self.bride_surname.present? || self.groom_father_forename.present? || self.groom_father_surname.present? || self.bride_father_surname.present? ||
            self.bride_father_forename.present? || self.multiple_witness_names?
        end
        return process
      end

      def get(date_string)
        if date_string && md = date_string.match(/(\d\d\d\d)/)
          md.captures.first.to_i
        else
          1 # assume illegible dates are old -- start with year 1
        end
      end

      def get_the_image_id(church,user,manage_user_origin,image_server_group_id,chapman_code)
        #church = Church.id('55b14c71f493fd0b910006e5').first
        image_id = nil
        if self.image_file_name.present? && church.present?
          image_server_groups = church.image_server_groups
          image_server_groups.each do |group|
            image = group.image_server_images.where(:image_file_name => self.image_file_name).first
            image_id = image.id if image.present?
            @group = group
            break if image.present?
          end
        end
        if image_id.present?
          if !self.open_data?(@group)
            if user.present?
              if !ImageServerImage.image_detail_access_allowed?(user,manage_user_origin,image_server_group_id,chapman_code)
                if !self.transcribed_by_me?(user)
                  image_id = nil
                end
              end
            else
              image_id = nil
            end
          end
        end
        image_id
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



      def multiple_witness_names?
        present = false
        self.multiple_witnesses.each do |witness|
          if  witness.witness_forename.present? || witness.witness_surname.present?
            present = true
          end
        end
        return present
      end

      def open_data?(group)
        value = false
        source = group.source
        value = true if source.present? && source.open_data
        return value
      end

      def ordered_baptism_display_fields(extended_def)
        order = []
        if extended_def
          order = order + FreeregOptionsConstants::LOCATION_FIELDS
          order = order + FreeregOptionsConstants::EXTENDED_BAPTISM_LAYOUT
          order = order + FreeregOptionsConstants::ORIGINAL_COMMON_FIELDS
          order = order + FreeregOptionsConstants::ADDITIONAL_COMMON_FIELDS
        else
          order = order + FreeregOptionsConstants::LOCATION_FIELDS
          order = order + FreeregOptionsConstants::ORIGINAL_BAPTISM_FIELDS
          order = order + FreeregOptionsConstants::ORIGINAL_COMMON_FIELDS
        end
        order = order + FreeregOptionsConstants::END_FIELDS
        order = order.uniq
        order
      end

      def ordered_burial_display_fields(extended_def)
        order = []
        if extended_def
          order = order + FreeregOptionsConstants::LOCATION_FIELDS
          order = order + FreeregOptionsConstants::EXTENDED_BURIAL_LAYOUT
          order = order + FreeregOptionsConstants::ORIGINAL_COMMON_FIELDS
          order = order + FreeregOptionsConstants::ADDITIONAL_COMMON_FIELDS
        else
          order = order + FreeregOptionsConstants::LOCATION_FIELDS
          order = order + FreeregOptionsConstants::ORIGINAL_BURIAL_FIELDS
          order = order + FreeregOptionsConstants::ORIGINAL_COMMON_FIELDS
        end
        order = order + FreeregOptionsConstants::END_FIELDS
        order = order.uniq
        order
      end

      def ordered_display_fields(extended_def)
        order = []
        order = order + FreeregOptionsConstants::END_FIELDS
        order = order + FreeregOptionsConstants::LOCATION_FIELDS
        order = order + FreeregOptionsConstants::ORIGINAL_BAPTISM_FIELDS
        order = order + FreeregOptionsConstants::ADDITIONAL_BAPTISM_FIELDS if extended_def
        order = order + FreeregOptionsConstants::ORIGINAL_BURIAL_FIELDS
        order = order + FreeregOptionsConstants::ADDITIONAL_BURIAL_FIELDS if extended_def
        order = order + FreeregOptionsConstants::ORIGINAL_MARRIAGE_FIELDS
        order = order + FreeregOptionsConstants::ADDITONAL_MARRIAGE_FIELDS if extended_def
        order = order + FreeregOptionsConstants::ORIGINAL_COMMON_FIELDS
        order = order + FreeregOptionsConstants::ADDITIONAL_COMMON_FIELDS if extended_def
        order = order + FreeregOptionsConstants::END_FIELDS
        order = order.uniq
        order
      end

      def ordered_marriage_display_fields(extended_def)
        order = []
        if extended_def
          order = order + FreeregOptionsConstants::LOCATION_FIELDS
          order = order + FreeregOptionsConstants::EXTENDED_MARRIAGE_LAYOUT
          order = order + FreeregOptionsConstants::ORIGINAL_COMMON_FIELDS
          order = order + FreeregOptionsConstants::ADDITIONAL_COMMON_FIELDS
        else
          order = order + FreeregOptionsConstants::LOCATION_FIELDS
          order = order + FreeregOptionsConstants::ORIGINAL_MARRIAGE_LAYOUT
          order = order + FreeregOptionsConstants::ORIGINAL_COMMON_FIELDS
        end
        order = order + FreeregOptionsConstants::END_FIELDS
        order = order.uniq
        order
      end

      def order_fields_for_record_type(record_type, extended_def, member)
        order = []
        array_of_entries = []
        json_of_entries = {}
        case record_type
        when 'ba'
          fields = ordered_baptism_display_fields(extended_def)
        when 'ma'
          fields = ordered_marriage_display_fields(extended_def)
        when 'bu'
          fields = ordered_burial_display_fields(extended_def)
        else
          logger.warn "#{MyopicVicar::Application.config.freexxx_display_name.upcase} get_record_type missing"
          crash
        end
        fields.each do |field|
          case field
          when 'witness'
            #this translate the embedded witness fields into specific line displays
            increment = 1
            multiple_witnesses.each do |witness|
              field_for_order = field + increment.to_s
              order << field_for_order
              forename = witness.witness_forename.present? ? witness.witness_forename.to_s : ''
              surname = witness.witness_surname.present? ? witness.witness_surname.to_s : ''
              actual_witness = forename + ' ' + surname
              actual_witness = actual_witness.strip
              self[field_for_order] = actual_witness
              array_of_entries << actual_witness
              json_of_entries[field.to_sym] = actual_witness
              increment = increment + 1
            end
          when 'film'
            if member
              order << field
              self[field].blank? ? array_of_entries << nil : array_of_entries << self[field]
              self[field].blank? ? json_of_entries[field.to_sym] = nil : json_of_entries[field.to_sym]  = self[field]
            end
          when 'film_number'
            if member
              order << field
              self[field].blank? ? array_of_entries << nil : array_of_entries << self[field]
              self[field].blank? ? json_of_entries[field.to_sym] = nil : json_of_entries[field.to_sym]  = self[field]
            end
          when 'line_id'
            if member
              order << field
              self[field].blank? ? array_of_entries << nil : array_of_entries << self[field]
              self[field].blank? ? json_of_entries[field.to_sym] = nil : json_of_entries[field.to_sym]  = self[field]
            end
          when 'error_flag'
            if member
              order << field
              self[field].blank? ? array_of_entries << nil : array_of_entries << self[field]
              self[field].blank? ? json_of_entries[field.to_sym] = nil : json_of_entries[field.to_sym]  = self[field]
            end
          else
            order << field
            self[field].blank? ? array_of_entries << nil : array_of_entries << self[field]
            self[field].blank? ? json_of_entries[field.to_sym] = nil : json_of_entries[field.to_sym]  = self[field]
          end
        end
        return  order, array_of_entries, json_of_entries
      end

      def process_embargo
        unless embargo_records.present? && embargo_records.last.who == 'register_rule'
          return [false, ''] if embargo_records.present? # individual embargo present so we will not process register rule

          return [false, ''] if freecen_csv_file.register.embargo_rules.blank? # guard to avoid there being no rules!

        end
        embargoes = freecen_csv_file.register.embargo_rules
        return [false, ''] if embargoes.blank?

        rule = embargoes.find_by(record_type: record_type)

        return [false, ''] if rule.blank? #no rule for this record type

        end_year = EmbargoRecord.process_embargo_year(rule, year)

        if embargo_records.blank? && DateTime.now.year.to_i >= end_year
          return [false, '']
        elsif embargo_records.blank?
          embargo_record = EmbargoRecord.new(embargoed: true, rule_date: rule.updated_at, rule_applied: rule.id, who: 'register_rule', why: rule.reason, when: DateTime.now, release_year: end_year, release_date: end_year)
        elsif embargo_records.present? && already_has_this_embargo?(rule)
          return [false, '']
        elsif embargo_records.present? && embargo_records.last.embargoed == false && DateTime.now.year.to_i >= end_year
          return [false, '']
        elsif embargo_records.present? && embargo_records.last.embargoed == false
          embargo_record = EmbargoRecord.new(embargoed: true, rule_date: rule.updated_at, rule_applied: rule.id, who: 'register_rule', why: rule.reason, when: DateTime.now, release_year: end_year, release_date: end_year)
        elsif embargo_records.present? && embargo_records.last.embargoed == true && DateTime.now.year.to_i >= end_year
          embargo_record = EmbargoRecord.new(embargoed: false, rule_date: rule.updated_at, rule_applied: rule.id, who: 'register_rule', why: rule.reason, when: DateTime.now, release_year: end_year, release_date: end_year)
        else
          embargo_record = EmbargoRecord.new(embargoed: true, rule_date: rule.updated_at, rule_applied: rule.id, who: 'register_rule', why: rule.reason, when: DateTime.now, release_year: end_year, release_date: end_year)
        end
        [true, embargo_record]
      end

      def same_location(record, file)
        success = true
        record_id = record.freecen_csv_file_id
        file_id = file.id
        if record_id == file_id
          success = true
        else
          success = false
        end
        success
      end

      def update_location(record, file)
        update(freecen_csv_file_id: file.id, place: record[:place], church_name: record[:church_name], register_type: record[:register_type])
      end

      def update_place_ucf_list(place, file, old_search_record)
        file_in_ucf_list = place.ucf_list.has_key?(file.id.to_s)
        search_record_has_ucf = search_record.contains_wildcard_ucf?.present? ? true : false
        # No change
        return if !file_in_ucf_list && !search_record_has_ucf

        # list there and record has
        if file_in_ucf_list && search_record_has_ucf
          return if place.ucf_list[file.id.to_s].include?(search_record.id.to_s)
          place.ucf_list[file.id.to_s].delete_if { |record| record.to_s == old_search_record.id.to_s } if old_search_record.present?
          file.ucf_list.delete_if { |record| record.to_s == old_search_record.id.to_s } if old_search_record.present? && file.ucf_list.present?
          place.ucf_list[file.id.to_s] << search_record.id
          if file.ucf_list.blank?
            file.ucf_list = []
          end
          file.ucf_list << search_record.id
          file.ucf_updated = DateTime.now.to_date
          file.save
          place.save
          return
        end
        if file_in_ucf_list && !search_record_has_ucf
          place.ucf_list[file.id.to_s].delete_if { |record| record.to_s == old_search_record.id.to_s } if old_search_record.present?
          place.ucf_list[file.id.to_s].delete_if { |record| record.to_s == search_record.id.to_s }
          file.ucf_list.delete_if { |record| record.to_s == old_search_record.id.to_s } if old_search_record.present? && file.ucf_list.present?
          file.ucf_list.delete_if { |record| record.to_s == search_record.id.to_s } if file.ucf_list.present?
          file.ucf_updated = DateTime.now.to_date
          file.save
          place.save
          return
        end

        if !file_in_ucf_list && search_record_has_ucf
          place.ucf_list[file.id.to_s] = []
          place.ucf_list[file.id.to_s] << search_record.id
          if file.ucf_list.blank?
            file.ucf_list = []
          end
          file.ucf_list << search_record.id
          file.ucf_updated = DateTime.now.to_date
          file.save
          place.save
        end
      end

      def errors_in_fields

        if freecen_csv_file.blank?
          check_embargo = false
        else
          register = freecen_csv_file.register
          if register.blank?
            check_embargo = false
          else
            embargoes = register.embargo_rules
            check_embargo = embargoes.present? ? true : false
          end
        end

        unless FreeregValidations.cleantext(register_entry_number)
          errors.add(:register_entry_number, 'Invalid characters')

        end
        unless FreeregValidations.cleantext(notes)
          errors.add(:notes, 'Invalid characters')

        end
        unless FreeregValidations.cleantext(notes_from_transcriber)
          errors.add(:notes_from_transcriber, 'Invalid characters')

        end
        unless FreeregValidations.cleantext(image_file_name)
          errors.add(:image_file_name, 'Invalid characters')

        end
        unless FreeregValidations.cleantext(film)
          errors.add(:film, 'Invalid characters')

        end
        unless FreeregValidations.cleantext(film_number)
          errors.add(:film_number, 'Invalid characters')

        end

        case
        when record_type =='ma'
          unless FreeregValidations.cleanage(bride_age)
            errors.add(:bride_age, 'Invalid age')

          end
          unless FreeregValidations.cleantext(register_entry_number)
            errors.add(:register_entry_number, 'Invalid characters')

          end
          unless FreeregValidations.cleanage(groom_age)
            errors.add(:groom_age, 'Invalid age')

          end
          unless FreeregValidations.cleantext(bride_abode)
            errors.add(:bride_abode, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(bride_condition)
            errors.add(:bride_condition, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(bride_father_forename)
            errors.add(:bride_father_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(bride_father_occupation)
            errors.add(:bride_father_occupation, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(bride_father_surname)
            errors.add(:bride_father_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(bride_mother_forename)
            errors.add(:bride_mother_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(bride_mother_surname)
            errors.add(:bride_mother_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(bride_mother_occupation)
            errors.add(:bride_mother_occupation, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(bride_forename)
            errors.add(:bride_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(bride_occupation)
            errors.add(:bride_occupation, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(bride_parish)
            errors.add(:bride_parish, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(bride_surname)
            errors.add(:bride_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(groom_abode)
            errors.add(:groom_abode, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(groom_condition)
            errors.add(:groom_condition, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(groom_father_forename)
            errors.add(:groom_father_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(groom_father_occupation)
            errors.add(:groom_father_occupation, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(groom_father_surname)
            errors.add(:groom_father_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(groom_mother_forename)
            errors.add(:groom_mother_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(groom_mother_occupation)
            errors.add(:groom_mother_occupation, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(groom_mother_surname)
            errors.add(:groom_mother_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(groom_forename)
            errors.add(:groom_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(groom_occupation)
            errors.add(:groom_occupation, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(groom_parish)
            errors.add(:groom_parish, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(groom_surname)
            errors.add(:groom_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness1_forename)
            errors.add(:witness1_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness1_surname)
            errors.add(:witness1_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness2_forename)
            errors.add(:witness2_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness2_surname)
            errors.add(:witness2_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness3_forename)
            errors.add(:witness3_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness3_surname)
            errors.add(:witness3_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness4_forename)
            errors.add(:witness4_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness4_surname)
            errors.add(:witness4_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness5_forename)
            errors.add(:witness5_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness5_surname)
            errors.add(:witness5_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness6_forename)
            errors.add(:witness6_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness6_surname)
            errors.add(:witness6_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness7_forename)
            errors.add(:witness7_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness7_surname)
            errors.add(:witness7_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness8_forename)
            errors.add(:witness8_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness8_surname)
            errors.add(:witness8_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(bride_title)
            errors.add(:bride_title, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(bride_mother_title)
            errors.add(:bride_mother_title, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(bride_father_title)
            errors.add(:bride_father_title, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(groom_title)
            errors.add(:groom_title, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(groom_father_title)
            errors.add(:groom_father_title, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(groom_mother_title)
            errors.add(:groom_mother_title, 'Invalid characters')

          end
          unless FreeregValidations.cleandate(marriage_date)
            errors.add(:marriage_date, 'Invalid date')

          end
          unless FreeregValidations.cleandate(contract_date)
            errors.add(:contract_date, 'Invalid date')

          end
          if check_embargo
            rule = embargoes.where(record_type: 'ma', period_type: 'period').first
            errors.add(:marriage_date, 'Cannot compute end of embargo as there is no record date') if rule.present? && year.blank?

          end

        when record_type =='ba'
          unless FreeregValidations.cleandate(birth_date)
            errors.add(:birth_date, 'Invalid date')

          end
          unless FreeregValidations.cleandate(baptism_date)
            errors.add(:baptism_date, 'Invalid date')

          end
          unless FreeregValidations.cleandate(confirmation_date)
            errors.add(:confirmation_date, 'Invalid date')

          end
          unless FreeregValidations.cleandate(received_into_church_date)
            errors.add(:received_into_church_date, 'Invalid date')

          end
          unless FreeregValidations.cleantext(person_forename)
            errors.add(:person_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(person_surname)
            errors.add(:person_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(person_title)
            errors.add(:person_title, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(person_condition)
            errors.add(:person_condition, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(person_status)
            errors.add(:person_status, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(person_occupation)
            errors.add(:person_occupation, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(person_place_birth)
            errors.add(:person_place_birth, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(person_occupation)
            errors.add(:person_occupation, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(person_relationship)
            errors.add(:person_relationship, 'Invalid characters')

          end
          unless FreeregValidations.cleansex(person_sex)
            errors.add(:person_sex, 'Invalid sex field')

          end
          unless FreeregValidations.cleanage(person_age)
            errors.add(:groom_age, 'Invalid age')

          end

          #following is disabled until check is improved
          #unless FreeregValidations.birth_date_less_than_baptism_date(birth_date,baptism_date)
          #errors.add(:birth_date, 'Birth date is more recent than baptism date')
          #error_flag = 'true'
          # end
          unless FreeregValidations.cleantext(person_abode)
            errors.add(:person_abode, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(father_forename)
            errors.add(:father_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(father_surname)
            errors.add(:father_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(father_title)
            errors.add(:father_title, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(father_abode)
            errors.add(:father_abode, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(father_place)
            errors.add(:father_place, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(father_county)
            errors.add(:father_county, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(father_occupation)
            errors.add(:father_occupation, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(mother_forename)
            errors.add(:mother_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(mother_surname)
            errors.add(:mother_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(mother_title)
            errors.add(:mother_title, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(mother_abode)
            errors.add(:mother_abode, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(mother_condition_prior_to_marriage)
            errors.add(:mother_condition_prior_to_marriage, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(mother_place_prior_to_marriage)
            errors.add(:mother_place_prior_to_marriage, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(mother_county_prior_to_marriage)
            errors.add(:mother_county_prior_to_marriage, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(mother_occupation)
            errors.add(:mother_county, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness1_forename)
            errors.add(:witness1_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness1_surname)
            errors.add(:witness1_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness2_forename)
            errors.add(:witness2_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness2_surname)
            errors.add(:witness2_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness3_forename)
            errors.add(:witness3_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness3_surname)
            errors.add(:witness3_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness4_forename)
            errors.add(:witness4_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness4_surname)
            errors.add(:witness4_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness5_forename)
            errors.add(:witness5_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness5_surname)
            errors.add(:witness5_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness6_forename)
            errors.add(:witness6_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness6_surname)
            errors.add(:witness6_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness7_forename)
            errors.add(:witness7_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness7_surname)
            errors.add(:witness7_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness8_forename)
            errors.add(:witness8_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(witness8_surname)
            errors.add(:witness8_surname, 'Invalid characters')

          end
          if check_embargo
            rule = embargoes.where(record_type: 'ba', period_type: 'period').first
            errors.add(:baptism_date, 'Cannot compute end of embargo') if rule.present? && year.blank?

          end

        when record_type =='bu'
          unless FreeregValidations.cleantext(person_age)
            errors.add(:person_age, 'Invalid age')

          end
          unless FreeregValidations.cleandate(burial_date)
            errors.add(:burial_date, 'Invalid date')

          end
          unless FreeregValidations.cleandate(death_date)
            errors.add(:death_date, 'Invalid date')

          end
          unless FreeregValidations.cleantext(burial_person_forename)
            errors.add(:burial_person_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(burial_person_surname)
            errors.add(:burial_person_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(burial_person_title)
            errors.add(:burial_person_title, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(burial_person_abode)
            errors.add(:burial_person_abode, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(relationship)
            errors.add(:relationship, 'Invalid relationship')

          end
          unless FreeregValidations.cleantext(male_relative_forename)
            errors.add(:male_relative_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(relative_surname)
            errors.add(:relative_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(male_relative_title)
            errors.add(:burial_person_title, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(female_relative_forename)
            errors.add(:female_relative_forename, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(female_relative_surname)
            errors.add(:female_relative_surname, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(female_relative_title)
            errors.add(:female_relative_title, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(cause_of_death)
            errors.add(:cause_of_death, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(burial_location_information)
            errors.add(:burial_location_information, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(place_of_death)
            errors.add(:place_of_death, 'Invalid characters')

          end
          unless FreeregValidations.cleantext(memorial_information)
            errors.add(:memorial_information, 'Invalid characters')

          end
          if check_embargo
            rule = embargoes.where(record_type: 'bu', period_type: 'period').first
            errors.add(:burial, 'Cannot compute end of embargo') if rule.present? && year.blank?

          end
        else
          p "freereg entry validations #{id} no record type"
        end
      end
      def get_listing_of_witnesses
        witnesses = Array.new
        single_witness = Array.new(2)
        self.multiple_witnesses.each do |witness|
          single_witness = Array.new(2)
          single_witness[0] = witness.witness_forename
          single_witness[1] = witness.witness_surname
          witnesses << single_witness
        end
        witnesses
      end

      def transcribed_by_me?(user)
        if user.person_role == 'transcriber'
          all_assignments = user.assignments
          all_assignments.each do |assignment|
            image = assignment.image_server_images.where(:image_file_name => self.image_file_name).first
            return true if image.present?
          end
        end
        return false
      end

    end
