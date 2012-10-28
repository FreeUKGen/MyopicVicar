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
# The collection of images forming a book
class AssetCollection
  include MongoMapper::Document
  key :title, String, :required => true
  key :author, String, :required => false
  key :extern_ref, String
  
  key :has_thumbnails, Boolean, :default => false
  
  many :assets 
end
