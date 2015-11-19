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
module RecordType

  BURIAL='bu'
  MARRIAGE='ma'
  BAPTISM='ba'


  def self.all_types
    if true #MyopicVicar::Application.config.template_set == MyopicVicar::TemplateSet::FREEREG
      ALL_FREEREG_TYPES
    else
      []
    end
  end
  
  def self.options
    if true #MyopicVicar::Application.config.template_set == MyopicVicar::TemplateSet::FREEREG
      FREEREG_OPTIONS
    else
      []
    end
  end
  
  def self.display_name(value)
    # binding.pry
    self.options.key(value)
  end

  ALL_FREEREG_TYPES = [BURIAL, MARRIAGE, BAPTISM]

private
  FREEREG_OPTIONS = {
    'Baptism' => BAPTISM,
    'Marriage' => MARRIAGE,
    'Burial' => BURIAL
  }    
  


end
