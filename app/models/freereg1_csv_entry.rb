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
  include MongoMapper::Document
  

  belongs_to :freereg1_csv_file
  one :search_record

  # Fields here represent those currently requested by FreeREG1 at
  # http://www.freereg.org.uk/howto/enterdata.htm
  # They have only been modified to replace hyphens with underscores.
  key :baptism_date, String #actual date as written
  key :birth_date, String #actual date as written
  key :bride_abode, String
  key :bride_age, String
  key :bride_condition, String
  key :bride_father_forename, String
  key :bride_father_occupation, String
  key :bride_father_surname, String
  key :bride_forename, String
  key :bride_occupation, String
  key :bride_parish, String
  key :bride_surname, String
  key :burial_date, String #actual date as written
  key :burial_person_forename, String
  key :burial_person_surname, String
  key :burial_person_abode, String
  key :county, String
  key :father_forename, String
  key :father_occupation, String
  key :father_surname, String
  key :female_relative_forename, String
  key :groom_abode, String
  key :groom_age, String
  key :groom_condition, String
  key :groom_father_forename, String
  key :groom_father_occupation, String
  key :groom_father_surname, String
  key :groom_forename, String
  key :groom_occupation, String
  key :groom_parish, String
  key :groom_surname, String
  key :male_relative_forename, String
  key :marriage_date, String #actual date as written
  key :mother_forename, String
  key :mother_surname, String
  key :notes, String
  key :person_abode, String
  key :person_age, String
  key :person_forename, String
  key :person_sex, String
  key :place, String
  key :register, String
  key :register_entry_number, Integer
  key :register_type, String
  key :relationship, String
  key :relative_surname, String
  key :witness1_forename, String
  key :witness1_surname, String
  key :witness2_forename, String
  key :witness2_surname, String
  key :line_id, String
  key :file_line_number, Integer


  after_save :transform_search_record
  
  def transform_search_record
    SearchRecord.from_freereg1_csv_entry(self)
  end
  
end
