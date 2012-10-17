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
  include MongoMapper::Document        
  
  # filename
  key :name, String, :required => true
  key :chapman_code, String, :required => false, :in => ChapmanCode::values+[nil]
  key :start_date, String, :length=>10
  key :end_date, String, :length=>10
  key :difficulty
  key :image_file_ids, Array #, :typecast => 'ObjectId'
  many :image_files, :in => :image_file_ids
  key :template, ObjectId
  key :asset_collection, ObjectId
  
#  belongs_to :template

  validates_format_of :start_date, :end_date, 
    :with => /^(\d\d\d\d(-\d\d(-\d\d)?)?)?$/, 
    :message => "Dates must be a date of the format YYYY, YYYY-MM, or YYYY-MM-DD."
  
  timestamps!


  def publish_to_asset_collection
    ac = ScribeTranslator.image_list_to_asset_collection(self)
    self.asset_collection = ac.id
    self.save!
    ac
  end

end
