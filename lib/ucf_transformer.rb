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
module UcfTransformer
  
  BRACE_REGEX = /(\[(\w*?)\])/
  EDITORIAL_NOT_UCF = /blank|sic|\?|unnamed|deceased|wife|son|daughter|widow/
  TENTATIVE_NAME_NOT_UCF = /(\[(john|william|thomas|james|mary|richard)\])/

  def self.expand_single_name(name)
    # seed the expansions with the untransformed name      
    expanded_names = [name]
    # loop through each UCF expression
    name.scan(BRACE_REGEX).each do |(replacement, contents)|
      new_expansions = []
      unless contents =~ EDITORIAL_NOT_UCF
        # loop through each character in the UCF expression
        contents.each_char do |character|
          unless character == '_'
            # add the permutation to the expansion
            expanded_names.each do |forename|
              new_name = forename.sub(replacement, character)
              new_expansions << new_name
            end
          end
        end
      end
      expanded_names = new_expansions     
    end
    
    # p name
    # p expanded_names
    if expanded_names == [name]
      nil
    else
      expanded_names
    end
  end

  def self.transform(name_array)
    transformed_names = []
    # loop through each name
    name_array.each do |name|     
      # first, handle the names in square brackets (invalid but common)
      name.first_name.sub!(TENTATIVE_NAME_NOT_UCF,'\2')     
      
      expanded_forenames = expand_single_name(name.first_name)
      if expanded_forenames # only add the transformation if we did stuff
        transformed_names = expanded_forenames.map { |forename| SearchName.new(name.attributes.merge({:first_name => forename, :origin => 'ucf'}))}    
      end

      name.last_name.sub!(TENTATIVE_NAME_NOT_UCF,'\2')           
      expanded_surnames = expand_single_name(name.last_name)
      if expanded_surnames # only add the transformation if we did stuff
        transformed_names += expanded_surnames.map { |surname| SearchName.new(name.attributes.merge({:last_name => surname, :origin => 'ucf'}))}    
      end
    end       
    name_array + transformed_names
  end
  
  def self.contains_wildcard_ucf?(name_part)
    print "\tcontains_wildcard_ucf?(#{name_part}) => #{contains_wildcard_ucf?(name_part)}\n"
    name_part.match(/[\*_]/)
  end
  
  def self.ucf_to_regex(name_part)
    Regexp.new(name_part.gsub(/\./, '\.').gsub(/_/, ".").gsub(/\*/, '\w?'))
  end
  
  def self.wildcard_ucf_to_regex(name_part)
    
  end

end
