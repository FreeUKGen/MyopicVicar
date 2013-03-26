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
  include Mongoid::Document
  include Mongoid::Timestamps
  
  # For the UI - can be used to build a tutorial
  field :name, type: String
  field :description, type: String
  field :help, type: String
  
  # Can this entity be resized in the UI?
  field :resizeable, type: Boolean, :default => false
  field :width, type: Integer
  field :height, type: Integer
  field :bounds, type: Array
  field :zoom, type: Float

  field :search_record_type, type: String

    
  belongs_to :template
  has_many :fields
end
