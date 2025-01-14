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
class Freereg1CsvEntry
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  include Mongoid::Attributes::Dynamic
  require 'freereg_validations'
  require 'record_type'
  require 'freereg_options_constants'
  require 'multiple_witness'
  require 'chapman_code'

  # IF your add or delete fields you MAY have to alter the freereg_options_constants fields for baptisms, burials and marriages to enable the
  # new_freereg_csv_update_processor to process them


  # Fields here represent those currently requested by FreeREG1 at
  # http://www.freereg.org.uk/howto/enterdata.htm
  # They have only been modified to replace hyphens with underscores.
  #original Common fields
  field :county, type: String # note this is actually a chapman code in the records
  field :place, type: String #every where else this is place_name
  field :church_name, type: String
  field :register_type, type: String
  field :register_entry_number, type: String
  field :notes, type: String
  field :file_line_number, type: Integer
  field :film, type: String
  field :film_number, type: String

  #new common fields
  field :image_file_name, type: String
  field :notes_from_transcriber, type: String


  #original baptism fields
  field :baptism_date, type: String #actual date as written
  field :birth_date, type: String #actual date as written
  field :person_forename, type: String
  field :person_sex, type: String
  field :father_forename, type: String
  field :father_occupation, type: String
  field :father_surname, type: String
  field :mother_forename, type: String
  field :mother_surname, type: String
  field :person_abode, type: String

  #new baptism fields
  field :confirmation_date, type: String #actual date as written
  field :received_into_church_date, type: String #actual date as written
  field :person_surname, type: String
  field :person_title, type: String
  field :person_age, type: String
  field :person_condition, type: String
  field :person_status, type: String
  field :person_occupation, type: String
  field :person_place_birth, type: String
  field :person_county_birth, type: String
  field :person_relationship, type: String
  field :father_title, type: String
  field :father_abode, type: String
  field :father_place, type: String
  field :father_county, type: String
  field :mother_title, type: String
  field :mother_abode, type: String
  field :mother_condition_prior_to_marriage, type: String
  field :mother_place_prior_to_marriage, type: String
  field :mother_county_prior_to_marriage, type: String
  field :mother_occupation, type: String
  field :private_baptism, type: Boolean, default: false

  #field :witness1_forename, type: String
  #field :witness1_surname, type: String
  #field :witness2_forename, type: String
  #field :witness2_surname, type: String
  #field :witness3_forename, type: String
  #field :witness3_surname, type: String
  #field :witness4_forename, type: String
  #field :witness4_surname, type: String
  #field :witness5_forename, type: String
  #field :witness5_surname, type: String
  #field :witness6_forename, type: String
  #field :witness6_surname, type: String
  #field :witness7_forename, type: String
  #field :witness7_surname, type: String
  #field :witness8_forename, type: String
  #field :witness8_surname, type: String


  #original burial fields
  field :burial_date, type: String #actual date as written
  field :burial_person_forename, type: String
  field :burial_person_surname, type: String
  field :burial_person_abode, type: String
  field :female_relative_forename, type: String
  field :male_relative_forename, type: String
  field :person_age, type: String
  field :relationship, type: String
  field :relative_surname, type: String

  #new burial fields
  field :death_date, type: String  #Date of death (To be used if date of burial is absent)
  field :burial_person_title, type: String
  field :male_relative_title, type: String
  field :female_relative_surname, type: String #To be added to search_names
  field :female_relative_title, type: String
  field :cause_of_death, type: String
  field :burial_location_information, type: String
  field :place_of_death, type: String
  field :memorial_information, type: String


  #original marriage fields
  field :bride_abode, type: String
  field :bride_age, type: String
  field :bride_condition, type: String
  field :bride_father_forename, type: String
  field :bride_father_occupation, type: String
  field :bride_father_surname, type: String
  field :bride_forename, type: String
  field :bride_occupation, type: String
  field :bride_parish, type: String
  field :bride_surname, type: String
  field :groom_abode, type: String
  field :groom_age, type: String
  field :groom_condition, type: String
  field :groom_father_forename, type: String
  field :groom_father_occupation, type: String
  field :groom_father_surname, type: String
  field :groom_forename, type: String
  field :groom_occupation, type: String
  field :groom_parish, type: String
  field :groom_surname, type: String
  field :marriage_date, type: String #actual date as written
  field :witness1_forename, type: String
  field :witness1_surname, type: String
  field :witness2_forename, type: String
  field :witness2_surname, type: String

  #new marriage fields
  field :contract_date, type: String #actual date as written usage mainly in Scotland
  field :bride_title, type: String
  field :bride_marked, type: Boolean, default: false
  field :bride_father_title, type: String
  field :bride_mother_forename, type: String
  field :bride_mother_surname, type: String
  field :bride_mother_title, type: String
  field :bride_mother_occupation, type: String
  field :groom_title, type: String
  field :groom_marked, type: Boolean, default: false
  field :groom_father_title, type: String
  field :groom_mother_forename, type: String
  field :groom_mother_surname, type: String
  field :groom_mother_title, type: String
  field :groom_mother_occupation, type: String
  field :marriage_by_licence, type: Boolean, default: false
  field :witness3_forename, type: String
  field :witness3_surname, type: String
  field :witness4_forename, type: String
  field :witness4_surname, type: String
  field :witness5_forename, type: String
  field :witness5_surname, type: String
  field :witness6_forename, type: String
  field :witness6_surname, type: String
  field :witness7_forename, type: String
  field :witness7_surname, type: String
  field :witness8_forename, type: String
  field :witness8_surname, type: String

  #calculated fields
  field :year, type: String
  field :line_id, type: String
  field :error_flag, type:String, default: 'false'
  field :record_digest, type: String
  field :location, type: String
  field :transcribed_by, type: String
  field :credit, type: String
  field :register, type: String
  field :record_type, type: String
  field :processed_date, type: DateTime
  field :consecrated_ground, type: String

  validate :errors_in_fields

  belongs_to :freereg1_csv_file, index: true, optional: true

  embeds_many :multiple_witnesses, cascade_callbacks: true
  embeds_many :embargo_records
  has_one :search_record, dependent: :restrict_with_error

  before_save :add_digest, :captitalize_surnames, :check_register_type

  before_destroy do |entry|
    SearchRecord.destroy_all(:freereg1_csv_entry_id => entry._id)
  end

  after_update :update_seach_record_location

  accepts_nested_attributes_for :embargo_records, allow_destroy: false, reject_if: :all_blank
  accepts_nested_attributes_for :multiple_witnesses, allow_destroy: true, reject_if: :all_blank, limit: 8

  scope :zero_baptism_records, -> { where(:baptism_date.in => [nil, "","0"], :birth_date.in => [nil, "","0"]) }
  scope :zero_marriage_records, -> { where(:marriage_date.in => [nil,"","0"]) }
  scope :zero_burial_records, -> { where(:burial_date.in => [nil,"","0"]) }

  index({ freereg1_csv_file_id: 1, year: 1 }, { name: 'freereg1_csv_file_id_year' })
  index({freereg1_csv_file_id: 1,file_line_number:1})
  index({freereg1_csv_file_id: 1, record_digest:1})
  index({person_forename: 1})
  index({mother_forename: 1})
  index({groom_forenamen: 1})
  index({groom_father_forename: 1})
  index({female_relative_forenamee: 1})
  index({father_forename: 1})
  index({burial_person_forename: 1})
  index({bride_forename: 1})
  index({bride_father_forename: 1})
  index({"multiple_witnesses.witness_forename": 1})
  index({ _id: 1, "embargo_record.id": 1 }, { name: 'entry_id_embargo_id' })

  class << self
    def id(id)
      where(id: id)
    end

    def freereg1_csv_file(id)
      where(freereg1_csv_file_id: id)
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
      entries = Freereg1CsvEntry.where(freereg1_csv_file_id: fileid).all.no_timeout
      entries.destroy_all
    end

    def update_entries_userid(userid, batch)
      batch.freereg1_csv_entries.each do |entry|
        line = entry.line_id
        if line.present?
          line_parts = line.split('.')
          line_parts[0] = userid
          line = line_parts.join('.')
        else
          line = (userid + "." + self.file_name + "." + entry.file_line_number.to_s).to_s
        end
        entry.update_attribute(:line_id,line)
      end
      true
    end

    def update_parameters(params, entry)
      #clean up old null entries
      params = params.delete_if { |k, v| v == '' }
      return params
    end

    def valid_freereg1_csv_entry?(freereg1_csv_entry)
      result = false
      return result if freereg1_csv_entry.blank?

      freereg1_csv_entry_object = Freereg1CsvEntry.find(freereg1_csv_entry)
      result = true if freereg1_csv_entry_object.present? && Freereg1CsvFile.valid_freereg1_csv_file?(freereg1_csv_entry_object.freereg1_csv_file_id)
      logger.warn("FREEREG:LOCATION:VALIDATION invalid freereg1_csv_entry id #{freereg1_csv_entry} ") unless result
      result
    end
  end



  # ...........................................................................Instance methods

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

  def cal_digest
    case self.record_type
    when RecordType::BAPTISM
      string = self.create_baptism_string
    when RecordType::MARRIAGE
      string = self.create_marriage_string
    when RecordType::BURIAL
      string = self.create_burial_string
    else
      false
    end
    md5 = OpenSSL::Digest::MD5.new
    if string.nil?
      p "#{self._id}, nil string for MD5"
    else
      the_digest  =  hex_to_base64_digest(md5.hexdigest(string))
    end
    return the_digest
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
    file = entry.freereg1_csv_file
    return if file.blank? || file.ucf_list.blank?

    proceed, place, _church, _register = file.location_from_file
    search_record = entry.search_record
    if search_record.present? && proceed
      file.ucf_list.delete_if { |record| record.to_s == search_record.id.to_s }
      file.ucf_updated = DateTime.now.to_date
      file.save
      if proceed && place.present? && place.ucf_list.present? && place.ucf_list[file.id.to_s].present?
        place.ucf_list[file.id.to_s].delete_if { |record| record.to_s == search_record.id.to_s }
        place.save
      end
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

  def location_ids
    file = freereg1_csv_file
    if file.present?
      extended_def = file.def
      proceed, place, church, register = file.location_from_file
    end
    return [false, nil, nil, nil, extended_def] unless proceed

    [true, place._id, church._id, register._id, extended_def]
  end

  def lookup_record_type
    return freereg1_csv_file.record_type if RecordType.all_types.include?(freereg1_csv_file.record_type)

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

  def hex_to_base64_digest(hexdigest)
    [[hexdigest].pack("H*")].pack("m").strip
  end

  def location_from_entry
    file = freereg1_csv_file_id
    return [false] unless Freereg1CsvFile.freereg1_csv_file_valid?(file)

    my_file = Freereg1CsvFile.find_by(_id: file)
    my_register = my_file.register
    return [false] unless Register.register_valid?(my_register)

    my_church = my_register.church
    return [false] unless Church.church_valid?(my_church)

    my_place = my_church.place
    return [false] unless Place.place_valid?(my_place)

    [true, my_place, my_church, my_register]
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

      return [false, ''] if freereg1_csv_file.register.embargo_rules.blank? # guard to avoid there being no rules!

    end
    embargoes = freereg1_csv_file.register.embargo_rules
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
    record_id = record.freereg1_csv_file_id
    file_id = file.id
    if record_id == file_id
      success = true
    else
      success = false
    end
    success
  end

  def update_location(record, file)
    update(freereg1_csv_file_id: file.id, place: record[:place], church_name: record[:church_name], register_type: record[:register_type])
  end

  def update_seach_record_location
    search_record.update_location(self, freereg1_csv_file) if search_record.present? && freereg1_csv_file.present?
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
    if freereg1_csv_file.blank?
      check_embargo = false
    else
      register = freereg1_csv_file.register
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
    unless FreeregValidations.cleantext(consecrated_ground)
      errors.add(:consecrated_ground, 'Invalid characters')

    end
    case
    when record_type == 'ma'
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

    when record_type == 'ba'
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
        errors.add(:person_age, 'Invalid age')
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

    when record_type == 'bu'
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
      unless FreeregValidations.cleanage(person_age)
        errors.add(:person_age, 'Invalid age')
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
