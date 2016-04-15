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
  def self.transform(name_array)
#    binding.pry
    transformed_names = []
    # loop through each name
    name_array.each do |name|     
      # first, handle the names in square brackets (invalid but common)
      name.first_name.sub!(TENTATIVE_NAME_NOT_UCF,'\2')     
      # seed the expansions with the untransformed name      
      expanded_forenames = [name.first_name]
      # loop through each UCF expression
      name.first_name.scan(BRACE_REGEX).each do |(replacement, contents)|
        new_expansions = []
        unless contents =~ EDITORIAL_NOT_UCF
          # loop through each character in the UCF expression
          contents.each_char do |character|
            unless character == '_'
              # add the permutation to the expansion
              expanded_forenames.each do |forename|
                new_name = forename.sub(replacement, character)
                new_expansions << new_name
              end
            end
          end
        end
        expanded_forenames = new_expansions     
      end
      
      unless expanded_forenames == [name.first_name] # only add the transformation if we did stuff
        transformed_names = expanded_forenames.map { |forename| SearchName.new(name.attributes.merge({:first_name => forename, :origin => 'ucf'}))}    
      end

      transformed_names
    end       
    name_array + transformed_names
  end
  


end
