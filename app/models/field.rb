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
# The idea of the field is that it defines the layout of the thing being transcribed at the most fine level. e.g. a text-field
class Field
  include MongoMapper::EmbeddedDocument
  
  key :name, String
  key :field_key, String
  key :kind, String # text/select
  key :initial_value, String
  
  # This options hash has the descripition of the field with options.
  key :options, Hash
  key :validations, Array
  
  # TODO - should validate within scope of entity
  # validates_uniqueness_of :field_key, :scope => 'entity_id' ?
  
  belongs_to :entity
end