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


  def self.setup_benchmark
    unless defined? @@tts
      @@tts = {}
      @@tts[:entry] = Benchmark.measure {}
      @@tts[:file] = Benchmark.measure {}
      @@tts[:transform] = Benchmark.measure {}
    end
  end
  def self.report_benchmark
    print "\n\nTranslator\n"
    @@tts.each_pair do |k,v|
      print "#{k}\t"
      print "#{v.format}"
    end
  end



  def self.translate(file, entry)
    entry_attrs = nil
    file_attrs = nil
    names = nil

    if defined? @@tts
      @@tts[:entry] += Benchmark.measure do
        entry_attrs = entry_attributes(entry) # straightforward remapping of csv entry fields to corresponding search record fields
      end
      @@tts[:file] += Benchmark.measure do
        file_attrs = file_attributes(file)    # populating search record fields from file header
        file_attrs.merge!(entry_attrs)        # join the two
      end
      @@tts[:transform] += Benchmark.measure do
        names = transform_names(entry)
        file_attrs[:transcript_names] = names
      end
    else
      entry_attrs = entry_attributes(entry) # straightforward remapping of csv entry fields to corresponding search record fields
      file_attrs = file_attributes(file)    # populating search record fields from file header
      file_attrs.merge!(entry_attrs)        # join the two
      names = transform_names(entry)
      file_attrs[:transcript_names] = names
    end

    file_attrs
  end



  def self.entry_attributes(entry)
    new_attrs = {}
    new_attrs[:chapman_code] = entry[:county]
    new_attrs[:line_id] = entry[:line_id]

    new_attrs[:transcript_dates] = []
    ['baptism_date', 'burial_date', 'marriage_date', 'birth_date', 'death_date', 'contract_date', 'confirmation_date','received_into_church_date'].each do |date_key|
      new_attrs[:transcript_dates] << entry[date_key] if entry[date_key]
    end
    #new_attrs[:line_id] = entry.line_id

    new_attrs
  end

  def self.file_attributes(file)
    new_attrs = {}
    # keys for finding duplicate tranascript
    new_attrs[:record_type] = file.record_type
    new_attrs[:search_record_version] = file.search_record_version
    new_attrs
  end

  # create transcript names from the entry and mapping configuration
  def self.transform_names(entry)
    case entry.record_type
    when RecordType::BURIAL
      translate_names_burial(entry)
    when RecordType::MARRIAGE
      translate_names_marriage(entry)
    when RecordType::BAPTISM
      translate_names_baptism(entry)
    end
  end


  def self.translate_names_marriage(entry)
    names = []
    # - role: b
    # type: primary
    # fields:
    # first_name: bride_forename
    # last_name:  bride_surname
    names << { :role => 'b', :type => 'primary', :first_name => entry.bride_forename, :last_name => entry.bride_surname }
    # - role: g
    # type: primary
    # fields:
    # first_name: groom_forename
    # last_name:  groom_surname
    names << { :role => 'g', :type => 'primary', :first_name => entry.groom_forename, :last_name => entry.groom_surname }
    #
    # - role: gf
    # type: other
    # fields:
    # first_name: groom_father_forename
    # last_name:  groom_father_surname
    if entry.groom_father_surname
      names << { :role => 'gf', :type => 'other', :first_name => entry.groom_father_forename, :last_name => entry.groom_father_surname }
    end
    # - role: bf
    # type: other
    # fields:
    # first_name: bride_father_forename
    # last_name:  bride_father_surname

    if entry.bride_father_surname
      names << { :role => 'bf', :type => 'other', :first_name => entry.bride_father_forename, :last_name => entry.bride_father_surname }
    end
    if entry.bride_mother_surname
      names << { :role => 'bm', :type => 'other', :first_name => entry.bride_mother_forename, :last_name => entry.bride_mother_surname }
    end
    if entry.groom_mother_surname
      names << { :role => 'gm', :type => 'other', :first_name => entry.groom_mother_forename, :last_name => entry.groom_mother_surname }
    end
    # - role: wt
    # type: witness
    # fields:
    # first_name: witness_forename
    # last_name:  witness_surname
    entry.multiple_witnesses.each do |witness|
      names << { :role => 'wt', :type => 'witness', :first_name => witness.witness_forename, :last_name => witness.witness_surname }
    end
    names
  end

  def self.translate_names_burial(entry)
    names = []

    # - role: bu
    # type: primary
    # fields:
    # first_name: burial_person_forename
    # last_name:
    # - burial_person_surname
    # - relative_surname
    alternate_surname = entry.relative_surname.present? ? entry.relative_surname : entry.female_relative_surname
   
    names << { :role => 'bu', :type => 'primary', :first_name => entry.burial_person_forename||"", :last_name => entry.burial_person_surname.present? ? entry.burial_person_surname : alternate_surname }
    # - role: fr
    # type: other
    # fields:
    
    # first_name: female_relative_forename
    # last_name: female_relative_surname
    # last_name:  relative_surname
    #
    if entry.female_relative_forename.present? || entry.male_relative_forename.present? || entry.relative_surname.present?
      if entry.female_relative_forename
        if entry.female_relative_surname.present?
          names << { :role => 'fr', :type => 'other', :first_name => entry.female_relative_forename, :last_name => entry.female_relative_surname }
        else
          if entry.relative_surname.present? 
            names << { :role => 'fr', :type => 'other', :first_name => entry.female_relative_forename, :last_name => entry.relative_surname }
          else 
            names << { :role => 'fr', :type => 'other', :first_name => entry.female_relative_forename, :last_name => entry.burial_person_surname }
          end
        end
      end
      
      # - role: mr
      # type: other
      # fields:
      # first_name: male_relative_forename
      # last_name:  relative_surname
      if entry.male_relative_forename
        names << { :role => 'mr', :type => 'other', :first_name => entry.male_relative_forename, :last_name => entry.relative_surname.present?  ? entry.relative_surname : entry.burial_person_surname }
      end
    end
    names
  end

  def self.translate_names_baptism(entry)
    names = []

    # - role: ba
    # type: primary
    # fields:
    # first_name: person_forename
    # last_name: person_surname
    # - father_surname
    # - mother_surname
    forename = entry.person_forename || ""
    entry.person_surname.present? ? surname = entry.person_surname : surname = nil
    if surname.nil?
      surname = entry.father_surname.present? ? entry.father_surname : entry.mother_surname
    end
    names << { :role => 'ba', :type => 'primary', :first_name => forename, :last_name => surname}
    # - role: f
    # type: other
    # fields:
    # first_name: father_forename
    # last_name:  father_surname
    if entry.father_forename
      names << { :role => 'f', :type => 'other', :first_name => entry.father_forename, :last_name => entry.father_surname}
    end


    # - role: m
    # type: other
    # fields:
    # first_name: mother_forename
    # last_name:
    # - mother_surname
    # - father_surname
    if entry.mother_forenamefemale_relative_forename
      names << { :role => 'm', :type => 'other', :first_name => entry.mother_forename, :last_name => entry.mother_surname.present? ? entry.mother_surname : entry.father_surname}
    end
    # - role: wt
    # type: witness
    # fields:
    # first_name: witness_forename
    # last_name:  witness_surname
    entry.multiple_witnesses.each do |witness|
      names << { :role => 'wt', :type => 'witness', :first_name => witness.witness_forename, :last_name => witness.witness_surname }
    end
    names
  end

end
