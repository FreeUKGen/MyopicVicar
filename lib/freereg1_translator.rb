# Copyright 2012 Trustees of FreeBMD
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 
require 'name_role'

module Freereg1Translator
  KEY_MAP = {
  #  :baptism_date => , #actual date as written
  #  :birth_date => ,
    # :bride_father_forename => :father_first_name,
    # :bride_father_surname => :father_surname,
    :bride_forename => :bride_first_name,
  #  :bride_parish => ,
    :bride_surname => :bride_last_name,
  #  :burial_date => , #actual date as written
    :burial_person_forename => :first_name,
    :burial_person_surname => :last_name,
    :county => :chapman_code,
    :father_forename => :father_first_name,
    :father_surname => :father_last_name,
    # what should we do about the various relatives?  They should be put into family records.
    :female_relative_forename => :mother_first_name,
    # TODO refactor parentage to arrays
    # :groom_father_forename => ,
    # :groom_father_occupation => ,
    # :groom_father_surname => ,
    :groom_forename => :groom_first_name,
  #  :groom_parish => ,
    :groom_surname => :groom_last_name,
    # what should we do about the various relatives?  They should be put into family records.
    :male_relative_forename => :father_first_name,
   # :marriage_date => , #actual date as written
    :mother_forename => :mother_first_name,
    :mother_surname => :mother_last_name,
    :person_forename => :first_name,
  #  :register => ,
  #  :register_type => ,
  #  :relationship => ,
    :relative_surname => :father_last_name,
    # :witness1_forename => ,
    # :witness1_surname => ,
    # :witness2_forename => ,
    # :witness2_surname => ,
    # :line => ,
    :file_line_number => :file_line_number,
  }

  def self.entry_attributes(entry)
    new_attrs = {}
    KEY_MAP.keys.each do |key|
      new_attrs[KEY_MAP[key]] = entry[key] if entry[key] 
    end    
    new_attrs[:line_id] = entry.line_id
    
    new_attrs
  end
  
  def self.file_attributes(file)
    new_attrs = {}
    # keys for finding duplicate tranascript
    new_attrs[:record_type] = file.record_type

    new_attrs
  end
  
  def self.expanded_attrs(entry)
    extras = []

    if entry[:groom_father_forename] || entry[:groom_father_surname]
      extra_name = { :role => NameRole::GROOM_FATHER }
      extra_name[:first_name] = entry[:groom_father_forename]
      extra_name[:last_name] = entry[:groom_father_surname]
      extras << extra_name
    end
        
    if entry[:bride_father_forename] || entry[:bride_father_surname]
      extra_name = { :role => NameRole::BRIDE_FATHER }
      extra_name[:first_name] = entry[:bride_father_forename]
      extra_name[:last_name] = entry[:bride_father_surname]
      extras << extra_name
    end

  end
  
  def self.translate(file, entry)
    entry_attrs = entry_attributes(entry)
    file_attrs = file_attributes(file)
    file_attrs.merge!(entry_attrs)
    file_attrs[:other_family_names] = expanded_attrs(entry)
    file_attrs
  end

end