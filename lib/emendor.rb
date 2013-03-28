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

  def self.emend(name_array)
    # fetch all the emendation types
    emended_names = []
    EmendationType.all.each do |emendation_type|
      target_field = emendation_type.target_field
      name_array.each do |name|
        rules = emendation_type.emendation_rules.where(:original => name[target_field]).all
        rules.each do |rule|
          emended_name = SearchName.new(name.attributes)
          emended_name[target_field] = rule.replacement
          emended_name.origin = emendation_type.name
          emended_names << emended_name
        end
      end
    end
    name_array + emended_names
  end

end