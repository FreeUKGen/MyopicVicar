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
  require 'freereg_validations'
  require 'record_type'
  require 'freereg_options_constants'
  require 'multiple_witness'
  require 'chapman_code'


  # Fields here represent those currently requested by FreeREG1 at
  # http://www.freereg.org.uk/howto/enterdata.htm
  # They have only been modified to replace hyphens with underscores.
  field :baptism_date, type: String #actual date as written
  field :birth_date, type: String #actual date as written
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
  field :burial_date, type: String #actual date as written
  field :burial_person_forename, type: String
  field :burial_person_surname, type: String
  field :burial_person_abode, type: String
  field :church_name, type: String
  field :county, type: String # note this is actually a chapman code in the records
  field :father_forename, type: String
  field :father_occupation, type: String
  field :father_surname, type: String
  field :female_relative_forename, type: String
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
  field :male_relative_forename, type: String
  field :marriage_date, type: String #actual date as written
  field :mother_forename, type: String
  field :mother_surname, type: String
  field :notes, type: String
  field :notes_from_transcriber, type: String
  field :person_abode, type: String
  field :person_age, type: String
  field :person_forename, type: String
  field :person_sex, type: String
  field :place, type: String #every where else this is place_name

  field :register, type: String
  field :register_entry_number, type: String
  field :register_type, type: String
  field :relationship, type: String
  field :relative_surname, type: String
  field :witness1_forename, type: String
  field :witness1_surname, type: String
  field :witness2_forename, type: String
  field :witness2_surname, type: String
  field :year, type: String
  field :line_id, type: String
  field :file_line_number, type: Integer
  field :film, type: String
  field :film_number, type: String
  field :error_flag, type:String, default: 'false'
  field :record_type, type: String
  field :record_digest, type: String
  field :location, type: String

  belongs_to :freereg1_csv_file, index: true

  before_save :add_digest, :captitalize_surnames


  before_destroy do |entry|
    SearchRecord.destroy_all(:freereg1_csv_entry_id => entry._id)
  end

  has_one :search_record


  embeds_many :multiple_witnesses, cascade_callbacks: true
  accepts_nested_attributes_for :multiple_witnesses,allow_destroy: true,
    reject_if: :all_blank

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
  index({"multiple_witnesses.witness_forename":1})
  
  validate :errors_in_fields
  class << self
    def id(id)
      where(:id => id)
    end
    def delete_entries_for_a_file(fileid)
      entries = Freereg1CsvEntry.where(:freereg1_csv_file_id => fileid).all.no_timeout
      p "#{entries.length}" unless entries.nil?
      entries.destroy_all
    end
    def update_entries_userid(userid,batch)
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
  end

  def extract_year(date_string)
    if date_string && md = date_string.match(/(\d\d\d\d)/)
      md.captures.first.to_i
    else
      1 # assume illegible dates are old -- start with year 1
    end
  end

  def add_digest
    self.record_digest = self.cal_digest
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
    self.bride_surname = self.bride_surname.upcase if self.bride_surname.present?
    self.burial_person_surname = self.burial_person_surname.upcase if self.burial_person_surname.present?
    self.father_surname = self.father_surname.upcase if self.father_surname.present?
    self.groom_father_surname = self.groom_father_surname.upcase if self.groom_father_surname.present?
    self.groom_surname = self.groom_surname.upcase if self.groom_surname.present?
    self.mother_surname = self.mother_surname.upcase if self.mother_surname.present?
    self.relative_surname = self.relative_surname.upcase if self.relative_surname.present?
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

  def create_baptism_string
    string = ''
    string = string + self.person_forename.strip + "person" unless  self.person_forename.nil?
    string = string + self.baptism_date.strip + "baptism" unless self.baptism_date.nil?
    string = string + self.birth_date.strip + "birth" unless self.birth_date.nil?
    string = string + self.father_forename.strip + "male" unless self.father_forename.nil?
    string = string + self.father_surname.strip + "malesurname" unless self.father_surname.nil?
    string = string + self.mother_forename.strip + "female" unless self.mother_forename.nil?
    string = string + self.mother_surname.strip + "femalesurname" unless self.mother_surname.nil?
    string = string + self.register_entry_number.strip + "register" unless self.register_entry_number.nil?
    string = string + self.person_sex.strip unless self.person_sex.nil?
    string = string + self.father_occupation.strip + "occupation" unless self.father_occupation.nil?
    string = string + self.person_abode.strip + "abode" unless self.person_abode.nil?
    string = string + self.notes.strip + "notes" unless self.notes.nil?
    string = string + self.film.strip + "film" unless self.film.nil?
    string = string + self.film_number.strip + "film_number" unless self.film_number.nil?
    return string
  end
  def create_marriage_string
   
    string = ''
    string = string + self.groom_forename.strip + "groom" unless  self.groom_forename.nil?
    string = string + self.groom_surname.strip + "groomsurname" unless self.groom_surname.nil?
    string = string + self.groom_age.strip + "groomage" unless self.groom_age.nil?
    string = string + self.groom_occupation.strip + "groomoccupation" unless self.groom_occupation.nil?
    string = string + self.groom_abode.strip + "grromabode" unless self.groom_abode.nil?
    string = string + self.groom_condition.strip + "groomcondition" unless self.groom_condition.nil?
    string = string + self.groom_parish.strip + "groomparish" unless self.groom_parish.nil?
    string = string + self.bride_forename.strip + "bride" unless  self.bride_forename.nil?
    string = string + self.bride_surname.strip + "bridesurname" unless self.bride_surname.nil?
    string = string + self.bride_age.strip unless self.bride_age.nil?
    string = string + self.bride_occupation.strip + "brideoccupation" unless self.bride_occupation.nil?
    string = string + self.bride_abode.strip + "brideabode" unless self.bride_abode.nil?
    string = string + self.bride_condition.strip unless self.bride_condition.nil?
    string = string + self.bride_parish.strip + "brideparish" unless self.bride_parish.nil?
    string = string + self.bride_father_forename.strip + "father" unless self.bride_father_forename.nil?
    string = string + self.bride_father_surname.strip + "fathersurname" unless self.bride_father_surname.nil?
    string = string + self.bride_father_occupation.strip + "fatheroccupation" unless self.bride_father_occupation.nil?
    string = string + self.marriage_date.strip unless self.marriage_date.nil?
    string = string + self.register_entry_number.strip + "register" unless self.register_entry_number.nil?
    string = string + self.witness1_forename.strip + "witness1" unless self.witness1_forename.nil?
    string = string + self.witness1_surname.strip + "witness1surname" unless self.witness1_surname.nil?
    string = string + self.witness2_forename.strip + "witness2" unless self.witness2_forename.nil?
    string = string + self.witness2_surname.strip + "witness2surname" unless self.witness2_surname.nil?
    string = string + self.notes.strip + "notes" unless self.notes.nil?
    string = string + self.film.strip + "film" unless self.film.nil?
    string = string + self.film_number.strip + "film_number" unless self.film_number.nil?
    return string

  end
  def create_burial_string
    string = ''
    string = string + self.burial_person_forename.strip + "person" unless  self.burial_person_forename.nil?
    string = string + self.burial_date.strip unless self.burial_date.nil?
    string = string + self.burial_person_surname.strip + "personsurname" unless self.burial_person_surname.nil?
    string = string + self.male_relative_forename.strip + "male" unless self.male_relative_forename.nil?
    string = string + self.female_relative_forename.strip + "female" unless self.female_relative_forename.nil?
    string = string + self.relative_surname.strip + "relative" unless self.relative_surname.nil?
    string = string + self.register_entry_number.strip + "register" unless self.register_entry_number.nil?
    string = string + self.person_sex.strip unless self.person_sex.nil?
    string = string + self.burial_person_abode.strip + "abode" unless self.burial_person_abode.nil?
    string = string + self.notes.strip + "notes" unless self.notes.nil?
    string = string + self.film.strip + "film" unless self.film.nil?
    string = string + self.film_number.strip + "film_number" unless self.film_number.nil?
    return string
  end
  def hex_to_base64_digest(hexdigest)
    [[hexdigest].pack("H*")].pack("m").strip
  end

  def self.compare_baptism_fields?(one, two)
    #used in  task check_record_digest
    if one.person_forename == two.person_forename &&
        one.baptism_date == two.baptism_date &&
        one.birth_date == two.birth_date &&
        one.father_forename == two.father_forename &&
        one.father_surname == two.father_surname &&
        one.mother_forename == two.mother_forename &&
        one.mother_surname == two.mother_surname &&
        one.register_entry_number  == two.register_entry_number &&
        one.person_sex == two.person_sex &&
        one.father_occupation == two.father_occupation &&
        one.person_abode == two.person_abode &&
        one.notes == two.notes &&
        one.film == two.film &&
        one.film_number == two.film_number
      equal = true
    else
      equal = false
    end
    equal
  end
  def self.compare_marriage_fields?(one, two)
      #used in  task check_record_digest
    if one.groom_forename  ==  two.groom_forename             &&
        one.groom_surname  ==  two.groom_surname            &&
        one.groom_age  ==            two.groom_age  &&
        one.groom_occupation  ==          two.groom_occupation &&
        one.groom_abode  ==    two.groom_abode &&
        one.groom_condition  ==        two.groom_condition &&
        one.groom_parish  ==             two.groom_parish  &&
        one.bride_forename  ==   two.bride_forename &&
        one.bride_surname  ==  two.bride_surname &&
        one.bride_age  ==   two.bride_age  &&
        one.bride_occupation  ==  two.bride_occupation &&
        one.bride_abode  ==  two.bride_abode  &&
        one.bride_condition  ==            two.bride_condition &&
        one.bride_parish  ==      two.bride_parish &&
        one.bride_father_forename  ==   two.bride_father_forename &&
        one.bride_father_surname  ==  two.bride_father_surname &&
        one.bride_father_occupation  == two.bride_father_occupation &&
        one.marriage_date  ==  two.marriage_date &&
        one.register_entry_number  ==         two.register_entry_number &&
        one.witness1_forename  ==  two.witness1_forename &&
        one.witness1_surname  ==          two.witness1_surname &&
        one.witness2_forename  ==              two.witness2_forename &&
        one.witness2_surname  ==   two.witness2_surname &&
        one.notes == two.notes &&
        one.film == two.film &&
        one.film_number == two.film_number
      equal = true
    else
      equal = false
    end
    equal
  end
  def self.compare_burial_fields?(one, two)
      #used in  task check_record_digest
    if one.burial_person_forename == two.burial_person_forename &&
        one.burial_date == two.burial_date &&
        one.burial_person_surname  == two.burial_person_surname &&
        one.male_relative_forename == two.male_relative_forename &&
        one.female_relative_forename ==  two.female_relative_forename &&
        one.relative_surname == two.relative_surname &&
        one.register_entry_number  == two.register_entry_number &&
        one.person_sex == two.person_sex &&
        one.burial_person_abode == one.burial_person_abode &&
        one.notes == two.notes &&
        one.film == two.film &&
        one.film_number == two.film_number
      equal = true
    else
      equal = false
    end
    equal
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

  def self.update_parameters(params,entry)
    #clean up old null entries
    params = params.delete_if{|k,v| v == ''}
    return params
  end

  def same_location(record,file)
    success = true
    record_id = record.freereg1_csv_file_id
    file_id = file.id
    #p "checking location"
    #p record_id
    #p file_id
    if record_id == file_id
      success = true
    else
      success = false
    end
    success
  end
  def update_location(record,file)
    #p "updating location"
    #p record
    #p file
    #p self
    self.update_attributes(:freereg1_csv_file_id => file.id, :place => record[:place], :church_name => record[:church_name], :register_type => record[:register_type])
    #p self
  end


  def date_beyond_cutoff?(date_string, cutoff)
    current_year = Time.now.year

    return (current_year - cutoff) < extract_year(date_string)
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

  def embed_witness
    #does not appear to be called
    if self.record_type == 'ma'
      self.multiple_witnesses_attributes = [{:witness_forename => self[:witness1_forename], :witness_surname => self[:witness1_surname]}] unless self[:witness1_forename].blank? &&  self[:witness1_surname].blank?
      self.multiple_witnesses_attributes = [{:witness_forename => self[:witness2_forename], :witness_surname => self[:witness2_surname]}] unless self[:witness2_forename].blank? &&  self[:witness2_surname].blank?
    end
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



  def ordered_display_fields
    order = []
    order << 'county'
    order << 'place'
    order << 'church_name'
    order << 'register'
    order << 'register_type'
    order << 'register_entry_number'
    order << 'baptism_date'
    order << 'birth_date'
    order << 'burial_date'
    order << 'marriage_date'
    [
      # primary members of the record are displayed first
      "person_",
      "burial_person_",
      "groom_",
      "bride_",
      # other family members show up next
      "father_",
      "mother_",
      "husband_",
      "wife_",
      "groom_father_",
      "bride_father_"
    ].each do |prefix|
      ["forename", "surname", "age", "sex", "condition", "abode", "parish", "occupation", ].each do |suffix|
        order << "#{prefix}#{suffix}"
      end
    end
    order << 'relationship'
    [
      "male_relative_",
      "female_relative_",
      "relative_",

    ].each do |prefix|
      ["forename", "surname", "age", "sex", "condition", "abode", "parish", "occupation", ].each do |suffix|
        order << "#{prefix}#{suffix}"
      end
    end

    order
  end



  def errors_in_fields

    unless FreeregValidations.cleantext(self.register_entry_number)
      errors.add(:register_entry_number, "Invalid characters")
      self.error_flag = "true"
    end
    unless FreeregValidations.cleantext(self.notes)
      errors.add(:notes, "Invalid characters")
      self.error_flag = "true"
    end
    #There seem to be many errors in notes characters
    #unless FreeregValidations.cleantext(self.notes_from_register)
    #errors.add(:notes_from_register, "Invalid characters")
    #self.error_flag = "true"
    #end

    case
    when self.record_type =='ma'


      unless FreeregValidations.cleanage(self.bride_age)
        errors.add(:bride_age, "Invalid age")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.register_entry_number)
        errors.add(:register_entry_number, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleanage(self.groom_age)
        errors.add(:groom_age, "Invalid age")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.bride_abode)
        errors.add(:bride_abode, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.bride_condition)
        errors.add(:bride_condition, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.bride_father_forename)
        errors.add(:bride_father_forename, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.bride_father_occupation)
        errors.add(:bride_father_occupation, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.bride_father_surname)
        errors.add(:bride_father_surname, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.bride_forename)
        errors.add(:bride_forename, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.bride_occupation)
        errors.add(:bride_occupation, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.bride_parish)
        errors.add(:bride_parish, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.bride_surname)
        errors.add(:bride_surname, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.groom_abode)
        errors.add(:groom_abode, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.groom_condition)
        errors.add(:groom_condition, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.groom_father_forename)
        errors.add(:groom_father_forename, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.groom_father_occupation)
        errors.add(:groom_father_occupation, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.groom_father_surname)
        errors.add(:groom_father_surname, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.groom_forename)
        errors.add(:groom_forename, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.groom_occupation)
        errors.add(:groom_occupation, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.groom_parish)
        errors.add(:groom_parish, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.groom_surname)
        errors.add(:groom_surname, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.witness1_forename)
        errors.add(:witness1_forename, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.witness1_surname)
        errors.add(:witness1_surname, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.witness2_forename)
        errors.add(:witness2_forename, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.witness2_surname)
        errors.add(:witness2_surname, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleandate(self.marriage_date)
        errors.add(:marriage_date, "Invalid date")
        self.error_flag = "true"
      end
    when self.record_type =='ba'

      unless FreeregValidations.cleantext(self.person_forename)
        errors.add(:person_forename, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleandate(self.birth_date)
        errors.add(:birth_date, "Invalid date")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleansex(self.person_sex)
        errors.add(:person_sex, "Invalid sex field")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleandate(self.baptism_date)
        errors.add(:baptism_date, "Invalid date")
        self.error_flag = "true"
      end
      #following is disabled until check is improved
      #unless FreeregValidations.birth_date_less_than_baptism_date(self.birth_date,self.baptism_date)
      #errors.add(:birth_date, "Birth date is more recent than baptism date")
      #self.error_flag = "true"
      # end
      unless FreeregValidations.cleantext(self.person_abode)
        errors.add(:person_abode, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.father_forename)
        errors.add(:father_forename, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.mother_forename)
        errors.add(:mother_forename, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.father_surname)
        errors.add(:father_surname, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.mother_surname)
        errors.add(:mother_surname, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.father_occupation)
        errors.add(:father_occupation, "Invalid characters")
        self.error_flag = "true"
      end

    when self.record_type =='bu'

      unless FreeregValidations.cleantext(self.person_age)
        errors.add(:person_age, "Invalid age")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleandate(self.burial_date)
        errors.add(:burial_date, "Invalid date")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.burial_person_forename)
        errors.add(:burial_person_forename, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.relationship)
        errors.add(:relationship, "Invalid relationship")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.male_relative_forename)
        errors.add(:male_relative_forename, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.female_relative_forename)
        errors.add(:female_relative_forename, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.relative_surname)
        errors.add(:relative_surname, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.burial_person_surname)
        errors.add(:burial_person_surname, "Invalid characters")
        self.error_flag = "true"
      end
      unless FreeregValidations.cleantext(self.burial_person_abode)
        errors.add(:burial_person_abode, "Invalid characters")
        self.error_flag = "true"
      end
    else
      p "freereg entry validations #{self.id} no record type"
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
  
  def record_updateable?
    p "updateable"
    is_ok = true
    record = self.search_record
    return false if record.nil?
    return false unless updateable_search_date?(record)
    return false unless updateable_county?(record)
    p is_ok
    return is_ok
  end
  
  def updateable_county?(record)
    p "updateable county"
    is_ok = true
    if record.chapman_code? && self.county.present? && self.county  != record.chapman_code
      is_ok = false
    end
    self.search_record = nil unless is_ok
    self.search_record(true) unless is_ok
    p is_ok
    return is_ok
  end
  
  def updateable_search_date?(record)
    p "updateable date"
     is_ok = true
    if record.search_date.present? && self.baptism_date.present? && DateParser::searchable(self.baptism_date)  != record.search_date
      p "baptism"
      is_ok = false
    elsif record.search_date.present? && self.burial_date.present? && DateParser::searchable(self.burial_date)  != record.search_date
    p "burial"
      is_ok = false
    elsif record.search_date.present? && self.marriage_date.present? && DateParser::searchable(self.marriage_date)  != record.search_date
    p "marriage"
      is_ok = false
    elsif record.secondary_search_date.present? && self.birth_date.present? && DateParser::searchable(self.birth_date)  != record.secondary_search_date 
    p "birth"
      is_ok = false
    else
      is_ok = true
    end
    self.search_record = nil unless is_ok
    self.search_record(true) unless is_ok
    p is_ok
    return is_ok
  end



end
