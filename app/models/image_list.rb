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
require 'chapman_code'
require 'scribe_translator'
class ImageList 
  include Mongoid::Document
  include Mongoid::Timestamps

  
  # filename
  field :name, type: String, :required => true
  field :chapman_code, type: String, :required => false, :in => ChapmanCode::values+[nil]
  field :start_date, type: String, :length=>10
  field :end_date, type: String, :length=>10
  field :difficulty
  field :image_file_ids, type: Array #, :typecast => 'ObjectId'
  has_many :image_files, :as => :image_file_ids
  field :template, type: BSON::ObjectId
  field :asset_collection, type: BSON::ObjectId
  
#  belongs_to :template

  validates_format_of :start_date, :end_date, 
    :with => /^(\d\d\d\d(-\d\d(-\d\d)?)?)?$/, 
    :message => "Dates must be a date of the format YYYY, YYYY-MM, or YYYY-MM-DD."
  


  def publish_to_asset_collection
    ac = ScribeTranslator.image_list_to_asset_collection(self)
    self.asset_collection = ac.id
    self.save!
    ac
  end

end
