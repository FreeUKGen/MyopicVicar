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
# The image being transcribed
class Asset
  include MongoMapper::Document
  
  # What is the native size of the image
  key :height, Integer, :required => true
  key :width, Integer, :required => true
  
  # What size should the image be displayed at
  key :display_width, Integer, :required => true
  
  key :location, String, :required => true
  key :ext_ref, String
  key :order, Integer
  key :template_id, ObjectId
  
  key :done, Boolean, :default => false 
  key :classification_count, Integer , :default => 0 
  
  key :thumbnail_location, String
  key :thumbnail_width, Integer
  key :thumbnail_height, Integer
  
  scope :active, :conditions => { :done => false }
  scope :in_collection, lambda { |asset_collection| where(:asset_collection_id => asset_collection.id)}

  timestamps!
  
  belongs_to :template
  belongs_to :asset_collection
  

  # Don't want the image to be squashed
  def display_height
    (display_width.to_f / width.to_f) * height
  end
  

end
