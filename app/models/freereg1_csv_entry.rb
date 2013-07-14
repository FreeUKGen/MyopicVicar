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
  

  belongs_to :freereg1_csv_file
  has_one :search_record

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
  field :line_id, type: String
  field :file_line_number, type: Integer

  index({freereg1_csv_file_id:1})
  index({file_line_number:1})
  #after_save :transform_search_record
  
  def transform_search_record
    SearchRecord.from_freereg1_csv_entry(self)
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
  
  
end
