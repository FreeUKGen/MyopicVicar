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
module Emendor

  @@emendations = nil

  def self.emend(name_array)
    load_emendations unless @@emendations

    emended_names = []
    name_array.each do |name|
      rules = @@emendations[name[:first_name]] # currently hard-wired

      if rules
        rules.each do |rule|
          if rule[:gender].present? #ignore gender-based rule unless same gender
            case 
            when (name[:gender].nil? && name[:role] == "bu")
              #p "no sex on burial"
            when (name[:gender].nil? && name[:role] == "wt")
              #p "no sex on witness"
            when (name[:gender].present? && (name[:gender].downcase != rule[:gender]))
              #p "genders do not match"
              next
            end
          end
          #p "actually applying rule #{rule.inspect}"
          emended_name = SearchName.new(name.attributes)
          emended_name[:first_name] = rule.replacement
          emended_name.origin = SearchRecord::Source::EMENDOR
          emended_names << emended_name
        end
      end
    end

    name_array = name_array + emended_names
  end

  def self.load_emendations
    @@emendations = {}

    EmendationRule.all.each do |rule|
      @@emendations[rule.original] = [] unless @@emendations[rule.original]
      @@emendations[rule.original] << rule
    end
  end


  def self.search_params(code, rule)
    params = Hash.new
    params[:chapman_code] = { '$in' => [code] }

    name_params = Hash.new
    name_params["first_name"] = rule.original

    params["search_names"] =  { "$elemMatch" => name_params}

    params
  end

  def self.matching_records(code, rule, verbose=false)
    # find the actual records
    index = "county_fn_ln_sd"
    records = SearchRecord.where(search_params(code,rule)).hint(index)

    print "\t\tFound \t#{records.count} matching records\n" if verbose

    records
  end


  def self.apply_emendation(rule, verbose, pretend)
    if verbose
      print "Applying rule emending #{rule.original} to #{rule.replacement}\n"
    end
    ChapmanCode.values.each do |code|
      print "\tApplying #{rule.original}=>#{rule.replacement} over records in #{code}\n" if verbose

      records = matching_records(code, rule, verbose)

      ids = []
      records.each { |r| ids << r.id }

      ids.each do |id|
        record = SearchRecord.find(id)
        if transformed = record.search_names.to_a.detect { |n| n.origin == SearchRecord::Source::EMENDOR }
          print "\t\tSkipping record #{transformed.first_name} #{transformed.last_name} (as already emended)\n" if verbose
        else
          print "\t\tTransforming record "+record.search_names.inject("") { |acc,n| acc << "#{n.first_name} #{n.last_name} & " }+"\n" if verbose
          record.transform
          unless pretend
            record.save!
            sleep(0.1)
          end
        end
      end
    end

  end
end
