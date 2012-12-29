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
class ChurchName
  include MongoMapper::Document
  after_create :populate_toponym
  
  
  key :chapman_code, String
  key :church, String
  key :parish, String
  key :resolved, Boolean
  key :entry_count, Integer
  belongs_to :toponym
  
  # these are not canonical -- just quick and dirty
  key :files, Array # filename, user hash

  def populate_toponym
    toponym_attrs = {:chapman_code => self.chapman_code, :parish => self.parish}
    self.toponym = Toponym.first(toponym_attrs) || Toponym.create!(toponym_attrs) 
  end

  
end
