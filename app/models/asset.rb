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
  include Mongoid::Document
  include Mongoid::Timestamps
  
  # What is the native size of the image
  field :height, type: Integer, :required => true
  field :width, type: Integer, :required => true
  
  # What size should the image be displayed at
  field :display_width, type: Integer, :required => true
  
  field :location, type: String, :required => true
  field :ext_ref, type: String
  field :order, type: Integer
  field :template_id, type: BSON::ObjectId
  
  field :done, type: Boolean, :default => false 
  field :classification_count, type: Integer , :default => 0 
  
  field :thumbnail_location, type: String
  field :thumbnail_width, type: Integer
  field :thumbnail_height, type: Integer
  
  scope :active, :conditions => { :done => false }
  scope :in_collection, lambda { |asset_collection| where(:asset_collection_id => asset_collection.id)}

  belongs_to :template
  belongs_to :asset_collection
  

  # Don't want the image to be squashed
  def display_height
    (display_width.to_f / width.to_f) * height
  end
  

end
