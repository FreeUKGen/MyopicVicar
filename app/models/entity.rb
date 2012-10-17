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
#
# TODO: Move Scribe-originated models into an engine or other usefully-separated format
#
# An Entity is the 'thing' being transcribed e.g. a weather observation and is composed of many Fields
# In the UI it corresponds to a tab on the data-entry screen
class Entity
  include MongoMapper::Document
  
  # For the UI - can be used to build a tutorial
  key :name, String
  key :description, String
  key :help, String
  
  # Can this entity be resized in the UI?
  key :resizeable, Boolean, :default => false
  key :width, Integer
  key :height, Integer
  key :bounds, Array
  key :zoom, Float
    
  timestamps!
  
  belongs_to :template
  many :fields
end