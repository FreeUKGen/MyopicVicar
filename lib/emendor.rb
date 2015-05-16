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
          emended_name = SearchName.new(name.attributes)
          emended_name[:first_name] = rule.replacement
          emended_name.origin = rule.emendation_type.name
          emended_names << emended_name
        end        
      end
    end

    name_array + emended_names
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

      records.each do |record|
        unless pretend
          record.transform
          record.save! 
          binding.pry         
        end
      end
    end

  end
end