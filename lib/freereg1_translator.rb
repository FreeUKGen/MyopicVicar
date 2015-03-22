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
   :baptism_date => :transcript_date, #actual date as written
  #  :birth_date => ,
    # :bride_father_forename => :father_first_name,
    # :bride_father_surname => :father_surname,
#    :bride_forename => :bride_first_name,
  #  :bride_parish => ,
#    :bride_surname => :bride_last_name,
   :burial_date => :transcript_date, #actual date as written
#    :burial_person_forename => :first_name,
#    :burial_person_surname => :last_name,
    :county => :chapman_code,
    # what should we do about the various relatives?  They should be put into family records.
    :female_relative_forename => :mother_first_name,
    # TODO refactor parentage to arrays
    # :groom_father_forename => ,
    # :groom_father_occupation => ,
    # :groom_father_surname => ,
#    :groom_forename => :groom_first_name,
  #  :groom_parish => ,
#    :groom_surname => :groom_last_name,
    # what should we do about the various relatives?  They should be put into family records.
    :male_relative_forename => :father_first_name,
   :marriage_date => :transcript_date, #actual date as written
#    :person_forename => :first_name,
  #  :register => ,
  #  :register_type => ,
  #  :relationship => ,
#    :relative_surname => :father_last_name,
    # :witness1_forename => ,
    # :witness1_surname => ,
    # :witness2_forename => ,
    # :witness2_surname => ,
    # :line => ,
    :file_line_number => :file_line_number,
  }

  def self.translate(file, entry)
    entry_attrs = entry_attributes(entry) # straightforward remapping of csv entry fields to corresponding search record fields
    file_attrs = file_attributes(file)    # populating search record fields from file header
    file_attrs.merge!(entry_attrs)        # join the two
    names = transform_names(entry)        # populate names from csv entry based on mapping file
    file_attrs[:transcript_names] = names
    
    file_attrs
  end



  def self.entry_attributes(entry)
    new_attrs = {}
    KEY_MAP.keys.each do |key|
      new_attrs[KEY_MAP[key]] = entry[key] if entry[key] 
    end    
    
    # get the dates transformed
    new_attrs[:transcript_date] = []
    [:baptism_date, :burial_date, :marriage_date, :birth_date].each do |date_key|
      new_attrs[:transcript_date] << entry[date_key] if entry[date_key]
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

  # create transcript names from the entry and mapping configuration  
  def self.transform_names(entry)
    names = []
    role_fields_map = begin
      YAML.load(File.open("#{Rails.root}/config/csv_layout.yml"))
    rescue ArgumentError => e
      puts "Could not parse YAML: #{e.message}"
    end
    # consider duplicate field keys for different formats (see relative surnames above)
    role_fields_map.each do |role|
      role_name = role['role']
      type_name = role['type']
      fields_map = role['fields']

      first_name_keys = fields_map['first_name'].is_a?(Array) ? fields_map['first_name'] : [fields_map['first_name']]
      last_name_keys = fields_map['last_name'].is_a?(Array) ? fields_map['last_name'] : [fields_map['last_name']]
      
      first_name_key = first_name_keys.detect { |key| entry[key.to_sym] }
      last_name_key = last_name_keys.detect { |key| entry[key.to_sym] }
      if first_name_key && last_name_key # does it have both first and last names?
        extra_name = { :role => role_name, :type => type_name }
        fields_map.each_pair do |standard, original|
          if original.is_a? Array
            original.detect { |o| extra_name[standard.to_sym] = entry[o.to_sym] }
          else
            extra_name[standard.to_sym] = entry[original.to_sym]
          end
        end
        names << extra_name
      end    
    end
  
    names

  end
  
end