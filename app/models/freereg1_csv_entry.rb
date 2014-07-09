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
  field :county, type: String
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
  field :place, type: String
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

 belongs_to :freereg1_csv_file, index: true

  before_destroy do |entry|
    SearchRecord.destroy_all(:freereg1_csv_entry_id => entry._id)       
  end
  
  has_one :search_record
  embeds_many :multiple_witnesses
  accepts_nested_attributes_for :multiple_witnesses

  index({freereg1_csv_file_id: 1,file_line_number:1})
  index({file_line_number:1})
  index ({line_id:1})

  validate :errors_in_fields
  before_save :embed_witness


  def embed_witness
 self.multiple_witnesses_attributes = [{:witness_forename => self[:witness1_forename], :witness_surname => self[:witness1_surname]}]
 self.multiple_witnesses_attributes = [{:witness_forename => self[:witness2_forename], :witness_surname => self[:witness2_surname]}]
  end

  
  def transform_search_record
    SearchRecord.from_freereg1_csv_entry(self) 
  end
  
  def display_field(field_name)
    if field_name == 'county'
      ChapmanCode::name_from_code(self.county)
    else
      self[field_name]
    end
  end
  
  
  
  def ordered_display_fields
    order = []
    order << 'county'
    order << 'place'
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
      "witness1_",
      "witness2_"
    ].each do |prefix|
      ["forename", "surname", "age", "sex", "condition", "abode", "parish", "occupation", ].each do |suffix|
        order << "#{prefix}#{suffix}"
      end
    end
    order << 'file_line_number'
    order << 'line_id'
    order << 'notes'

    order
  end

  def self.change_file(old_id,new_id)
   entries = Freereg1CsvEntry.where(:freereg1_csv_file_id => old_id).all
   entries.each do |entry|
     entry.update_attributes(:freereg1_csv_file_id => new_id)
    end
  end

  def errors_in_fields
 
    unless  Place.where(:place_name => self.place, :disabled.ne => "true").exists?
  
      errors.add(:place, "Place does not exit") 
      self.error_flag = "true"
    end
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
     p 'freereg entry validations'
     p self
     p 'no record type'
   end
  end
 
end
