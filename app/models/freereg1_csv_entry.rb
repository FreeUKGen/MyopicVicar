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

  # Fields here represent those currently requested by FreeREG1 at
  # http://www.freereg.org.uk/howto/enterdata.htm
  # They have only been modified to replace hyphens with underscores.
  key :abode, String
  key :age, String
  key :baptdate, String
  key :birthdate, String
  key :bride_abode, String
  key :bride_age, String
  key :bride_condition, String
  key :bride_fath_firstname, String
  key :bride_fath_occupation, String
  key :bride_fath_surname, String
  key :bride_firstname, String
  key :bride_occupation, String
  key :bride_parish, String
  key :bride_surname, String
  key :burdate, String
  key :church, String
  key :county, String
  key :fath_occupation, String
  key :fath_surname, String
  key :father, String
  key :firstname, String
  key :groom_abode, String
  key :groom_age, String
  key :groom_condition, String
  key :groom_fath_firstname, String
  key :groom_fath_occupation, String
  key :groom_fath_surname, String
  key :groom_firstname, String
  key :groom_occupation, String
  key :groom_parish, String
  key :groom_surname, String
  key :marrdate, String
  key :moth_surname, String
  key :mother, String
  key :no, String
  key :notes, String
  key :place, String
  key :rel1_male_first, String
  key :rel1_surname, String
  key :rel2_female_first, String
  key :relationship, String
  key :sex, String
  key :surname, String
  key :witness1_firstname, String
  key :witness1_surname, String
  key :witness2_firstname, String
  key :witness2_surname
end
